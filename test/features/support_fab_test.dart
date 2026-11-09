import 'package:dentigo/core/l10n/generated/app_localizations.dart';
import 'package:dentigo/data/models/support_model.dart';
import 'package:dentigo/features/support/widgets/support_button.dart';
import 'package:dentigo/providers/support_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoThread extends SupportThreadNotifier {
  @override
  Future<SupportThread?> build() async => null;
}

void main() {
  testWidgets('destek butonu shell\'in yüzen alt barının üstünde durur', (
    tester,
  ) async {
    const barInset = 100.0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [supportThreadProvider.overrideWith(_NoThread.new)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // Shell gibi: bar yüksekliği yalnızca padding.bottom olarak verilir.
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(padding: const EdgeInsets.only(bottom: barInset)),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              floatingActionButton: SupportFab(
                bottomInset: SupportFab.insetOf(context),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final screen = tester.getSize(find.byType(Scaffold));
    final fab = tester.getRect(find.byType(FloatingActionButton));
    expect(fab.bottom, lessThanOrEqualTo(screen.height - barInset));
  });
}
