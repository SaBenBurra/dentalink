import 'package:flutter_test/flutter_test.dart';
import 'package:dentlink/data/models/post_model.dart';
import 'package:dentlink/data/models/enums.dart';
import 'package:dentlink/data/models/tag_model.dart';
import 'package:dentlink/data/models/user_model.dart';

void main() {
  final testAuthor = UserModel(
    id: 'author-1',
    fullName: 'Test Author',
    username: 'testauthor',
    title: UserTitle.disHekimi,
    createdAt: DateTime(2024, 1, 1),
  );

  final testTag = TagModel(
    id: 'tag-1',
    name: 'endodonti',
    slug: 'endodonti',
    usageCount: 5,
  );

  group('CasePostModel -', () {
    test('constructor creates model with correct defaults', () {
      final post = CasePostModel(
        id: 'case-1',
        userId: 'author-1',
        title: 'Test Case',
        content: 'Case content',
        createdAt: DateTime(2024, 6, 1),
        updatedAt: DateTime(2024, 6, 1),
        author: testAuthor,
      );

      expect(post.id, 'case-1');
      expect(post.type, PostType.casePost);
      expect(post.likeCount, 0);
      expect(post.commentCount, 0);
      expect(post.bookmarkCount, 0);
      expect(post.viewCount, 0);
      expect(post.isLiked, isFalse);
      expect(post.isBookmarked, isFalse);
      expect(post.tags, isEmpty);
      expect(post.branch, isNull);
      expect(post.imageUrls, isEmpty);
    });

    test('constructor with all fields sets values correctly', () {
      final post = CasePostModel(
        id: 'case-2',
        userId: 'author-1',
        title: 'Full Case',
        content: 'Full content',
        branch: DentalBranch.endodonti,
        imageUrls: ['url1.jpg', 'url2.jpg'],
        tags: [testTag],
        likeCount: 10,
        commentCount: 5,
        bookmarkCount: 3,
        viewCount: 100,
        isLiked: true,
        isBookmarked: true,
        createdAt: DateTime(2024, 6, 1),
        updatedAt: DateTime(2024, 6, 2),
        author: testAuthor,
      );

      expect(post.branch, DentalBranch.endodonti);
      expect(post.imageUrls, hasLength(2));
      expect(post.tags, hasLength(1));
      expect(post.likeCount, 10);
      expect(post.isLiked, isTrue);
      expect(post.isBookmarked, isTrue);
    });

    test('copyWith creates new instance with changed fields', () {
      final original = CasePostModel(
        id: 'case-1',
        userId: 'author-1',
        title: 'Original',
        content: 'Original content',
        likeCount: 5,
        isLiked: false,
        createdAt: DateTime(2024, 6, 1),
        updatedAt: DateTime(2024, 6, 1),
        author: testAuthor,
      );

      final copied = original.copyWith(
        title: 'Updated',
        likeCount: 6,
        isLiked: true,
      );

      expect(copied.title, 'Updated');
      expect(copied.likeCount, 6);
      expect(copied.isLiked, isTrue);
      // Unchanged fields
      expect(copied.id, 'case-1');
      expect(copied.content, 'Original content');
      expect(copied.userId, 'author-1');
    });

    test('copyWith with no args returns equivalent object', () {
      final original = CasePostModel(
        id: 'case-1',
        userId: 'author-1',
        title: 'Title',
        content: 'Content',
        branch: DentalBranch.ortodonti,
        createdAt: DateTime(2024, 6, 1),
        updatedAt: DateTime(2024, 6, 1),
        author: testAuthor,
      );

      final copied = original.copyWith();
      expect(copied.id, original.id);
      expect(copied.title, original.title);
      expect(copied.branch, original.branch);
    });

    test('is PostModel (sealed class hierarchy)', () {
      final post = CasePostModel(
        id: 'case-1',
        userId: 'author-1',
        title: 'Test',
        content: 'Content',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
        author: testAuthor,
      );

      expect(post, isA<PostModel>());
      expect(post, isA<CasePostModel>());
    });
  });

  group('QuestionPostModel -', () {
    test('constructor creates model with correct defaults', () {
      final post = QuestionPostModel(
        id: 'question-1',
        userId: 'author-1',
        title: 'Test Question',
        content: 'Question content',
        createdAt: DateTime(2024, 6, 1),
        updatedAt: DateTime(2024, 6, 1),
        author: testAuthor,
      );

      expect(post.id, 'question-1');
      expect(post.type, PostType.question);
      expect(post.isSolved, isFalse);
      expect(post.likeCount, 0);
      expect(post.tags, isEmpty);
    });

    test('isSolved flag can be set', () {
      final post = QuestionPostModel(
        id: 'question-2',
        userId: 'author-1',
        title: 'Solved Question',
        content: 'Content',
        isSolved: true,
        createdAt: DateTime(2024, 6, 1),
        updatedAt: DateTime(2024, 6, 1),
        author: testAuthor,
      );

      expect(post.isSolved, isTrue);
    });

    test('copyWith changes isSolved', () {
      final original = QuestionPostModel(
        id: 'question-1',
        userId: 'author-1',
        title: 'Question',
        content: 'Content',
        isSolved: false,
        createdAt: DateTime(2024, 6, 1),
        updatedAt: DateTime(2024, 6, 1),
        author: testAuthor,
      );

      final copied = original.copyWith(isSolved: true);
      expect(copied.isSolved, isTrue);
      expect(copied.id, 'question-1');
      expect(copied.title, 'Question');
    });

    test('is PostModel (sealed class hierarchy)', () {
      final post = QuestionPostModel(
        id: 'q-1',
        userId: 'author-1',
        title: 'Test',
        content: 'Content',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
        author: testAuthor,
      );

      expect(post, isA<PostModel>());
      expect(post, isA<QuestionPostModel>());
    });
  });

  group('PostModel equality -', () {
    test('two posts with same id are equal', () {
      final post1 = CasePostModel(
        id: 'same-id',
        userId: 'author-1',
        title: 'Title 1',
        content: 'Content 1',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
        author: testAuthor,
      );
      final post2 = QuestionPostModel(
        id: 'same-id',
        userId: 'author-2',
        title: 'Title 2',
        content: 'Content 2',
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
        author: testAuthor,
      );

      expect(post1, equals(post2));
    });

    test('two posts with different id are not equal', () {
      final post1 = CasePostModel(
        id: 'id-1',
        userId: 'author-1',
        title: 'Title',
        content: 'Content',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
        author: testAuthor,
      );
      final post2 = CasePostModel(
        id: 'id-2',
        userId: 'author-1',
        title: 'Title',
        content: 'Content',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
        author: testAuthor,
      );

      expect(post1, isNot(equals(post2)));
    });

    test('hashCode is based on id', () {
      final post = CasePostModel(
        id: 'test-id',
        userId: 'author-1',
        title: 'Title',
        content: 'Content',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
        author: testAuthor,
      );

      expect(post.hashCode, 'test-id'.hashCode);
    });
  });
}
