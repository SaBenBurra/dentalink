import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dentigo/core/theme/app_theme.dart';
import 'package:dentigo/core/l10n/generated/app_localizations.dart';
import 'package:dentigo/features/messaging/widgets/chat_input.dart';

void main() {
  for (final theme in [AppTheme.light, AppTheme.dark]) {
    testWidgets('send icon uses onPrimary when active (${theme.brightness})',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ChatInput(
            controller: TextEditingController(text: 'merhaba'),
            onSend: () {},
          ),
        ),
      ));
      final icon = tester.widget<Icon>(find.byIcon(Icons.arrow_upward_rounded));
      expect(icon.color, theme.colorScheme.onPrimary);
    });
  }
}
