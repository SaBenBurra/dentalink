import 'package:equatable/equatable.dart';
import '../enums/enums.dart';

class UserEntity extends Equatable {
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

  const UserEntity({
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
