import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'package:dentlink/data/models/enums.dart';
import 'package:dentlink/features/auth/widgets/register_step_one.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final locale in const [Locale('tr'), Locale('en')]) {
    testWidgets('unvan kartları 360dp ekranda taşmıyor ($locale)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: RegisterStepOne(
              nameController: TextEditingController(),
              nameError: null,
              nameFocusNode: FocusNode(),
              selectedTitle: UserTitle.periodontolog,
              onNameChanged: (_) {},
              onTitleSelected: (_) {},
              acceptedTerms: false,
              onAcceptedTermsChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  }
}
