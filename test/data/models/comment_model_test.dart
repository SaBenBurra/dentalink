import 'package:flutter_test/flutter_test.dart';
import 'package:dentlink/data/models/comment_model.dart';
import 'package:dentlink/data/models/user_model.dart';
import 'package:dentlink/data/models/enums.dart';

void main() {
  final testAuthor = UserModel(
    id: 'author-1',
    fullName: 'Dr. Test',
    username: 'drtest',
    title: UserTitle.disHekimi,
    createdAt: DateTime(2024, 1, 1),
  );

  group('CommentModel -', () {
    test('constructor sets correct defaults', () {
      final comment = CommentModel(
        id: 'comment-1',
        postId: 'post-1',
        userId: 'author-1',
        content: 'Güzel vaka!',
        createdAt: DateTime(2024, 6, 1),
        updatedAt: DateTime(2024, 6, 1),
        author: testAuthor,
      );

      expect(comment.id, 'comment-1');
      expect(comment.postId, 'post-1');
      expect(comment.content, 'Güzel vaka!');
      expect(comment.isBestAnswer, isFalse);
      expect(comment.likeCount, 0);
      expect(comment.isLiked, isFalse);
    });

    test('isBestAnswer can be set to true', () {
      final comment = CommentModel(
        id: 'comment-2',
        postId: 'post-1',
        userId: 'author-1',
        content: 'En iyi cevap',
        isBestAnswer: true,
        createdAt: DateTime(2024, 6, 1),
        updatedAt: DateTime(2024, 6, 1),
        author: testAuthor,
      );

      expect(comment.isBestAnswer, isTrue);
    });

    test('copyWith changes specific fields', () {
      final original = CommentModel(
        id: 'comment-1',
        postId: 'post-1',
        userId: 'author-1',
        content: 'Orijinal',
        likeCount: 3,
        isLiked: false,
        isBestAnswer: false,
        createdAt: DateTime(2024, 6, 1),
        updatedAt: DateTime(2024, 6, 1),
        author: testAuthor,
      );

      final updated = original.copyWith(
        likeCount: 4,
        isLiked: true,
        isBestAnswer: true,
      );

      expect(updated.likeCount, 4);
      expect(updated.isLiked, isTrue);
      expect(updated.isBestAnswer, isTrue);
      // Değişmeyen alanlar
      expect(updated.id, 'comment-1');
      expect(updated.content, 'Orijinal');
      expect(updated.postId, 'post-1');
    });

    test('equality: same id means equal', () {
      final a = CommentModel(
        id: 'c-1', postId: 'p-1', userId: 'u-1',
        content: 'X', createdAt: DateTime(2024),
        updatedAt: DateTime(2024), author: testAuthor,
      );
      final b = CommentModel(
        id: 'c-1', postId: 'p-2', userId: 'u-2',
        content: 'Y', createdAt: DateTime(2025),
        updatedAt: DateTime(2025), author: testAuthor,
      );
      expect(a, equals(b));
    });

    test('equality: different id means not equal', () {
      final a = CommentModel(
        id: 'c-1', postId: 'p-1', userId: 'u-1',
        content: 'X', createdAt: DateTime(2024),
        updatedAt: DateTime(2024), author: testAuthor,
      );
      final b = CommentModel(
        id: 'c-2', postId: 'p-1', userId: 'u-1',
        content: 'X', createdAt: DateTime(2024),
        updatedAt: DateTime(2024), author: testAuthor,
      );
      expect(a, isNot(equals(b)));
    });

    test('hashCode is based on id', () {
      final comment = CommentModel(
        id: 'c-abc', postId: 'p-1', userId: 'u-1',
        content: 'test', createdAt: DateTime(2024),
        updatedAt: DateTime(2024), author: testAuthor,
      );
      expect(comment.hashCode, 'c-abc'.hashCode);
    });
  });
}
