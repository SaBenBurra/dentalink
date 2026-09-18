import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dentlink/data/repositories/supabase_post_repository.dart';

import '../../mocks/generate_mocks.mocks.dart';

void main() {
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockAuthClient;
  late SupabasePostRepository repository;

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockAuthClient = MockGoTrueClient();

    when(mockSupabaseClient.auth).thenReturn(mockAuthClient);

    repository = SupabasePostRepository(mockSupabaseClient);
  });

  group('SupabasePostRepository -', () {
    test(
      'likePost upserts into likes table and fetches updated post',
      () async {
        // Arrange
        final mockUser = MockUser();
        when(mockUser.id).thenReturn('current-user');
        when(mockAuthClient.currentUser).thenReturn(mockUser);

        // Mocks for upsert
        final mockUpsertQueryBuilder = MockSupabaseQueryBuilder();
        final mockUpsertFilterBuilder = MockPostgrestFilterBuilderList();

        when(
          mockSupabaseClient.from('likes'),
        ).thenAnswer((_) => mockUpsertQueryBuilder);
        when(
          mockUpsertQueryBuilder.upsert(
            any,
            onConflict: anyNamed('onConflict'),
            ignoreDuplicates: anyNamed('ignoreDuplicates'),
          ),
        ).thenAnswer((_) => mockUpsertFilterBuilder);
        when(
          mockUpsertFilterBuilder.then(any, onError: anyNamed('onError')),
        ).thenAnswer((invocation) {
          final callback =
              invocation.positionalArguments[0]
                  as dynamic Function(List<Map<String, dynamic>>);
          return Future.value(callback([]));
        });

        // Mocks for getPostById (which is called inside likePost)
        final mockPostQueryBuilder = MockSupabaseQueryBuilder();
        final mockPostFilterBuilder1 = MockPostgrestFilterBuilderList();
        final mockPostFilterBuilder2 = MockPostgrestFilterBuilderList();
        final mockPostFilterBuilder3 = MockPostgrestFilterBuilderList();

        when(
          mockSupabaseClient.from('posts'),
        ).thenAnswer((_) => mockPostQueryBuilder);
        when(
          mockPostQueryBuilder.select(any),
        ).thenAnswer((_) => mockPostFilterBuilder1);
        when(
          mockPostFilterBuilder1.eq('likes.user_id', 'current-user'),
        ).thenAnswer((_) => mockPostFilterBuilder2);
        when(
          mockPostFilterBuilder2.eq('bookmarks.user_id', 'current-user'),
        ).thenAnswer((_) => mockPostFilterBuilder3);

        final mockSingleFilterBuilder = MockPostgrestTransformBuilderMap();

        when(
          mockPostFilterBuilder3.eq('id', 'post-1'),
        ).thenAnswer((_) => mockPostFilterBuilder3);
        when(
          mockPostFilterBuilder3.single(),
        ).thenAnswer((_) => mockSingleFilterBuilder);
        when(
          mockSingleFilterBuilder.then(any, onError: anyNamed('onError')),
        ).thenAnswer((invocation) {
          final callback =
              invocation.positionalArguments[0]
                  as dynamic Function(Map<String, dynamic>);
          return Future.value(
            callback({
              'id': 'post-1',
              'user_id': 'author-1',
              'type': 'case',
              'title': 'Test Case',
              'content': 'Content',
              'branch': 'pedodontist',
              'like_count': 1,
              'comment_count': 0,
              'bookmark_count': 0,
              'view_count': 0,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
              'users': {
                'id': 'author-1',
                'full_name': 'Author',
                'username': 'author',
                'title': 'Ogrenci',
                'followers_count': 0,
                'following_count': 0,
                'posts_count': 0,
                'onboarding_completed': true,
                'is_verified': false,
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              },
              'post_images': [],
              'post_tags': [],
              'likes': [
                {'user_id': 'current-user'},
              ],
              'bookmarks': [],
            }),
          );
        });

        // Act
        final post = await repository.likePost('post-1');

        // Assert
        final upsertArgs =
            verify(
                  mockUpsertQueryBuilder.upsert(
                    captureAny,
                    onConflict: 'user_id,post_id',
                    ignoreDuplicates: true,
                  ),
                ).captured.single
                as Map<String, dynamic>;
        expect(upsertArgs['user_id'], 'current-user');
        expect(upsertArgs['post_id'], 'post-1');

        expect(post.id, 'post-1');
        expect(post.isLiked, isTrue);
        expect(post.likeCount, 1);
      },
    );

    test('likePost throws Exception when not logged in', () async {
      // Arrange
      when(mockAuthClient.currentUser).thenReturn(null);

      // Act & Assert
      expect(() => repository.likePost('post-1'), throwsException);
    });

    test('unlikePost deletes from likes table and fetches updated post', () async {
      // Arrange
      final mockUser = MockUser();
      when(mockUser.id).thenReturn('current-user');
      when(mockAuthClient.currentUser).thenReturn(mockUser);

      // Mocks for delete
      final mockDeleteQueryBuilder = MockSupabaseQueryBuilder();
      final mockDeleteFilterBuilder = MockPostgrestFilterBuilderList();

      when(
        mockSupabaseClient.from('likes'),
      ).thenAnswer((_) => mockDeleteQueryBuilder);
      when(mockDeleteQueryBuilder.delete()).thenAnswer((_) => mockDeleteFilterBuilder);
      when(
        mockDeleteFilterBuilder.eq('user_id', 'current-user'),
      ).thenAnswer((_) => mockDeleteFilterBuilder);
      when(
        mockDeleteFilterBuilder.eq('post_id', 'post-1'),
      ).thenAnswer((_) => mockDeleteFilterBuilder);
      when(
        mockDeleteFilterBuilder.then(any, onError: anyNamed('onError')),
      ).thenAnswer((invocation) {
        final callback =
            invocation.positionalArguments[0]
                as dynamic Function(List<Map<String, dynamic>>);
        return Future.value(callback([]));
      });

      // Mocks for getPostById (which is called inside unlikePost)
      final mockPostQueryBuilder = MockSupabaseQueryBuilder();
      final mockPostFilterBuilder1 = MockPostgrestFilterBuilderList();
      final mockPostFilterBuilder2 = MockPostgrestFilterBuilderList();
      final mockPostFilterBuilder3 = MockPostgrestFilterBuilderList();

      when(
        mockSupabaseClient.from('posts'),
      ).thenAnswer((_) => mockPostQueryBuilder);
      when(
        mockPostQueryBuilder.select(any),
      ).thenAnswer((_) => mockPostFilterBuilder1);
      when(
        mockPostFilterBuilder1.eq('likes.user_id', 'current-user'),
      ).thenAnswer((_) => mockPostFilterBuilder2);
      when(
        mockPostFilterBuilder2.eq('bookmarks.user_id', 'current-user'),
      ).thenAnswer((_) => mockPostFilterBuilder3);

      final mockSingleFilterBuilder = MockPostgrestTransformBuilderMap();

      when(
        mockPostFilterBuilder3.eq('id', 'post-1'),
      ).thenAnswer((_) => mockPostFilterBuilder3);
      when(
        mockPostFilterBuilder3.single(),
      ).thenAnswer((_) => mockSingleFilterBuilder);
      when(
        mockSingleFilterBuilder.then(any, onError: anyNamed('onError')),
      ).thenAnswer((invocation) {
        final callback =
            invocation.positionalArguments[0]
                as dynamic Function(Map<String, dynamic>);
        return Future.value(
          callback({
            'id': 'post-1',
            'user_id': 'author-1',
            'type': 'case',
            'title': 'Test Case',
            'content': 'Content',
            'branch': 'pedodontist',
            'like_count': 0, // Mock DB says no likes
            'comment_count': 0,
            'bookmark_count': 0,
            'view_count': 0,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
            'users': {
              'id': 'author-1',
              'full_name': 'Author',
              'username': 'author',
              'title': 'Ogrenci',
              'followers_count': 0,
              'following_count': 0,
              'posts_count': 0,
              'onboarding_completed': true,
              'is_verified': false,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            },
            'post_images': [],
            'post_tags': [],
            'likes': [], // Boş, unlike edildi
            'bookmarks': [],
          }),
        );
      });

      // Act
      final post = await repository.unlikePost('post-1');

      // Assert
      verify(mockDeleteQueryBuilder.delete()).called(1);
      verify(mockDeleteFilterBuilder.eq('user_id', 'current-user')).called(1);
      verify(mockDeleteFilterBuilder.eq('post_id', 'post-1')).called(1);

      expect(post.id, 'post-1');
      expect(post.isLiked, isFalse);
      expect(post.likeCount, 0);
    });
  });
}
