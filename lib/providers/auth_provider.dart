import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/enums.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/supabase_auth_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Repository Provider — Supabase gerçek implementasyon
// ─────────────────────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository();
});

// ─────────────────────────────────────────────────────────────────────────────
// Auth State Notifier — OTP tabanlı şifresiz kimlik doğrulama
// ─────────────────────────────────────────────────────────────────────────────

class AuthNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    // Uygulama başlatıldığında mevcut oturumu kontrol et
    return ref.read(authRepositoryProvider).getCurrentUser();
  }

  /// OTP kodu gönderir.
  Future<void> sendOtp(String emailOrPhone) async {
    await ref.read(authRepositoryProvider).sendOtp(emailOrPhone);
  }

  /// OTP kodunu doğrular ve oturum açar.
  /// Profili olan kullanıcı → UserModel döner (state güncellenir).
  /// Yeni kullanıcı → null döner (kayıt ekranına yönlendirilir).
  /// Doğrulama başarısız olursa hata fırlatır — çağıran yakalamalı.
  ///
  /// NOT: Burada [AsyncValue.guard] KULLANILMAZ; çünkü guard hatayı yutup
  /// state'i AsyncError yapıyor ama fırlatmıyordu. Bu durumda login ekranı
  /// hatayı fark edemeyip kullanıcıyı oturum açılmadan kayıt ekranına
  /// yönlendiriyor, ardından "Oturum bulunamadı" hatası çıkıyordu.
  Future<UserModel?> verifyOtp(String emailOrPhone, String otpCode) async {
    state = const AsyncLoading();
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .verifyOtp(emailOrPhone, otpCode);
      state = AsyncData(user);
      return user;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Kayıt tamamlandığında profil bilgilerini Supabase'e yazar.
  /// [avatarFile] seçildiyse Storage'a yüklenir.
  Future<void> completeRegistration({
    required String fullName,
    required UserTitle title,
    String? bio,
    String? university,
    String? city,
    String? workplace,
    int? experienceYears,
    File? avatarFile,
  }) async {
    state = const AsyncLoading();

    try {
      final client = Supabase.instance.client;
      final authUser = client.auth.currentUser;

      if (authUser == null) {
        throw Exception('Oturum bulunamadı. Lütfen tekrar giriş yapın.');
      }

      String? avatarUrl;

      // Avatar dosyası varsa Storage'a yükle
      if (avatarFile != null) {
        avatarUrl = await _uploadAvatar(authUser.id, avatarFile);
      }

      // Kullanıcı adı oluştur (ad soyaddan)
      final username = _generateUsername(fullName);

      // UserTitle → veritabanı değeri
      final titleDbValue = _titleToDbValue(title);

      // public.users tablosuna profil ekle
      final now = DateTime.now().toIso8601String();
      final profileData = {
        'id': authUser.id,
        'email': authUser.email,
        'phone': authUser.phone,
        'full_name': fullName,
        'username': username,
        'avatar_url': avatarUrl,
        'title': titleDbValue,
        'bio': bio,
        'university': university,
        'city': city,
        'experience_years': experienceYears,
        'workplace': workplace,
        'onboarding_completed': true,
        'created_at': now,
        'updated_at': now,
      };

      // null değerleri kaldır (Supabase'de default kullanılsın)
      profileData.removeWhere((key, value) => value == null);

      await client.from('users').upsert(profileData);

      // State'i güncelle
      state = AsyncData(
        UserModel(
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
        ),
      );
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncData(null);
  }

  // ── Yardımcı Metodlar ─────────────────────────────────────────────────

  /// Avatar dosyasını Supabase Storage'a yükler, public URL döner.
  Future<String> _uploadAvatar(String userId, File file) async {
    final client = Supabase.instance.client;
    final fileExt = file.path.split('.').last.toLowerCase();
    final fileName =
        '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

    await client.storage
        .from('avatars')
        .upload(
          fileName,
          file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );

    return client.storage.from('avatars').getPublicUrl(fileName);
  }

  /// Ad soyaddan kullanıcı adı üretir: "Ahmet Yılmaz" → "ahmet_yilmaz"
  String _generateUsername(String fullName) {
    final base = fullName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), '_');

    // Türkçe karakterleri normalize et
    final turkishMap = {
      'ç': 'c',
      'ğ': 'g',
      'ı': 'i',
      'ö': 'o',
      'ş': 's',
      'ü': 'u',
    };
    var normalized = base;
    turkishMap.forEach((tr, en) {
      normalized = normalized.replaceAll(tr, en);
    });

    // Boşsa fallback
    if (normalized.isEmpty) normalized = 'user';

    // Benzersizlik için timestamp ekle
    final suffix = DateTime.now().millisecondsSinceEpoch % 10000;
    return '${normalized}_$suffix';
  }

  /// UserTitle enum → veritabanı string değeri
  String _titleToDbValue(UserTitle title) {
    const map = {
      UserTitle.ogrenci: 'ogrenci',
      UserTitle.disHekimi: 'dis_hekimi',
      UserTitle.endodontist: 'endodontist',
      UserTitle.ortodontist: 'ortodontist',
      UserTitle.periodontolog: 'periodontolog',
      UserTitle.protezUzmani: 'protez_uzmani',
      UserTitle.pedodontist: 'pedodontist',
      UserTitle.agizDisCeneCerrahisi: 'agiz_dis_cene_cerrahisi',
      UserTitle.agizDisCeneRadyoloji: 'agiz_dis_cene_radyoloji',
      UserTitle.restoratifDisTedavisi: 'restoratif_dis_tedavisi',
    };
    return map[title] ?? 'dis_hekimi_genel_pratisyen';
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(() {
  return AuthNotifier();
});

/// Mevcut kullanıcıyı senkron olarak okumak için kısayol.
/// Null dönebilir — widget katmanında null kontrolü yapılmalı.
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).valueOrNull;
});
