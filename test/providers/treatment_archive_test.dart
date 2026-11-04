import 'package:dentigo/core/utils/paging.dart';
import 'package:dentigo/data/models/enums.dart';
import 'package:dentigo/data/models/post_model.dart';
import 'package:dentigo/data/models/user_model.dart';
import 'package:dentigo/data/providers/repository_providers.dart';
import 'package:dentigo/data/repositories/post_repository.dart';
import 'package:dentigo/providers/post_provider.dart';
import 'package:dentigo/providers/treatment_archive_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _author = UserModel(
  id: 'a',
  fullName: 'A',
  username: 'a',
  title: UserTitle.disHekimi,
  createdAt: DateTime(2024),
);

PostModel _post(String id) => CasePostModel(
  id: id,
  userId: 'a',
  title: 't',
  content: 'c',
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
  author: _author,
);

/// İlk sayfa dolu, ikinci sayfa tek post; çağrıları kaydeder.
class _Repo implements PostRepository {
  final calls = <({String? treatment, bool recent, int offset})>[];

  @override
  Future<List<PostModel>> popularPosts({
    String query = '',
    List<String> tags = const [],
    DentalBranch? branch,
    String? treatment,
    bool recent = false,
    required DateTime now,
    int offset = 0,
  }) async {
    calls.add((treatment: treatment, recent: recent, offset: offset));
    return offset == 0
        ? [for (var i = 0; i < pageSize; i++) _post('p$i')]
        : [_post('last')];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Repo repo;
  late ProviderContainer container;
  late ProviderSubscription<TreatmentArchiveState> sub;
  final provider = treatmentArchiveProvider('kron');

  setUp(() async {
    repo = _Repo();
    container = ProviderContainer(
      overrides: [searchRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    sub = container.listen(provider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
  });

  test('tedaviyle filtreler, en yeni önce açılır, sayfalar', () async {
    expect(container.read(provider).posts.value, hasLength(pageSize));
    await container.read(provider.notifier).loadMore();
    expect(repo.calls, [
      (treatment: 'kron', recent: true, offset: 0),
      (treatment: 'kron', recent: true, offset: pageSize),
    ]);
    expect(container.read(provider).hasMore, isFalse);
  });

  test('sıra değişince baştan yüklenir', () async {
    container.read(provider.notifier).setRecent(false);
    await Future<void>.delayed(Duration.zero);
    expect(repo.calls.last, (treatment: 'kron', recent: false, offset: 0));
  });

  test(
    'post sayfasındaki değişiklik açık arşive yansır, kapanınca kaydı düşer',
    () async {
      final ref = container.read(Provider((ref) => ref));
      patchPostCopies(ref, 'p1', null, (p) => p.copyWith(likeCount: 9));
      final p1 = container
          .read(provider)
          .posts
          .value!
          .firstWhere((p) => p.id == 'p1');
      expect(p1.likeCount, 9);
      expect(container.read(openArchivesProvider), {'kron'});

      sub.close();
      await Future<void>.delayed(Duration.zero);
      expect(container.read(openArchivesProvider), isEmpty);
    },
  );
}
