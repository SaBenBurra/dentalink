import '../datasources/mock_datasource.dart';
import '../models/enums.dart';
import '../models/post_model.dart';
import 'post_repository.dart';

/// Sahte gönderi repository. Faz 3'te SupabasePostRepository ile swap edilir.
class MockPostRepository implements PostRepository {
  static const _delay = Duration(milliseconds: 400);

  // In-memory mutable state — beğeni ve bookmark değişikliklerini tutar.
  final Map<String, PostModel> _postOverrides = {};

  PostModel _resolve(PostModel p) => _postOverrides[p.id] ?? p;

  @override
  Future<List<PostModel>> getFeed({bool chronological = true}) async {
    await Future.delayed(_delay);
    final all = MockDatasource.posts.map(_resolve).toList();

    if (chronological) {
      all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      // Algoritmik: basit skor = like + comment*2 + bookmark*3
      all.sort((a, b) {
        final scoreA = a.likeCount + a.commentCount * 2 + a.bookmarkCount * 3;
        final scoreB = b.likeCount + b.commentCount * 2 + b.bookmarkCount * 3;
        return scoreB.compareTo(scoreA);
      });
    }
    return all;
  }

  @override
  Future<PostModel> getPostById(String id) async {
    await Future.delayed(_delay);
    final post = MockDatasource.posts.firstWhere((p) => p.id == id);
    return _resolve(post);
  }

  @override
  Future<List<PostModel>> getPostsByUser(String userId) async {
    await Future.delayed(_delay);
    return MockDatasource.posts
        .where((p) => p.userId == userId)
        .map(_resolve)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<PostModel>> getBookmarkedPosts() async {
    await Future.delayed(_delay);
    return MockDatasource.posts
        .map(_resolve)
        .where((p) => p.isBookmarked)
        .toList();
  }

  @override
  Future<List<PostModel>> searchPosts(
    String query, {
    DentalBranch? branch,
    PostType? type,
  }) async {
    await Future.delayed(_delay);
    final q = query.toLowerCase();
    return MockDatasource.posts.map(_resolve).where((p) {
      final matchesText =
          p.title.toLowerCase().contains(q) ||
          p.content.toLowerCase().contains(q) ||
          p.tags.any((t) => t.name.toLowerCase().contains(q));
      final matchesBranch = branch == null || p.branch == branch;
      final matchesType = type == null || p.type == type;
      return matchesText && matchesBranch && matchesType;
    }).toList();
  }

  @override
  Future<PostModel> likePost(String postId) async {
    await Future.delayed(_delay);
    final current = _resolve(MockDatasource.postById(postId));
    final updated = current.copyWith(
      isLiked: true,
      likeCount: current.likeCount + 1,
    );
    _postOverrides[postId] = updated;
    return updated;
  }

  @override
  Future<PostModel> unlikePost(String postId) async {
    await Future.delayed(_delay);
    final current = _resolve(MockDatasource.postById(postId));
    final updated = current.copyWith(
      isLiked: false,
      likeCount: (current.likeCount - 1).clamp(0, 9999),
    );
    _postOverrides[postId] = updated;
    return updated;
  }

  @override
  Future<PostModel> bookmarkPost(String postId) async {
    await Future.delayed(_delay);
    final current = _resolve(MockDatasource.postById(postId));
    final updated = current.copyWith(
      isBookmarked: true,
      bookmarkCount: current.bookmarkCount + 1,
    );
    _postOverrides[postId] = updated;
    return updated;
  }

  @override
  Future<PostModel> unbookmarkPost(String postId) async {
    await Future.delayed(_delay);
    final current = _resolve(MockDatasource.postById(postId));
    final updated = current.copyWith(
      isBookmarked: false,
      bookmarkCount: (current.bookmarkCount - 1).clamp(0, 9999),
    );
    _postOverrides[postId] = updated;
    return updated;
  }

  @override
  Future<void> incrementViewCount(String postId) async {
    // Mock: view count artışı in-memory saklanır ama UI'a yansıtılmaz.
    await Future.delayed(const Duration(milliseconds: 100));
  }
}
