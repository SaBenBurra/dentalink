import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/enums.dart';
import '../models/user_model.dart';
import 'auth_repository.dart';
import 'otp_cooldown_exception.dart';
import 'otp_send_limiter.dart';

/// Supabase Auth ile gerçek OTP kimlik doğrulama.
///
/// Akış:
///   1. sendOtp → Supabase signInWithOtp (SMS/E-posta)
///   2. verifyOtp → Supabase verifyOTP + public.users profil kontrolü
///   3. getCurrentUser → Session + public.users profil
///
/// İstemci tarafı cooldown ([OtpSendLimiter]):
///   - Aynı hedefe 60 sn içinde tekrar SMS atılmaz.
///   - 60 sn içinde en fazla 2 farklı hedefe gönderim yapılabilir.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({
    SupabaseClient? client,
    Duration otpCooldown = const Duration(seconds: 60),
    int maxDistinctDestinations = 2,
  })  : _client = client ?? Supabase.instance.client,
        _limiter = OtpSendLimiter(
          cooldown: otpCooldown,
          maxDistinctDestinations: maxDistinctDestinations,
        );

  final SupabaseClient _client;
  final OtpSendLimiter _limiter;

  // ── Telefon numarası normalleştirme ────────────────────────────────────
  /// Türkiye telefon numarası formatı: +90XXXXXXXXXX
  /// Kullanıcı "5551234567" girerse → "+905551234567" olur.
  static final _phoneRegex = RegExp(r'^\+?[0-9]{8,15}$');
  static final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  bool _isPhone(String input) => _phoneRegex.hasMatch(input);
  bool _isEmail(String input) => _emailRegex.hasMatch(input);

  String _normalizePhone(String phone) {
    phone = phone.replaceAll(RegExp(r'\s+'), '');
    if (phone.startsWith('+')) return phone;
    if (phone.startsWith('0')) phone = phone.substring(1);
    return '+90$phone';
  }

  String _normalizeDestination(String input) {
    final trimmed = input.trim();
    if (_isEmail(trimmed)) return trimmed.toLowerCase();
    if (_isPhone(trimmed)) return _normalizePhone(trimmed);
    throw Exception('Geçersiz e-posta veya telefon numarası');
  }

  // ── sendOtp ────────────────────────────────────────────────────────────

  @override
  Future<void> sendOtp(String emailOrPhone) async {
    final destination = _normalizeDestination(emailOrPhone);

    await _limiter.ensureLoaded();
    final blocked = _limiter.check(destination);
    if (blocked != null) throw blocked;

    try {
      if (_isEmail(destination)) {
        await _client.auth.signInWithOtp(email: destination);
      } else {
        await _client.auth.signInWithOtp(phone: destination);
      }
    } on AuthException catch (e) {
      // Sunucu tarafı rate-limit: istemci cooldown'u senkronize et.
      // SMS gerçekten gönderilmediyse sameDestination yalnızca daha önce
      // başarıyla gönderilmiş aynı hedef için true olmalı.
      if (_isAuthRateLimit(e)) {
        final sameDestination = _limiter.hasSentTo(destination);
        if (sameDestination) {
          await _limiter.touchRateLimit(destination);
        }
        throw OtpCooldownException(
          remainingSeconds: _limiter.cooldown.inSeconds,
          sameDestination: sameDestination,
        );
      }
      rethrow;
    }

    await _limiter.recordSuccess(destination);
  }

  bool _isAuthRateLimit(AuthException e) {
    const rateLimitCodes = {
      'over_sms_send_rate_limit',
      'over_email_send_rate_limit',
      'over_request_rate_limit',
    };
    return rateLimitCodes.contains(e.code) || e.statusCode == '429';
  }

  // ── verifyOtp ──────────────────────────────────────────────────────────

  @override
  Future<UserModel?> verifyOtp(String emailOrPhone, String otpCode) async {
    final input = emailOrPhone.trim();

    AuthResponse response;

    if (_isEmail(input)) {
      response = await _client.auth.verifyOTP(
        type: OtpType.email,
        token: otpCode,
        email: input,
      );
    } else {
      final normalizedPhone = _normalizePhone(input);
      response = await _client.auth.verifyOTP(
        type: OtpType.sms,
        token: otpCode,
        phone: normalizedPhone,
      );
    }

    if (response.user == null) {
      throw Exception('Doğrulama başarısız');
    }

    // public.users tablosunda profil var mı kontrol et
    return _fetchUserProfile(response.user!.id);
  }

  // ── getCurrentUser ─────────────────────────────────────────────────────

  @override
  Future<UserModel?> getCurrentUser() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) return null;

    return _fetchUserProfile(authUser.id);
  }

  // ── signOut ────────────────────────────────────────────────────────────

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  bool get hasSession => _client.auth.currentSession != null;

  // ── Yardımcı: public.users'tan profil çek ─────────────────────────────

  /// Auth user ID ile public.users tablosundan profil çeker.
  /// Profil yoksa null döner (yeni kullanıcı → kayıt ekranına yönlendirilir).
  Future<UserModel?> _fetchUserProfile(String userId) async {
    try {
      final data = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return null;

      return UserModel(
        id: data['id'] as String,
        email: data['email'] as String?,
        phone: data['phone'] as String?,
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
    } catch (_) {
      return null;
    }
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
  }) async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) {
      throw Exception('Oturum bulunamadı. Lütfen tekrar giriş yapın.');
    }

    String? avatarUrl;
    if (avatarFile != null) {
      avatarUrl = await _uploadAvatar(authUser.id, avatarFile);
    }

    final now = DateTime.now().toIso8601String();
    final profileData = {
      'id': authUser.id,
      'email': authUser.email,
      'phone': authUser.phone,
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
      'created_at': now,
      'updated_at': now,
    };
    profileData.removeWhere((key, value) => value == null);
    await _client.from('users').upsert(profileData);

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
  }

  Future<String> _uploadAvatar(String userId, File file) async {
    final fileExt = file.path.split('.').last.toLowerCase();
    final fileName = '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    await _client.storage.from('avatars').upload(
      fileName, file,
      fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
    );
    return _client.storage.from('avatars').getPublicUrl(fileName);
  }}
