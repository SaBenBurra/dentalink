import 'package:equatable/equatable.dart';
import '../../domain/enums/enums.dart';

/// Kullanıcı modeli — Supabase `users` tablosuyla eşleşir.
///
/// Bu sınıf yalnızca kalıcı (persisted) kullanıcı verisini temsil eder.
/// Bağlama bağlı geçici UI state'leri (ör. takip durumu) bu modelde
/// yer almaz; bunlar ayrı provider'larda yönetilir.
class UserModel extends Equatable {
  final String id;
  final String? email;
  final String? phone;
  final String fullName;
  final String username;
  final String? avatarUrl;
  final UserTitle title;
  final String? bio;
  final String? university;
  final String? city;
  final int? experienceYears;
  final String? workplace;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final bool onboardingCompleted;
  final bool isVerified;
  final DateTime? lastSeenAt;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    this.email,
    this.phone,
    required this.fullName,
    required this.username,
    this.avatarUrl,
    required this.title,
    this.bio,
    this.university,
    this.city,
    this.experienceYears,
    this.workplace,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.onboardingCompleted = true,
    this.isVerified = false,
    this.lastSeenAt,
    required this.createdAt,
  });

  /// JSON'dan model oluşturur.
  ///
  /// Parsing stratejisi:
  /// - **Zorunlu alanlar** (`id`, `fullName`, `username`, `createdAt`):
  ///   Hard cast / `DateTime.parse` kullanılır. Eksik veya hatalı veri
  ///   gelirse exception fırlatılır (fail-fast). Bu alanlar backend'de
  ///   `NOT NULL` olarak tanımlıdır ve yokluğu bir veri bütünlüğü
  ///   sorununa işaret eder.
  /// - **Opsiyonel alanlar** (`email`, `bio`, `city`, vb.):
  ///   Nullable cast (`as String?`) kullanılır, `null` kabul edilir.
  /// - **Enum alanları** (`title`): `tryFromDbValue` ile güvenli parse
  ///   yapılır ve tanınmayan değerde varsayılana düşer. Enum uyuşmazlığı
  ///   (ör. backend'e yeni değer eklenip client güncellenmemesi) olası
  ///   bir senaryodur.
  /// - **Sayaç alanları** (`followersCount`, vb.): `null` ise `0`'a düşer.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      fullName: json['full_name'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
      title: UserTitle.tryFromDbValue(json['title'] as String?) ?? UserTitle.disHekimi,
      bio: json['bio'] as String?,
      university: json['university'] as String?,
      city: json['city'] as String?,
      experienceYears: json['experience_years'] as int?,
      workplace: json['workplace'] as String?,
      followersCount: json['followers_count'] as int? ?? 0,
      followingCount: json['following_count'] as int? ?? 0,
      postsCount: json['posts_count'] as int? ?? 0,
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? false,
      // Supabase bazen DateTime nesnesi, bazen ISO 8601 String döner;
      // .toString() her iki durumda da güvenli bir String temsili sağlar.
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.tryParse(json['last_seen_at'].toString())
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'full_name': fullName,
      'username': username,
      'avatar_url': avatarUrl,
      'title': title.dbValue,
      'bio': bio,
      'university': university,
      'city': city,
      'experience_years': experienceYears,
      'workplace': workplace,
      'followers_count': followersCount,
      'following_count': followingCount,
      'posts_count': postsCount,
      'onboarding_completed': onboardingCompleted,
      'is_verified': isVerified,
      'last_seen_at': lastSeenAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  // TODO(refactor): Nullable alanları (avatarUrl, bio, city, vb.) açıkça
  // null'a sıfırlamak bu pattern ile mümkün değildir. `freezed` paketine
  // geçildiğinde bu kısıtlama otomatik olarak çözülecektir.
  UserModel copyWith({
    String? id,
    String? email,
    String? phone,
    String? fullName,
    String? username,
    String? avatarUrl,
    UserTitle? title,
    String? bio,
    String? university,
    String? city,
    int? experienceYears,
    String? workplace,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    bool? onboardingCompleted,
    bool? isVerified,
    DateTime? lastSeenAt,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      title: title ?? this.title,
      bio: bio ?? this.bio,
      university: university ?? this.university,
      city: city ?? this.city,
      experienceYears: experienceYears ?? this.experienceYears,
      workplace: workplace ?? this.workplace,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      isVerified: isVerified ?? this.isVerified,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        phone,
        fullName,
        username,
        avatarUrl,
        title,
        bio,
        university,
        city,
        experienceYears,
        workplace,
        followersCount,
        followingCount,
        postsCount,
        onboardingCompleted,
        isVerified,
        lastSeenAt,
        createdAt,
      ];
}
