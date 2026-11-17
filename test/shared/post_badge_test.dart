import 'dart:math';

import 'package:dentigo/core/constants/app_colors.dart';
import 'package:dentigo/core/l10n/generated/app_localizations.dart';
import 'package:dentigo/core/theme/dark_theme.dart';
import 'package:dentigo/core/theme/light_theme.dart';
import 'package:dentigo/data/models/enums.dart';
import 'package:dentigo/shared/widgets/post_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

void main() {
  Future<Color?> labelColor(
    WidgetTester tester,
    PostType type, {
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
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

  for (final (theme, surface) in [
    (buildLightTheme(), AppColors.lightSurface),
    (buildDarkTheme(), AppColors.darkSurface),
  ]) {
    for (final type in PostType.values) {
      testWidgets('${type.name} rozeti ${theme.brightness} zeminde ≥ 4.5:1', (
        tester,
      ) async {
        final text = (await labelColor(tester, type, theme: theme))!;
        final box = tester.widget<Container>(find.byType(Container).first);
        final tint = (box.decoration! as BoxDecoration).color!;
        final background = Color.alphaBlend(tint, surface);
        expect(_contrast(text, background), greaterThanOrEqualTo(4.5));
      });
    }
  }
}
