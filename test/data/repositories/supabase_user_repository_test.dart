import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dentlink/data/repositories/supabase_user_repository.dart';
import 'package:dentlink/data/models/enums.dart';

import '../../mocks/generate_mocks.mocks.dart';

void main() {
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockAuthClient;
  late SupabaseUserRepository repository;

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockAuthClient = MockGoTrueClient();

    when(mockSupabaseClient.auth).thenReturn(mockAuthClient);

    repository = SupabaseUserRepository(client: mockSupabaseClient);
  });

  group('SupabaseUserRepository -', () {
    test('getUserById returns UserModel', () async {
      // Arrange
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockFilterBuilder = MockPostgrestFilterBuilderList();
      final mockTransformBuilder = MockPostgrestTransformBuilderMap();

      when(
        mockSupabaseClient.from('users'),
      ).thenAnswer((_) => mockQueryBuilder);
      when(mockQueryBuilder.select()).thenAnswer((_) => mockFilterBuilder);
      when(
        mockFilterBuilder.eq('id', '123'),
      ).thenAnswer((_) => mockFilterBuilder);
      when(mockFilterBuilder.single()).thenAnswer((_) => mockTransformBuilder);
      when(
        mockTransformBuilder.then(any, onError: anyNamed('onError')),
      ).thenAnswer((invocation) {
        final callback =
            invocation.positionalArguments[0]
                as dynamic Function(Map<String, dynamic>);
        return Future.value(
          callback({
            'id': '123',
            'email': 'test@example.com',
            'full_name': 'Test User',
            'username': 'testuser',
            'title': 'Ogrenci',
            'created_at': DateTime.now().toIso8601String(),
          }),
        );
      });

      // Act
      final user = await repository.getUserById('123');

      // Assert
      expect(user.id, '123');
      expect(user.fullName, 'Test User');
      verify(mockSupabaseClient.from('users')).called(1);
    });

    test('updateProfile calls update on users table', () async {
      // Arrange
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockFilterBuilder = MockPostgrestFilterBuilderList();

      when(
        mockSupabaseClient.from('users'),
      ).thenAnswer((_) => mockQueryBuilder);
      when(mockQueryBuilder.update(any)).thenAnswer((_) => mockFilterBuilder);
      when(
        mockFilterBuilder.eq('id', '123'),
      ).thenAnswer((_) => mockFilterBuilder);
      when(
        mockFilterBuilder.then(any, onError: anyNamed('onError')),
      ).thenAnswer((invocation) {
        final callback =
            invocation.positionalArguments[0]
                as dynamic Function(List<Map<String, dynamic>>);
        return Future.value(callback([]));
      });

      // Act
      await repository.updateProfile(
        '123',
        fullName: 'Updated Name',
        title: UserTitle.ortodontist,
      );

      // Assert
      final updateArgs =
          verify(mockQueryBuilder.update(captureAny)).captured.single
              as Map<String, dynamic>;
      expect(updateArgs['full_name'], 'Updated Name');
      expect(updateArgs['title'], UserTitle.ortodontist.dbValue);
      expect(updateArgs.containsKey('updated_at'), isTrue);

      verify(mockFilterBuilder.eq('id', '123')).called(1);
    });

    test('followUser inserts into follows table', () async {
      // Arrange
      final mockUser = MockUser();
      when(mockUser.id).thenReturn('current-user');
      when(mockAuthClient.currentUser).thenReturn(mockUser);

      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockFilterBuilder = MockPostgrestFilterBuilderList();

      when(
        mockSupabaseClient.from('follows'),
      ).thenAnswer((_) => mockQueryBuilder);
      when(
        mockQueryBuilder.upsert(any, onConflict: anyNamed('onConflict')),
      ).thenAnswer((_) => mockFilterBuilder);
      when(
        mockFilterBuilder.then(any, onError: anyNamed('onError')),
      ).thenAnswer((invocation) {
        final callback =
            invocation.positionalArguments[0]
                as dynamic Function(List<Map<String, dynamic>>);
        return Future.value(callback([]));
      });

      // Act
      await repository.followUser('target-user');

      // Assert
      final upsertArgs =
          verify(
                mockQueryBuilder.upsert(
                  captureAny,
                  onConflict: 'follower_id,following_id',
                ),
              ).captured.single
              as Map<String, dynamic>;
      expect(upsertArgs['follower_id'], 'current-user');
      expect(upsertArgs['following_id'], 'target-user');
    });

    test('followUser throws Exception when not logged in', () async {
      // Arrange
      when(mockAuthClient.currentUser).thenReturn(null);

      // Act & Assert
      expect(() => repository.followUser('target-user'), throwsException);
    });

    test('unfollowUser throws Exception when not logged in', () async {
      // Arrange
      when(mockAuthClient.currentUser).thenReturn(null);

      // Act & Assert
      expect(() => repository.unfollowUser('target-user'), throwsException);
    });

    test('isFollowingUser returns false when not logged in', () async {
      // Arrange
      when(mockAuthClient.currentUser).thenReturn(null);

      // Act
      final result = await repository.isFollowingUser('target-user');

      // Assert
      expect(result, isFalse);
    });

    test('getFollowedUserIds returns empty set when not logged in', () async {
      // Arrange
      when(mockAuthClient.currentUser).thenReturn(null);

      // Act
      final result = await repository.getFollowedUserIds(['user-1', 'user-2']);

      // Assert
      expect(result, isEmpty);
    });

    test('getFollowedUserIds returns empty set for empty input', () async {
      // Arrange
      final mockUser = MockUser();
      when(mockUser.id).thenReturn('current-user');
      when(mockAuthClient.currentUser).thenReturn(mockUser);

      // Act
      final result = await repository.getFollowedUserIds([]);

      // Assert
      expect(result, isEmpty);
    });

    test('unfollowUser calls delete on follows table', () async {
      // Arrange
      final mockUser = MockUser();
      when(mockUser.id).thenReturn('current-user');
      when(mockAuthClient.currentUser).thenReturn(mockUser);

      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockFilterBuilder = MockPostgrestFilterBuilderList();

      when(
        mockSupabaseClient.from('follows'),
      ).thenAnswer((_) => mockQueryBuilder);
      when(mockQueryBuilder.delete()).thenAnswer((_) => mockFilterBuilder);
      when(
        mockFilterBuilder.eq('follower_id', 'current-user'),
      ).thenAnswer((_) => mockFilterBuilder);
      when(
        mockFilterBuilder.eq('following_id', 'target-user'),
      ).thenAnswer((_) => mockFilterBuilder);
      when(
        mockFilterBuilder.then(any, onError: anyNamed('onError')),
      ).thenAnswer((invocation) {
        final callback =
            invocation.positionalArguments[0]
                as dynamic Function(List<Map<String, dynamic>>);
        return Future.value(callback([]));
      });

      // Act
      await repository.unfollowUser('target-user');

      // Assert
      verify(mockQueryBuilder.delete()).called(1);
      verify(mockFilterBuilder.eq('follower_id', 'current-user')).called(1);
      verify(mockFilterBuilder.eq('following_id', 'target-user')).called(1);
    });
  });
}
