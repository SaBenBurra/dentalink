import 'package:dentigo/core/l10n/generated/app_localizations.dart';
import 'package:dentigo/data/models/enums.dart';
import 'package:dentigo/data/models/user_model.dart';
import 'package:dentigo/features/search/widgets/search_results.dart';
import 'package:dentigo/providers/search_provider.dart';
import 'package:dentigo/shared/widgets/user_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FixedSearch extends SearchNotifier {
  _FixedSearch(this.query, this.branch);
  final String query;
  final DentalBranch? branch;

  @override
  SearchState build() =>
      SearchState(query: query, branch: branch, posts: const AsyncData([]));
}

Future<void> _pump(
  WidgetTester tester,
  String query, {
  DentalBranch? branch,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      key: ValueKey((query, branch)), // her durum taze provider
      overrides: [
        searchProvider.overrideWith(() => _FixedSearch(query, branch)),
        popularUsersProvider.overrideWith(
          (ref) => [
            UserModel(
              id: 'u1',
              fullName: 'Ayşe Hekim',
              username: 'ayse',
              title: UserTitle.disHekimi,
              createdAt: DateTime(2024),
            ),
          ],
        ),
      ],
      child: MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: ExploreResults()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('popüler kişiler yalnızca Tümü\'de ve arama yokken görünür', (
    tester,
  ) async {
    await _pump(tester, '');
    expect(find.text('Popüler kişiler'), findsOneWidget);
    expect(find.text('Ayşe Hekim'), findsOneWidget);
    // Başlıkla aynı kenar boşluğu, ekranın kenarına yapışmaz.
    expect(
      tester.getTopLeft(find.byType(UserTile)).dx,
      tester.getTopLeft(find.text('Popüler kişiler')).dx,
    );
    expect(tester.getTopLeft(find.byType(UserTile)).dx, greaterThan(0));
    // Başlığın sağında ilk 50 listesine giden buton.
    expect(find.text('Tümünü gör'), findsOneWidget);

    await _pump(tester, 'kanal');
    expect(find.text('Popüler kişiler'), findsNothing);

    await _pump(tester, '', branch: DentalBranch.endodonti);
    expect(find.text('Popüler kişiler'), findsNothing);
  });

  testWidgets(
    'arama varken başlık "Arama sonuçları", yokken "Popüler gönderiler"',
    (tester) async {
      await _pump(tester, '');
      expect(find.text('Popüler gönderiler'), findsOneWidget);
      expect(find.text('Arama sonuçları'), findsNothing);

      await _pump(tester, 'kanal');
      expect(find.text('Arama sonuçları'), findsOneWidget);
      expect(find.text('Popüler gönderiler'), findsNothing);
    },
  );
}
