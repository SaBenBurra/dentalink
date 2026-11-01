import 'package:dentlink/core/utils/paging.dart';
import 'package:dentlink/core/utils/string_utils.dart';
import 'package:dentlink/data/models/enums.dart';
import 'package:dentlink/data/models/post_model.dart';
import 'package:dentlink/data/models/user_model.dart';
import 'package:dentlink/data/providers/repository_providers.dart';
import 'package:dentlink/data/repositories/post_repository.dart';
import 'package:dentlink/data/repositories/user_repository.dart';
import 'package:dentlink/providers/search_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _author = UserModel(
  id: 'a',
  fullName: 'A',
  username: 'a',
  title: UserTitle.disHekimi,
  createdAt: DateTime(2024),
);

PostModel _post(String id) => QuestionPostModel(
      id: id,
      userId: 'a',
      title: 't',
      content: 'c',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
      author: _author,
    );

typedef _Call = ({String query, List<String> tags, DentalBranch? branch, int offset});

/// İlk sayfa dolu (pageSize), ikinci sayfa tek post; çağrıları kaydeder.
class _Repo implements PostRepository {
  final calls = <_Call>[];

  @override
  Future<List<PostModel>> popularPosts({
    String query = '',
    List<String> tags = const [],
    DentalBranch? branch,
    required DateTime now,
    int offset = 0,
  }) async {
    calls.add((query: query, tags: tags, branch: branch, offset: offset));
    return offset == 0
        ? [for (var i = 0; i < pageSize; i++) _post('p$i')]
        : [_post('p0'), _post('last')];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Users implements UserRepository {
  final queries = <String>[];

  @override
  Future<List<UserModel>> searchUsers(String query) async {
    queries.add(query);
    return [_author];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('arama satırı', () {
    test('parseExploreQuery etiketi metinden ayırır', () {
      final q = parseExploreQuery(' kanal  #implant tedavi #kök_kanal # ');
      expect(q.text, 'kanal tedavi');
      expect(q.tags, ['implant', 'kök_kanal']);
    });

    test('hashtag boşluğu alt çizgiye çevirir', () {
      expect(hashtag('kök kanal tedavisi'), '#kök_kanal_tedavisi');
    });

    test('typingTag yalnızca son sözcük #… iken', () {
      expect(typingTag('kanal #imp'), 'imp');
      expect(typingTag('#implant '), isNull);
      expect(typingTag('kanal'), isNull);
      expect(typingTag(''), isNull);
    });

    test('compareTurkish Ç, Ö harflerini kendi yerine koyar', () {
      final names = ['Restoratif', 'Çene Cerrahisi', 'Oral Diagnoz', 'Endodonti', 'Ön', 'Cerrahi'];
      names.sort(compareTurkish);
      expect(names, ['Cerrahi', 'Çene Cerrahisi', 'Endodonti', 'Oral Diagnoz', 'Ön', 'Restoratif']);
    });
  });

  group('SearchNotifier', () {
    late _Repo repo;
    late _Users users;
    late ProviderContainer container;

    setUp(() async {
      repo = _Repo();
      users = _Users();
      container = ProviderContainer(overrides: [
        searchRepositoryProvider.overrideWithValue(repo),
        userRepositoryProvider.overrideWithValue(users),
      ]);
      container.listen(searchProvider, (_, _) {});
      await pumpEventQueue();
    });

    tearDown(() => container.dispose());

    SearchNotifier notifier() => container.read(searchProvider.notifier);
    SearchState state() => container.read(searchProvider);

    test('açılışta filtresiz popüler postlar; kişi aranmaz', () {
      final first = repo.calls.single;
      expect((first.query, first.branch, first.offset), ('', null, 0));
      expect(first.tags, isEmpty);
      expect(state().posts.value, hasLength(pageSize));
      expect(state().hasMore, isTrue);
      expect(users.queries, isEmpty);
    });

    test('arama ve branş birlikte uygulanır; kişi araması yalnızca metinle', () async {
      notifier().setBranch(DentalBranch.endodonti);
      notifier().search('kanal #eğe');
      await pumpEventQueue();
      final last = repo.calls.last;
      expect(last.query, 'kanal');
      expect(last.tags, ['eğe']);
      expect(last.branch, DentalBranch.endodonti);
      expect(users.queries, ['kanal']);
      expect(state().users.value, hasLength(1));
    });

    test('popüler etiket: sorgu yalnızca etiket olur, branş Tümü', () async {
      notifier().setBranch(DentalBranch.ortodonti);
      notifier().search('braket');
      await pumpEventQueue();
      notifier().selectTag('şeffaf plak');
      await pumpEventQueue();
      expect(state().query, '#şeffaf_plak');
      expect(state().branch, isNull);
      final last = repo.calls.last;
      expect((last.query, last.branch, last.offset), ('', null, 0));
      expect(last.tags, ['şeffaf_plak']);
      expect(state().users.value, isEmpty);
      expect(state().isOnlyTag('şeffaf plak'), isTrue);
      expect(state().isOnlyTag('braket'), isFalse);
      notifier().search('#şeffaf_plak kalın');
      expect(state().isOnlyTag('şeffaf plak'), isFalse);
    });

    test('loadMore offset ile ekler, tekrar eden postu atar, son sayfada durur', () async {
      await notifier().loadMore();
      expect(repo.calls.last.offset, pageSize);
      expect(state().posts.value!.map((p) => p.id), [
        for (var i = 0; i < pageSize; i++) 'p$i',
        'last',
      ]);
      expect(state().hasMore, isFalse);
    });
  });

}
