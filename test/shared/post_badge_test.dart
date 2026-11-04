import 'package:dentigo/core/constants/app_colors.dart';
import 'package:dentigo/core/l10n/generated/app_localizations.dart';
import 'package:dentigo/data/models/enums.dart';
import 'package:dentigo/shared/widgets/post_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<Color?> labelColor(WidgetTester tester, PostType type) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: PostBadge(postType: type)),
      ),
    );
    return tester.widget<Text>(find.byType(Text)).style?.color;
  }

  testWidgets('vaka rozeti mavi, soru rozeti teal; emoji yok', (tester) async {
    expect(
      await labelColor(tester, PostType.casePost),
      AppColors.secondaryDark,
    );
    expect(find.text('Vaka'), findsOneWidget);
    expect(await labelColor(tester, PostType.question), AppColors.primaryDark);
    expect(find.text('Forum'), findsOneWidget);
  });
}
