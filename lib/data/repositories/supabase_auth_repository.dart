import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/error/app_failures.dart';
import '../../core/utils/contact_utils.dart';
import '../../core/utils/supabase_error_mapper.dart';
import '../models/enums.dart';
import '../models/user_model.dart';
import 'auth_repository.dart';
import 'otp_cooldown_exception.dart';
import 'otp_send_limiter.dart';

/// Supabase Auth ile gerçek OTP kimlik doğrulama.
///
/// Akış:
///   1. sendOtp → Supabase signInWithOtp (WhatsApp/E-posta)
///   2. verifyOtp → Supabase verifyOTP + public.users profil kontrolü
///   3. getCurrentUser → Session + public.users profil
///
/// İstemci tarafı cooldown ([OtpSendLimiter]):
///   - Aynı hedefe 60 sn içinde tekrar kod atılmaz.
///   - 60 sn içinde en fazla 2 farklı hedefe gönderim yapılabilir.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({
    SupabaseClient? client,
    Duration otpCooldown = const Duration(seconds: 60),
    int maxDistinctDestinations = 2,
  }) : _client = client ?? Supabase.instance.client,
       _limiter = OtpSendLimiter(
         cooldown: otpCooldown,
         maxDistinctDestinations: maxDistinctDestinations,
       );

  final SupabaseClient _client;
  final OtpSendLimiter _limiter;

  String _normalizeDestination(String input) =>
      normalizeContact(input) ??
      (throw const ValidationFailure('invalid email or phone'));

  // ── sendOtp ────────────────────────────────────────────────────────────

  @override
  Future<void> sendOtp(String emailOrPhone) async {
    final destination = _normalizeDestination(emailOrPhone);
    await _limitedSend(destination, () async {
      if (isEmailContact(destination)) {
        await _client.auth.signInWithOtp(email: destination);
      } else {
        await _client.auth.signInWithOtp(
          phone: destination,
          channel: OtpChannel.whatsapp,
        );
      }
    });
  }

  /// Gönderimi istemci cooldown'u ve sunucu rate-limit'iyle sarar.
  Future<void> _limitedSend(
    String destination,
    Future<void> Function() send,
  ) async {
    await _limiter.ensureLoaded();
    final blocked = _limiter.check(destination);
    if (blocked != null) throw blocked;

    try {
      await send();
    } on AuthException catch (e) {
      // Adres sıklık sınırı: sunucu kalan süreyi yazar, kod yakın zamanda
      // gitmiştir. Genel limitte süre yoktur, kod gitmemiştir; hata aynen çıkar.
      final remaining = _frequencyLimitSeconds(e);
      if (remaining == null) rethrow;
      final sameDestination = _limiter.hasSentTo(destination);
      if (sameDestination) {
        await _limiter.touchRateLimit(destination);
      }
      throw OtpCooldownException(
        remainingSeconds: remaining,
        sameDestination: sameDestination,
      );
    }

    await _limiter.recordSuccess(destination);
  }

  static final _frequencyLimitRegex = RegExp(r'after (\d+) seconds?');

  int? _frequencyLimitSeconds(AuthException e) {
    final match = _frequencyLimitRegex.firstMatch(e.message);
    return match == null ? null : int.parse(match[1]!);
  }

  // ── verifyOtp ──────────────────────────────────────────────────────────

  @override
  Future<UserModel?> verifyOtp(String emailOrPhone, String otpCode) async {
    final destination = _normalizeDestination(emailOrPhone);

    final AuthResponse response;

    if (isEmailContact(destination)) {
      response = await _client.auth.verifyOTP(
        type: OtpType.email,
        token: otpCode,
        email: destination,
      );
    } else {
      response = await _client.auth.verifyOTP(
        type: OtpType.sms,
        token: otpCode,
        phone: destination,
      );
    }

    if (response.user == null) {
      throw Exception('Doğrulama başarısız');
    }

    // public.users tablosunda profil var mı kontrol et
    return _fetchUserProfile(response.user!.id);
  }

  // ── E-posta/telefon ekleme ve değiştirme ───────────────────────────────

  @override
  Future<void> requestContactChange(String emailOrPhone) async {
    final destination = _normalizeDestination(emailOrPhone);
    await _limitedSend(destination, () async {
      await _client.auth.updateUser(
        isEmailContact(destination)
            ? UserAttributes(email: destination)
            : _WhatsAppPhoneAttributes(destination),
      );
    });
  }

  @override
  Future<UserModel?> confirmContactChange(
    String emailOrPhone,
    String otpCode,
  ) async {
    final destination = _normalizeDestination(emailOrPhone);
    final isEmail = isEmailContact(destination);
    final response = await _client.auth.verifyOTP(
      type: isEmail ? OtpType.emailChange : OtpType.phoneChange,
      token: otpCode,
      email: isEmail ? destination : null,
      phone: isEmail ? null : destination,
    );
    if (response.user == null) {
      throw Exception('Doğrulama başarısız');
    }
    return _fetchUserProfile(response.user!.id);
  }

  // ── getCurrentUser ─────────────────────────────────────────────────────

  @override
  Future<UserModel?> getCurrentUser() => guardSupabase(() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) return null;

    return _fetchUserProfile(authUser.id);
  });

  // ── signOut ────────────────────────────────────────────────────────────

  @override
  Future<void> signOut() => guardSupabase(() => _client.auth.signOut());

  @override
  bool get hasSession => _client.auth.currentSession != null;

  @override
  Stream<void> get signedOut => _client.auth.onAuthStateChange
      .where((s) => s.event == AuthChangeEvent.signedOut)
      .map((_) {});

  // ── Yardımcı: public.users'tan profil çek ─────────────────────────────

  /// Auth user ID ile public.users tablosundan profil çeker.
  /// Profil yoksa null döner (yeni kullanıcı → kayıt ekranına yönlendirilir).
  /// Ağ/sunucu hatası null DEĞİLDİR, fırlatılır; aksi halde mevcut kullanıcı
  /// kayıt ekranına atılıp profili ezilebilir (AUDIT AUTH-1).
  Future<UserModel?> _fetchUserProfile(String userId) async {
    final data = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return null;

    // email/phone public.users'ta tutulmaz (KVKK); oturumdaki auth kullanıcısından gelir.
    final authUser = _client.auth.currentUser;
    return UserModel(
      id: data['id'] as String,
      email: authUser?.email,
      phone: authUser?.phone,
      fullName: data['full_name'] as String,
      username: data['username'] as String,
      avatarUrl: data['avatar_url'] as String?,
      title: UserTitle.fromDbValue(data['title'] as String?),
      bio: data['bio'] as String?,
      university: data['university'] as String?,
      city: data['city'] as String?,
      experienceYears: data['experience_years'] as int?,
      workplace: data['workplace'] as String?,
      followersCount: (data['followers_count'] as int?) ?? 0,
      followingCount: (data['following_count'] as int?) ?? 0,
      postsCount: (data['posts_count'] as int?) ?? 0,
      onboardingCompleted: (data['onboarding_completed'] as bool?) ?? false,
      isVerified: (data['is_verified'] as bool?) ?? false,
      lastSeenAt: data['last_seen_at'] != null
          ? DateTime.parse(data['last_seen_at'] as String)
          : null,
      createdAt: DateTime.parse(data['created_at'] as String),
    );
  }

  @override
  Future<UserModel> completeRegistration({
    required String fullName,
    required String username,
    required UserTitle title,
    String? bio,
    String? university,
    String? city,
    String? workplace,
    int? experienceYears,
    File? avatarFile,
  }) => guardSupabase(() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) {
      throw const AuthRequiredFailure();
    }

    String? avatarUrl;
    if (avatarFile != null) {
      avatarUrl = await _uploadAvatar(authUser.id, avatarFile);
    }

    // insert (upsert değil): mevcut bir profil asla ezilmez; çakışma 23505 olarak
    // fırlar. created_at/updated_at DB varsayılanlarından gelir.
    final profileData = {
      'id': authUser.id,
      'full_name': fullName,
      'username': username,
      'avatar_url': avatarUrl,
      'title': title.dbValue,
      'bio': bio,
      'university': university,
      'city': city,
      'experience_years': experienceYears,
      'workplace': workplace,
      'onboarding_completed': true,
    };
    profileData.removeWhere((key, value) => value == null);
    await _client.from('users').insert(profileData);

    return UserModel(
      id: authUser.id,
      email: authUser.email,
      phone: authUser.phone,
      fullName: fullName,
      username: username,
      avatarUrl: avatarUrl,
      title: title,
      bio: bio,
      university: university,
      city: city,
      experienceYears: experienceYears,
      workplace: workplace,
      onboardingCompleted: true,
      createdAt: DateTime.now(),
    );
  });

  Future<String> _uploadAvatar(String userId, File file) async {
    final fileExt = file.path.split('.').last.toLowerCase();
    final fileName =
        '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    await _client.storage
        .from('avatars')
        .upload(
          fileName,
          file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );
    return _client.storage.from('avatars').getPublicUrl(fileName);
  }
}

/// gotrue `UserAttributes` kanal alanı taşımıyor; sunucu `PUT /user` için
/// `channel` kabul ediyor. Verilmezse kod SMS ile gider.
class _WhatsAppPhoneAttributes extends UserAttributes {
  _WhatsAppPhoneAttributes(String phone) : super(phone: phone);

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'channel': OtpChannel.whatsapp.name,
  };
}
