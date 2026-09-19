import '../../domain/entities/user_entity.dart';
import '../../domain/entities/user_summary.dart';
import '../../domain/enums/enums.dart';

class UserMapper {
  /// Supabase tablosundan gelen satırı (JSON) UserEntity'e dönüştürür.
  static UserEntity fromRow(Map<String, dynamic> row) {
    return UserEntity(
      id: row['id'] as String,
      email: row['email'] as String?,
      phone: row['phone'] as String?,
      fullName: row['full_name'] as String,
      username: row['username'] as String,
      avatarUrl: row['avatar_url'] as String?,
      title: UserTitle.tryFromDbValue(row['title'] as String?) ?? UserTitle.unknown,
      bio: row['bio'] as String?,
      university: row['university'] as String?,
      city: row['city'] as String?,
      experienceYears: row['experience_years'] as int?,
      workplace: row['workplace'] as String?,
      followersCount: row['followers_count'] as int? ?? 0,
      followingCount: row['following_count'] as int? ?? 0,
      postsCount: row['posts_count'] as int? ?? 0,
      onboardingCompleted: row['onboarding_completed'] as bool? ?? false,
      isVerified: row['is_verified'] as bool? ?? false,
      lastSeenAt: row['last_seen_at'] != null
          ? DateTime.tryParse(row['last_seen_at'].toString())
          : null,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  /// Supabase tablosundan gelen yazar verisini UserSummary'e dönüştürür.
  static UserSummary toSummary(Map<String, dynamic> row) {
    return UserSummary(
      id: row['id'] as String,
      fullName: row['full_name'] as String,
      username: row['username'] as String,
      avatarUrl: row['avatar_url'] as String?,
      title: UserTitle.tryFromDbValue(row['title'] as String?) ?? UserTitle.unknown,
      isVerified: row['is_verified'] as bool? ?? false,
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
    );
  }

  /// UserEntity'yi Supabase'e gönderilebilir bir map'e dönüştürür.
  /// Sadece kullanıcının güncelleyebileceği alanları içerir. (3d düzeltmesi)
  static Map<String, dynamic> toRow(UserEntity entity) {
    return {
      'full_name': entity.fullName,
      'avatar_url': entity.avatarUrl,
      'title': entity.title.dbValue,
      'bio': entity.bio,
      'university': entity.university,
      'city': entity.city,
      'experience_years': entity.experienceYears,
      'workplace': entity.workplace,
    };
  }
}
