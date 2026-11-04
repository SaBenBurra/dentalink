import 'package:dentigo/core/l10n/generated/app_localizations.dart';
import 'package:dentigo/features/post/widgets/share_submit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _bar({
  required bool loading,
  bool shared = false,
  VoidCallback? onPressed,
  VoidCallback? onEnd,
}) => MaterialApp(
  locale: const Locale('tr'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    bottomNavigationBar: ShareSubmitBar(
      isLoading: loading,
      shared: shared,
      onPressed: onPressed ?? () {},
      onSharedAnimationEnd: onEnd,
    ),
  ),
);

void main() {
  testWidgets('paylaş butonu yüklenirken devre dışı', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_bar(loading: true, onPressed: () => taps++));
    await tester.tap(find.text('Paylaş'));
    expect(taps, 0);
    await tester.pumpWidget(_bar(loading: false, onPressed: () => taps++));
    await tester.tap(find.text('Paylaş'));
    expect(taps, 1);
  });

  testWidgets(
    'paylaşılınca onay animasyonu oynar, bitince bir kez haber verir',
    (tester) async {
      var ended = 0;
      var taps = 0;
      await tester.pumpWidget(_bar(loading: true));
      await tester.pumpWidget(
        _bar(
          loading: false,
          shared: true,
          onPressed: () => taps++,
          onEnd: () => ended++,
        ),
      );
      await tester.pump(ShareSubmitBar.successDuration * 0.8);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(ended, 0);
      await tester.tap(find.byIcon(Icons.check_rounded), warnIfMissed: false);
      expect(taps, 0); // animasyon sırasında tekrar gönderilmez
      await tester.pumpAndSettle();
      expect(ended, 1);
    },
  );
}
