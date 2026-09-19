import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dentlink/data/repositories/supabase_user_repository.dart';
import 'package:dentlink/domain/enums/enums.dart';

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

  });
}
