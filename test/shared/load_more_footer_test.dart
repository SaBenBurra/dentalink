import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'package:dentlink/shared/widgets/load_more_footer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Future<void> Function() onLoadMore) => MaterialApp(
      locale: const Locale('tr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: LoadMoreFooter(onLoadMore: onLoadMore)),
    );

void main() {
  testWidgets('görünürken yükler; sayfa geldikten sonra hâlâ ekrandaysa sıradakini ister',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(_app(() async => calls++));
    expect(calls, 1);

    await tester.pump();
    expect(calls, greaterThan(1));
  });

  testWidgets('hata olursa mesaj ve Tekrar Dene gösterir, dokununca yeniden ister',
      (tester) async {
    var calls = 0;
    var fail = true;
    await tester.pumpWidget(_app(() async {
      calls++;
      if (fail) throw Exception('ağ');
    }));
    await tester.pump();

    expect(find.text('Tekrar Dene'), findsOneWidget);
    expect(calls, 1);

    fail = false;
    await tester.tap(find.text('Tekrar Dene'));
    await tester.pump();
    expect(calls, greaterThan(1));
    expect(find.text('Tekrar Dene'), findsNothing);
  });
}
