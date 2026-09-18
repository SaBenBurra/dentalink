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

  group('SupabasePostRepository - Bookmark Tests -', () {
    test('bookmarkPost throws Exception when not logged in', () async {
      // Arrange
      when(mockAuthClient.currentUser).thenReturn(null);

      // Act & Assert
      expect(() => repository.bookmarkPost('post-1'), throwsException);
    });

    test('unbookmarkPost throws Exception when not logged in', () async {
      // Arrange
      when(mockAuthClient.currentUser).thenReturn(null);

      // Act & Assert
      expect(() => repository.unbookmarkPost('post-1'), throwsException);
    });

    test('bookmarkPost upserts into bookmarks table and fetches updated post',
        () async {
      // Arrange
      final mockUser = MockUser();
      when(mockUser.id).thenReturn('current-user');
      when(mockAuthClient.currentUser).thenReturn(mockUser);

      // Mocks for upsert
      final mockUpsertQueryBuilder = MockSupabaseQueryBuilder();
      final mockUpsertFilterBuilder = MockPostgrestFilterBuilderList();

      when(
        mockSupabaseClient.from('bookmarks'),
      ).thenAnswer((_) => mockUpsertQueryBuilder);
      when(
        mockUpsertQueryBuilder.upsert(
          any,
          onConflict: anyNamed('onConflict'),
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

      // Mocks for getPostById (which is called inside bookmarkPost)
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
            'like_count': 0,
            'comment_count': 0,
            'bookmark_count': 1,
            'view_count': 0,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
            'users': {
              'id': 'author-1',
              'full_name': 'Author',
              'username': 'author',
              'title': 'ogrenci',
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
            'likes': [],
            'bookmarks': [
              {'id': 'bk-1', 'user_id': 'current-user'},
            ],
          }),
        );
      });

      // Act
      final post = await repository.bookmarkPost('post-1');

      // Assert
      final upsertArgs =
          verify(
                mockUpsertQueryBuilder.upsert(
                  captureAny,
                  onConflict: 'user_id,post_id',
                ),
              ).captured.single
              as Map<String, dynamic>;
      expect(upsertArgs['user_id'], 'current-user');
      expect(upsertArgs['post_id'], 'post-1');

      expect(post.id, 'post-1');
      expect(post.isBookmarked, isTrue);
      expect(post.bookmarkCount, 1);
    });

    test(
      'unbookmarkPost deletes from bookmarks table and fetches updated post',
      () async {
        // Arrange
        final mockUser = MockUser();
        when(mockUser.id).thenReturn('current-user');
        when(mockAuthClient.currentUser).thenReturn(mockUser);

        // Mocks for delete
        final mockDeleteQueryBuilder = MockSupabaseQueryBuilder();
        final mockDeleteFilterBuilder = MockPostgrestFilterBuilderList();

        when(
          mockSupabaseClient.from('bookmarks'),
        ).thenAnswer((_) => mockDeleteQueryBuilder);
        when(
          mockDeleteQueryBuilder.delete(),
        ).thenAnswer((_) => mockDeleteFilterBuilder);
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

        // Mocks for getPostById
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
              'like_count': 0,
              'comment_count': 0,
              'bookmark_count': 0,
              'view_count': 0,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
              'users': {
                'id': 'author-1',
                'full_name': 'Author',
                'username': 'author',
                'title': 'ogrenci',
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
              'likes': [],
              'bookmarks': [], // Boş, unbookmark edildi
            }),
          );
        });

        // Act
        final post = await repository.unbookmarkPost('post-1');

        // Assert
        verify(mockDeleteQueryBuilder.delete()).called(1);
        verify(mockDeleteFilterBuilder.eq('user_id', 'current-user')).called(1);
        verify(mockDeleteFilterBuilder.eq('post_id', 'post-1')).called(1);

        expect(post.id, 'post-1');
        expect(post.isBookmarked, isFalse);
        expect(post.bookmarkCount, 0);
      },
    );
  });

  group('SupabasePostRepository - Auth Guard Tests -', () {
    test('getFeed throws Exception when not logged in', () async {
      when(mockAuthClient.currentUser).thenReturn(null);
      expect(() => repository.getFeed(), throwsException);
    });

    test('getPostById throws Exception when not logged in', () async {
      when(mockAuthClient.currentUser).thenReturn(null);
      expect(() => repository.getPostById('post-1'), throwsException);
    });

    test('getPostsByUser throws Exception when not logged in', () async {
      when(mockAuthClient.currentUser).thenReturn(null);
      expect(() => repository.getPostsByUser('user-1'), throwsException);
    });

    test('searchPosts with empty query returns empty list', () async {
      final mockUser = MockUser();
      when(mockUser.id).thenReturn('current-user');
      when(mockAuthClient.currentUser).thenReturn(mockUser);

      final result = await repository.searchPosts('');
      expect(result, isEmpty);
    });

    test('searchPosts with whitespace-only query returns empty list', () async {
      final mockUser = MockUser();
      when(mockUser.id).thenReturn('current-user');
      when(mockAuthClient.currentUser).thenReturn(mockUser);

      final result = await repository.searchPosts('   ');
      expect(result, isEmpty);
    });
  });
}
