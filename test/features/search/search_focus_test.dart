import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'package:dentlink/data/models/tag_model.dart';
import 'package:dentlink/features/search/screens/search_screen.dart';
import 'package:dentlink/features/search/widgets/filter_chips.dart';
import 'package:dentlink/providers/search_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FixedSearch extends SearchNotifier {
  _FixedSearch(this.query);
  final String query;

  @override
  SearchState build() => SearchState(query: query, posts: const AsyncData([]));
}

Future<void> _pump(WidgetTester tester, String query) async {
  await tester.pumpWidget(
    ProviderScope(
      key: ValueKey(query),
      overrides: [
        searchProvider.overrideWith(() => _FixedSearch(query)),
        popularTagsProvider.overrideWith(
          (ref) => const [TagModel(id: '1', name: 'implant', slug: 'implant')],
        ),
      ],
      child: MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SearchScreen(autofocus: true),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('odakta sorgu boşken yalnızca branşlar kalır', (tester) async {
    await _pump(tester, '');
    expect(find.byType(BranchFilterChips), findsOneWidget);
    expect(find.text('#implant').hitTestable(), findsNothing);

    // Boş alana dokunmak odağı bırakır, keşfet içeriği geri gelir.
    await tester.tapAt(tester.getCenter(find.byKey(const ValueKey('empty'))));
    await tester.pumpAndSettle();
    expect(find.text('#implant').hitTestable(), findsOneWidget);
  });

  testWidgets('odakta sorgu varken sonuçlar görünür', (tester) async {
    await _pump(tester, 'kanal');
    expect(
      find.text(lookupAppLocalizations(const Locale('tr')).explorePopularPosts),
      findsOneWidget,
    );
  });

  testWidgets('odakta boşken çarpı görünür, basınca odak bırakılır', (
    tester,
  ) async {
    await _pump(tester, '');
    await tester.tap(find.byIcon(Icons.clear_rounded));
    await tester.pumpAndSettle();
    expect(find.text('#implant').hitTestable(), findsOneWidget);
    expect(find.byIcon(Icons.clear_rounded), findsNothing);
  });

  testWidgets('klavye kapanınca odak bırakılır', (tester) async {
    await _pump(tester, '');
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pump();
    expect(find.text('#implant').hitTestable(), findsNothing);

    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(find.text('#implant').hitTestable(), findsOneWidget);
  });
}
