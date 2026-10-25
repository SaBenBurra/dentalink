import 'dart:async';

import 'package:dentlink/core/utils/paging.dart';
import 'package:dentlink/data/repositories/keyset.dart';
import 'package:flutter_test/flutter_test.dart';

final _c1 = (createdAt: DateTime.utc(2026, 10, 25, 10, 0, 0, 0, 123), id: 'b');

void main() {
  group('Pager', () {
    test('ilk sayfa imleci kaydeder; son sayfada hasMore false olur', () async {
      final pager = Pager<int>();
      final items = <int>[...pager.first((items: [1, 2], next: _c1))];
      expect(pager.hasMore, isTrue);

      PageCursor? asked;
      await pager.loadMore((before) async {
        asked = before;
        return (items: [3], next: null);
      }, items.addAll);

      expect(asked, _c1);
      expect(items, [1, 2, 3]);
      expect(pager.hasMore, isFalse);
      // Sayfa kalmadıysa istek gitmez.
      await pager.loadMore((_) => fail('istek gitmemeli'), items.addAll);
    });

    test('eşzamanlı çağrılar tek isteği paylaşır', () async {
      final pager = Pager<int>()..first((items: [1], next: _c1));
      final completer = Completer<PageResult<int>>();
      var calls = 0;
      final items = <int>[];
      Future<PageResult<int>> fetch(PageCursor _) {
        calls++;
        return completer.future;
      }

      final a = pager.loadMore(fetch, items.addAll);
      final b = pager.loadMore(fetch, items.addAll);
      completer.complete((items: [2], next: null));
      await Future.wait([a, b]);

      expect(calls, 1);
      expect(items, [2]);
    });

    test('reset sonrası gelen eski sayfa atılır', () async {
      final pager = Pager<int>()..first((items: [1], next: _c1));
      final completer = Completer<PageResult<int>>();
      final items = <int>[];

      final pending = pager.loadMore((_) => completer.future, items.addAll);
      pager.first((items: [9], next: null));
      completer.complete((items: [2], next: _c1));
      await pending;

      expect(items, isEmpty);
      expect(pager.hasMore, isFalse);
    });

    test('hata fırlatılır, imleç korunur ve tekrar denenebilir', () async {
      final pager = Pager<int>()..first((items: [1], next: _c1));
      final items = <int>[];

      await expectLater(
        pager.loadMore((_) async => throw Exception('ağ'), items.addAll),
        throwsException,
      );
      expect(pager.hasMore, isTrue);

      await pager.loadMore((_) async => (items: [2], next: null), items.addAll);
      expect(items, [2]);
    });
  });

  group('keyset', () {
    test('imleç (created_at, id) ikilisiyle eşitlikte id kırıcısı kullanır', () {
      expect(
        keysetFilter(_c1),
        'created_at.lt."2026-10-25T10:00:00.000123Z",'
        'and(created_at.eq."2026-10-25T10:00:00.000123Z",id.lt.b)',
      );
      expect(
        keysetFilter(_c1, ascending: true),
        'created_at.gt."2026-10-25T10:00:00.000123Z",'
        'and(created_at.eq."2026-10-25T10:00:00.000123Z",id.gt.b)',
      );
    });

    test('eksik sayfada imleç yok; dolu sayfada son satır imleçtir', () {
      Map<String, dynamic> row(int i) =>
          {'id': 'id$i', 'created_at': '2026-10-25T10:00:00.00012${i % 10}+00:00'};

      expect(nextCursor([for (var i = 0; i < pageSize - 1; i++) row(i)]), isNull);

      final next = nextCursor([for (var i = 0; i < pageSize; i++) row(i)]);
      expect(next?.id, 'id${pageSize - 1}');
      expect(next?.createdAt.toUtc().toIso8601String(), '2026-10-25T10:00:00.000129Z');
    });
  });
}
