import 'enums.dart';

/// Kullanıcı modeli — Supabase `users` tablosuyla eşleşir.
class UserModel {
  final String id;
  final String email;
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

  // UI state — Faz 3'te API'den gelir, şimdilik mock provider'dan set edilir
  final bool isFollowing;

  const UserModel({
    required this.id,
    required this.email,
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
    this.isFollowing = false,
  });

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
    bool? isFollowing,
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
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is UserModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
