import 'package:flutter_test/flutter_test.dart';
import 'package:dentlink/data/models/user_model.dart';
import 'package:dentlink/data/models/enums.dart';

void main() {
  group('UserModel', () {
    const fixedCreatedAtString = '2026-09-18T10:00:00.000Z';
    const fixedLastSeenAtString = '2026-09-18T12:30:00.000Z';
    final fixedCreatedAt = DateTime.parse(fixedCreatedAtString);
    final fixedLastSeenAt = DateTime.parse(fixedLastSeenAtString);

    group('fromJson', () {
      test('fromJson with full valid JSON creates correct UserModel', () {
        // Arrange
        final json = {
          'id': 'user-123',
          'email': 'doctor@example.com',
          'phone': '+905551234567',
          'full_name': 'Dr. Ayşe Yılmaz',
          'username': 'drayse',
          'avatar_url': 'https://example.com/avatar.png',
          'title': 'ortodontist',
          'bio': 'Ortodontist ve araştırmacı.',
          'university': 'Hacettepe Üniversitesi',
          'city': 'Ankara',
          'experience_years': 8,
          'workplace': 'Özel Klinik',
          'followers_count': 150,
          'following_count': 80,
          'posts_count': 25,
          'onboarding_completed': true,
          'is_verified': true,
          'last_seen_at': fixedLastSeenAtString,
          'created_at': fixedCreatedAtString,
        };

        // Act
        final user = UserModel.fromJson(json);

        // Assert
        expect(user.id, equals('user-123'));
        expect(user.email, equals('doctor@example.com'));
        expect(user.phone, equals('+905551234567'));
        expect(user.fullName, equals('Dr. Ayşe Yılmaz'));
        expect(user.username, equals('drayse'));
        expect(user.avatarUrl, equals('https://example.com/avatar.png'));
        expect(user.title, equals(UserTitle.ortodontist));
        expect(user.bio, equals('Ortodontist ve araştırmacı.'));
        expect(user.university, equals('Hacettepe Üniversitesi'));
        expect(user.city, equals('Ankara'));
        expect(user.experienceYears, equals(8));
        expect(user.workplace, equals('Özel Klinik'));
        expect(user.followersCount, equals(150));
        expect(user.followingCount, equals(80));
        expect(user.postsCount, equals(25));
        expect(user.onboardingCompleted, isTrue);
        expect(user.isVerified, isTrue);
        expect(user.lastSeenAt, equals(fixedLastSeenAt));
        expect(user.createdAt, equals(fixedCreatedAt));
      });

      test(
        'fromJson with minimal required fields (id, full_name, username, created_at) plus defaults',
        () {
          // Arrange
          final json = {
            'id': 'user-min',
            'full_name': 'Ali Veli',
            'username': 'aliveli',
            'created_at': fixedCreatedAtString,
          };

          // Act
          final user = UserModel.fromJson(json);

          // Assert
          expect(user.id, equals('user-min'));
          expect(user.fullName, equals('Ali Veli'));
          expect(user.username, equals('aliveli'));
          expect(user.createdAt, equals(fixedCreatedAt));
          expect(user.title, equals(UserTitle.disHekimi));
          expect(user.followersCount, equals(0));
          expect(user.followingCount, equals(0));
          expect(user.postsCount, equals(0));
          expect(user.onboardingCompleted, isFalse);
          expect(user.isVerified, isFalse);
          expect(user.email, isNull);
          expect(user.phone, isNull);
          expect(user.avatarUrl, isNull);
          expect(user.bio, isNull);
          expect(user.university, isNull);
          expect(user.city, isNull);
          expect(user.experienceYears, isNull);
          expect(user.workplace, isNull);
          expect(user.lastSeenAt, isNull);
        },
      );

      test(
        'fromJson with null optional fields (bio, university, city, etc.) handles gracefully',
        () {
          // Arrange
          final json = {
            'id': 'user-null-fields',
            'email': null,
            'phone': null,
            'full_name': 'Zeynep Kaya',
            'username': 'zkaya',
            'avatar_url': null,
            'title': null,
            'bio': null,
            'university': null,
            'city': null,
            'experience_years': null,
            'workplace': null,
            'followers_count': null,
            'following_count': null,
            'posts_count': null,
            'onboarding_completed': null,
            'is_verified': null,
            'last_seen_at': null,
            'created_at': fixedCreatedAtString,
          };

          // Act
          final user = UserModel.fromJson(json);

          // Assert
          expect(user.id, equals('user-null-fields'));
          expect(user.email, isNull);
          expect(user.phone, isNull);
          expect(user.fullName, equals('Zeynep Kaya'));
          expect(user.username, equals('zkaya'));
          expect(user.avatarUrl, isNull);
          expect(user.title, equals(UserTitle.disHekimi));
          expect(user.bio, isNull);
          expect(user.university, isNull);
          expect(user.city, isNull);
          expect(user.experienceYears, isNull);
          expect(user.workplace, isNull);
          expect(user.followersCount, equals(0));
          expect(user.followingCount, equals(0));
          expect(user.postsCount, equals(0));
          expect(user.onboardingCompleted, isFalse);
          expect(user.isVerified, isFalse);
          expect(user.lastSeenAt, isNull);
          expect(user.createdAt, equals(fixedCreatedAt));
        },
      );

      test('fromJson with unknown title string defaults to disHekimi', () {
        // Arrange
        final json = {
          'id': 'user-unknown-title',
          'full_name': 'Unknown Title User',
          'username': 'unknowntitle',
          'title': 'unknown_or_future_title',
          'created_at': fixedCreatedAtString,
        };

        // Act
        final user = UserModel.fromJson(json);

        // Assert
        expect(user.title, equals(UserTitle.disHekimi));
      });

      test('fromJson counter fields null -> default to 0', () {
        // Arrange
        final json = {
          'id': 'user-null-counters',
          'full_name': 'Counter User',
          'username': 'counteruser',
          'followers_count': null,
          'following_count': null,
          'posts_count': null,
          'created_at': fixedCreatedAtString,
        };

        // Act
        final user = UserModel.fromJson(json);

        // Assert
        expect(user.followersCount, equals(0));
        expect(user.followingCount, equals(0));
        expect(user.postsCount, equals(0));
      });

      test('fromJson onboarding_completed null -> defaults to false', () {
        // Arrange
        final json = {
          'id': 'user-null-onboarding',
          'full_name': 'Onboarding User',
          'username': 'onboardinguser',
          'onboarding_completed': null,
          'created_at': fixedCreatedAtString,
        };

        // Act
        final user = UserModel.fromJson(json);

        // Assert
        expect(user.onboardingCompleted, isFalse);
      });

      test('fromJson last_seen_at as ISO 8601 string parses correctly', () {
        // Arrange
        final json = {
          'id': 'user-last-seen',
          'full_name': 'Last Seen User',
          'username': 'lastseenuser',
          'last_seen_at': fixedLastSeenAtString,
          'created_at': fixedCreatedAtString,
        };

        // Act
        final user = UserModel.fromJson(json);

        // Assert
        expect(user.lastSeenAt, equals(fixedLastSeenAt));
      });

      test('fromJson last_seen_at null -> null', () {
        // Arrange
        final json = {
          'id': 'user-last-seen-null',
          'full_name': 'Last Seen Null User',
          'username': 'lastseennull',
          'last_seen_at': null,
          'created_at': fixedCreatedAtString,
        };

        // Act
        final user = UserModel.fromJson(json);

        // Assert
        expect(user.lastSeenAt, isNull);
      });
    });

    group('toJson', () {
      test(
        'toJson produces correct key mappings (full_name, avatar_url, etc.)',
        () {
          // Arrange
          final user = UserModel(
            id: 'user-to-json',
            email: 'user@example.com',
            phone: '+905550001122',
            fullName: 'Mehmet Öz',
            username: 'mehmetoz',
            avatarUrl: 'https://example.com/photo.jpg',
            title: UserTitle.endodontist,
            bio: 'Endodontist bio',
            university: 'Ege Üniversitesi',
            city: 'İzmir',
            experienceYears: 5,
            workplace: 'Klinik A',
            followersCount: 10,
            followingCount: 20,
            postsCount: 30,
            onboardingCompleted: true,
            isVerified: true,
            lastSeenAt: fixedLastSeenAt,
            createdAt: fixedCreatedAt,
          );

          // Act
          final json = user.toJson();

          // Assert
          expect(json['id'], equals('user-to-json'));
          expect(json['email'], equals('user@example.com'));
          expect(json['phone'], equals('+905550001122'));
          expect(json['full_name'], equals('Mehmet Öz'));
          expect(json['username'], equals('mehmetoz'));
          expect(json['avatar_url'], equals('https://example.com/photo.jpg'));
          expect(json['title'], equals(UserTitle.endodontist.dbValue));
          expect(json['bio'], equals('Endodontist bio'));
          expect(json['university'], equals('Ege Üniversitesi'));
          expect(json['city'], equals('İzmir'));
          expect(json['experience_years'], equals(5));
          expect(json['workplace'], equals('Klinik A'));
          expect(json['followers_count'], equals(10));
          expect(json['following_count'], equals(20));
          expect(json['posts_count'], equals(30));
          expect(json['onboarding_completed'], isTrue);
          expect(json['is_verified'], isTrue);
          expect(json['last_seen_at'], equals(fixedLastSeenAtString));
          expect(json['created_at'], equals(fixedCreatedAtString));
        },
      );

      test(
        'fromJson -> toJson -> fromJson round-trip produces equal object',
        () {
          // Arrange
          final initialJson = {
            'id': 'user-roundtrip',
            'email': 'roundtrip@test.com',
            'phone': '+905559998877',
            'full_name': 'Round Trip User',
            'username': 'roundtrip',
            'avatar_url': 'https://example.com/rt.png',
            'title': 'periodontolog',
            'bio': 'Periodontolog specialist',
            'university': 'İstanbul Üniversitesi',
            'city': 'İstanbul',
            'experience_years': 12,
            'workplace': 'DentLink Center',
            'followers_count': 500,
            'following_count': 250,
            'posts_count': 42,
            'onboarding_completed': true,
            'is_verified': true,
            'last_seen_at': fixedLastSeenAtString,
            'created_at': fixedCreatedAtString,
          };

          // Act
          final initialUser = UserModel.fromJson(initialJson);
          final serializedJson = initialUser.toJson();
          final deserializedUser = UserModel.fromJson(serializedJson);

          // Assert
          expect(deserializedUser, equals(initialUser));
        },
      );
    });

    group('copyWith', () {
      test('copyWith with no args returns equal object', () {
        // Arrange
        final user = UserModel(
          id: 'user-cw',
          email: 'copy@example.com',
          phone: '+905551112233',
          fullName: 'Original Name',
          username: 'original',
          avatarUrl: 'https://example.com/orig.png',
          title: UserTitle.disHekimi,
          bio: 'Bio',
          university: 'Ankara Üniversitesi',
          city: 'Ankara',
          experienceYears: 3,
          workplace: 'Klinik B',
          followersCount: 15,
          followingCount: 25,
          postsCount: 5,
          onboardingCompleted: true,
          isVerified: false,
          lastSeenAt: fixedLastSeenAt,
          createdAt: fixedCreatedAt,
        );

        // Act
        final copy = user.copyWith();

        // Assert
        expect(copy, equals(user));
      });

      test('copyWith with specific field changes only that field', () {
        // Arrange
        final user = UserModel(
          id: 'user-cw-diff',
          email: 'user@example.com',
          phone: '+905551112233',
          fullName: 'Original Name',
          username: 'originaluser',
          avatarUrl: 'https://example.com/orig.png',
          title: UserTitle.ogrenci,
          bio: 'Old Bio',
          university: 'Gazi Üniversitesi',
          city: 'Ankara',
          experienceYears: 1,
          workplace: 'Staj',
          followersCount: 10,
          followingCount: 20,
          postsCount: 2,
          onboardingCompleted: false,
          isVerified: false,
          lastSeenAt: fixedLastSeenAt,
          createdAt: fixedCreatedAt,
        );

        // Act
        final updated = user.copyWith(
          fullName: 'Updated Name',
          title: UserTitle.pedodontist,
          followersCount: 50,
          onboardingCompleted: true,
        );

        // Assert
        expect(updated.fullName, equals('Updated Name'));
        expect(updated.title, equals(UserTitle.pedodontist));
        expect(updated.followersCount, equals(50));
        expect(updated.onboardingCompleted, isTrue);

        // Verify remaining fields are preserved
        expect(updated.id, equals(user.id));
        expect(updated.email, equals(user.email));
        expect(updated.phone, equals(user.phone));
        expect(updated.username, equals(user.username));
        expect(updated.avatarUrl, equals(user.avatarUrl));
        expect(updated.bio, equals(user.bio));
        expect(updated.university, equals(user.university));
        expect(updated.city, equals(user.city));
        expect(updated.experienceYears, equals(user.experienceYears));
        expect(updated.workplace, equals(user.workplace));
        expect(updated.followingCount, equals(user.followingCount));
        expect(updated.postsCount, equals(user.postsCount));
        expect(updated.isVerified, equals(user.isVerified));
        expect(updated.lastSeenAt, equals(user.lastSeenAt));
        expect(updated.createdAt, equals(user.createdAt));
      });
    });

    group('Equatable', () {
      test('Two UserModels with same props are equal', () {
        // Arrange
        final user1 = UserModel(
          id: 'user-eq',
          email: 'eq@example.com',
          phone: '+905550000000',
          fullName: 'Equal User',
          username: 'equaluser',
          avatarUrl: 'https://example.com/avatar.jpg',
          title: UserTitle.disHekimi,
          bio: 'Bio text',
          university: 'Hacettepe',
          city: 'Ankara',
          experienceYears: 4,
          workplace: 'Klinik',
          followersCount: 100,
          followingCount: 50,
          postsCount: 10,
          onboardingCompleted: true,
          isVerified: true,
          lastSeenAt: fixedLastSeenAt,
          createdAt: fixedCreatedAt,
        );
        final user2 = UserModel(
          id: 'user-eq',
          email: 'eq@example.com',
          phone: '+905550000000',
          fullName: 'Equal User',
          username: 'equaluser',
          avatarUrl: 'https://example.com/avatar.jpg',
          title: UserTitle.disHekimi,
          bio: 'Bio text',
          university: 'Hacettepe',
          city: 'Ankara',
          experienceYears: 4,
          workplace: 'Klinik',
          followersCount: 100,
          followingCount: 50,
          postsCount: 10,
          onboardingCompleted: true,
          isVerified: true,
          lastSeenAt: fixedLastSeenAt,
          createdAt: fixedCreatedAt,
        );

        // Act & Assert
        expect(user1, equals(user2));
        expect(user1.hashCode, equals(user2.hashCode));
      });

      test('Two UserModels with different id are not equal', () {
        // Arrange
        final user1 = UserModel(
          id: 'user-id-1',
          fullName: 'Same User',
          username: 'sameuser',
          title: UserTitle.disHekimi,
          createdAt: fixedCreatedAt,
        );
        final user2 = UserModel(
          id: 'user-id-2',
          fullName: 'Same User',
          username: 'sameuser',
          title: UserTitle.disHekimi,
          createdAt: fixedCreatedAt,
        );

        // Act & Assert
        expect(user1, isNot(equals(user2)));
      });
    });
  });
}
