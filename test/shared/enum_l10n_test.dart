import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'package:dentlink/data/models/enums.dart';
import 'package:dentlink/shared/extensions/dental_branch_ui.dart';
import 'package:dentlink/shared/extensions/user_title_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Enum etiketleri aktif dile göre ARB'den gelir (UX-12).
void main() {
  Future<BuildContext> pumpLocale(WidgetTester tester, Locale locale) async {
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      }),
    ));
    return ctx;
  }

  testWidgets('unvan ve branş adları TR/EN çevrilir', (tester) async {
    var ctx = await pumpLocale(tester, const Locale('tr'));
    expect(UserTitle.ogrenci.displayName(ctx), 'Öğrenci');
    expect(DentalBranch.endodonti.displayName(ctx), 'Endodonti');
    for (final t in UserTitle.values) {
      expect(t.displayName(ctx), isNotEmpty);
    }

    ctx = await pumpLocale(tester, const Locale('en'));
    expect(UserTitle.ogrenci.displayName(ctx), 'Student');
    expect(DentalBranch.endodonti.displayName(ctx), 'Endodontics');
    for (final b in DentalBranch.values) {
      expect(b.displayName(ctx), isNotEmpty);
    }
  });
}
