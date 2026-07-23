import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/enums.dart';
import '../models/user_model.dart';
import 'auth_repository.dart';

/// Supabase Auth ile gerçek OTP kimlik doğrulama.
///
/// Akış:
///   1. sendOtp → Supabase signInWithOtp (SMS/E-posta)
///   2. verifyOtp → Supabase verifyOTP + public.users profil kontrolü
///   3. getCurrentUser → Session + public.users profil
class SupabaseAuthRepository implements AuthRepository {
  final _client = Supabase.instance.client;

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

  // ── sendOtp ────────────────────────────────────────────────────────────

  @override
  Future<void> sendOtp(String emailOrPhone) async {
    final input = emailOrPhone.trim();

    if (_isEmail(input)) {
      await _client.auth.signInWithOtp(email: input);
    } else if (_isPhone(input)) {
      final normalizedPhone = _normalizePhone(input);
      await _client.auth.signInWithOtp(phone: normalizedPhone);
    } else {
      throw Exception('Geçersiz e-posta veya telefon numarası');
    }
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
        title: _parseTitleFromDb(data['title'] as String?),
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

  /// Veritabanındaki title string'ini UserTitle enum'una dönüştürür.
  UserTitle _parseTitleFromDb(String? titleStr) {
    if (titleStr == null) return UserTitle.disHekimi;
    final map = {
      'ogrenci': UserTitle.ogrenci,
      'dis_hekimi_genel_pratisyen': UserTitle.disHekimi,
      'endodontist': UserTitle.endodontist,
      'ortodontist': UserTitle.ortodontist,
      'periodontolog': UserTitle.periodontolog,
      'protez_uzmani': UserTitle.protezUzmani,
      'pedodontist': UserTitle.pedodontist,
      'agiz_dis_cene_cerrahisi': UserTitle.agizDisCeneCerrahisi,
      'agiz_dis_cene_radyoloji': UserTitle.agizDisCeneRadyoloji,
      'restoratif_dis_tedavisi': UserTitle.restoratifDisTedavisi,
    };
    return map[titleStr] ?? UserTitle.disHekimi;
  }
}
