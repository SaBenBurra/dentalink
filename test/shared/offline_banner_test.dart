import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dentlink/core/error/app_failures.dart';
import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'package:dentlink/core/utils/paging.dart';
import 'package:dentlink/data/models/post_model.dart';
import 'package:dentlink/data/providers/repository_providers.dart';
import 'package:dentlink/data/repositories/post_repository.dart';
import 'package:dentlink/providers/connectivity_provider.dart';
import 'package:dentlink/providers/feed_provider.dart';
import 'package:dentlink/shared/widgets/offline_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// İlk istek ağ hatası verir, sonrakiler boş sayfa döner.
class _FlakyFeedRepo implements PostRepository {
  int calls = 0;

  @override
  Future<PageResult<PostModel>> getFeed({PageCursor? before}) async {
    if (calls++ == 0) throw const NetworkFailure();
    return (items: <PostModel>[], next: null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late StreamController<List<ConnectivityResult>> net;

  setUp(() {
    net = StreamController();
    addTearDown(net.close);
  });

  test('isOnline: bilinmiyorsa true, yalnızca none ise false', () async {
    final container = ProviderContainer(
      overrides: [connectivityProvider.overrideWith((_) => net.stream)],
    );
    addTearDown(container.dispose);
    container.listen(isOnlineProvider, (_, _) {});
    expect(container.read(isOnlineProvider), isTrue);

    net.add([ConnectivityResult.none]);
    await pumpEventQueue();
    expect(container.read(isOnlineProvider), isFalse);

    net.add([ConnectivityResult.none, ConnectivityResult.vpn]);
    await pumpEventQueue();
    expect(container.read(isOnlineProvider), isTrue);
  });

  test('feed hatadaysa bağlantı gelince kendiliğinden yeniden dener', () async {
    final repo = _FlakyFeedRepo();
    final container = ProviderContainer(overrides: [
      feedRepositoryProvider.overrideWithValue(repo),
      connectivityProvider.overrideWith((_) => net.stream),
    ]);
    addTearDown(container.dispose);
    container.listen(feedProvider, (_, _) {});
    net.add([ConnectivityResult.none]);
    await pumpEventQueue();
    expect(container.read(feedProvider).hasError, isTrue);

    net.add([ConnectivityResult.mobile]);
    await pumpEventQueue();

    expect(repo.calls, 2);
    expect(container.read(feedProvider).requireValue, isEmpty);
  });

  testWidgets('çevrimdışıyken şerit görünür, bağlantı gelince kaybolur; sayfa korunur',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [connectivityProvider.overrideWith((_) => net.stream)],
      child: MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => OfflineBanner(child: child!),
        home: const _Counter(),
      ),
    ));
    await tester.tap(find.byType(_Counter));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);

    net.add([ConnectivityResult.none]);
    await tester.pump();
    await tester.pump(); // olay bir microtask sonra gelir
    expect(find.text('İnternet bağlantısı yok'), findsOneWidget);
    expect(find.text('1'), findsOneWidget); // state kaybolmadı

    net.add([ConnectivityResult.wifi]);
    await tester.pump();
    await tester.pump(); // olay bir microtask sonra gelir
    expect(find.text('İnternet bağlantısı yok'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}

/// Ağacın yeniden kurulup kurulmadığını görmek için yerel state tutar.
class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int _n = 0;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => setState(() => _n++),
        child: Material(child: Text('$_n')),
      );
}
