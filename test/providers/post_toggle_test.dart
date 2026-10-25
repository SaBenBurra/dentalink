import 'dart:async';

import 'package:dentlink/core/error/app_failures.dart';
import 'package:dentlink/data/models/post_model.dart';
import 'package:dentlink/data/models/user_model.dart';
import 'package:dentlink/data/providers/repository_providers.dart';
import 'package:dentlink/data/repositories/post_repository.dart';
import 'package:dentlink/domain/enums/enums.dart';
import 'package:dentlink/providers/feed_provider.dart';
import 'package:dentlink/providers/post_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _post = QuestionPostModel(
  id: 'p1',
  userId: 'a',
  title: 't',
  content: 'c',
  likeCount: 5,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
  author: UserModel(
    id: 'a',
    fullName: 'A',
    username: 'a',
    title: UserTitle.disHekimi,
    createdAt: DateTime(2024),
  ),
);

/// Beğeni isteği testin elindeki [likeCompleter] tamamlanana kadar bekler.
class _Repo implements PostRepository {
  int feedCalls = 0;
  int likeCalls = 0;
  Completer<PostModel> likeCompleter = Completer();

  @override
  Future<List<PostModel>> getFeed({bool chronological = true}) async {
    feedCalls++;
    return [_post];
  }

  @override
  Future<PostModel> getPostById(String id) async => _post;

  @override
  Future<PostModel> likePost(String postId) {
    likeCalls++;
    return likeCompleter.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Repo repo;
  late ProviderContainer container;

  setUp(() async {
    repo = _Repo();
    container = ProviderContainer(overrides: [
      feedRepositoryProvider.overrideWithValue(repo),
      postActionRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);
    container.listen(feedProvider, (_, _) {});
    await container.read(feedProvider.future);
  });

  PostModel feedPost() => container.read(feedProvider).value!.single;

  test('beğeni anında görünür, istek dokunuşlar kesilince gider', () async {
    final future = container.read(feedProvider.notifier).toggleLike('p1');

    expect(feedPost().isLiked, isTrue);
    expect(feedPost().likeCount, 6);
    expect(repo.likeCalls, 0, reason: 'debounce süresi dolmadı');

    repo.likeCompleter.complete(_post.copyWith(isLiked: true, likeCount: 7));
    await future;

    expect(repo.likeCalls, 1);
    expect(feedPost().likeCount, 7, reason: 'sunucu sayacı esas alınır');
  });

  test('çift sayıda dokunuş istek atmaz, sayaç yalnızca 5↔6 gider', () async {
    final notifier = container.read(feedProvider.notifier);
    final first = notifier.toggleLike('p1');
    expect(feedPost().likeCount, 6);
    final second = notifier.toggleLike('p1');
    expect(feedPost().likeCount, 5);
    await Future.wait([first, second]);

    expect(repo.likeCalls, 0);
    expect(feedPost().isLiked, isFalse);
  });

  test('tek sayıda seri dokunuşta yalnızca son hâl için tek istek gider', () async {
    final notifier = container.read(feedProvider.notifier);
    final taps = [for (var i = 0; i < 3; i++) notifier.toggleLike('p1')];
    expect(feedPost().likeCount, 6);

    repo.likeCompleter.complete(_post.copyWith(isLiked: true, likeCount: 6));
    await Future.wait(taps);

    expect(repo.likeCalls, 1);
    expect(feedPost().isLiked, isTrue);
  });

  test('hata olursa beğeni geri alınır ve hata fırlatılır', () async {
    final future = container.read(feedProvider.notifier).toggleLike('p1');
    final failed = expectLater(future, throwsA(isA<NetworkFailure>()));
    repo.likeCompleter.future.ignore(); // istek debounce sonrası dinler
    repo.likeCompleter.completeError(const NetworkFailure());

    await failed;
    expect(feedPost().isLiked, isFalse);
    expect(feedPost().likeCount, 5);
  });

  test('detaydaki beğeni feed\'i yeniden çekmeden günceller', () async {
    container.listen(postDetailProvider('p1'), (_, _) {});
    await container.read(postDetailProvider('p1').future);

    final future = container.read(postDetailProvider('p1').notifier).toggleLike();
    repo.likeCompleter.complete(_post.copyWith(isLiked: true, likeCount: 6));
    await future;

    expect(container.read(postDetailProvider('p1')).value!.isLiked, isTrue);
    expect(feedPost().isLiked, isTrue);
    expect(repo.feedCalls, 1);
  });
}
