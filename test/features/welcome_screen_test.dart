import 'package:flutter/material.dart';
import 'package:dentigo/features/feed/screens/feed_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/app_flow.dart';

void main() {
  testWidgets(
    'onaylı hesap ilk girişte "Hoş geldin" görür; buton feed\'e götürür, '
    'geri ok ve app bar yok',
    (tester) async {
      // Hareket azaltma açık: süzülme ve konfeti durur, ekran yerleşir.
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pumpDentigo(tester, welcomed: false);

      expect(find.text('Dentigo\'ya hoş geldin, Test! 🎉'), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);
      expect(find.byType(AppBar), findsNothing);

      await tester.tap(find.text('Hadi başlayalım'));
      await tester.pumpAndSettle();

      expect(find.byType(FeedScreen), findsOneWidget);
      expect(find.text('Dentigo\'ya hoş geldin, Test! 🎉'), findsNothing);
    },
  );
}
