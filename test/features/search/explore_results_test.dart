import 'package:dentigo/core/l10n/generated/app_localizations.dart';
import 'package:dentigo/data/models/tag_model.dart';
import 'package:dentigo/features/search/widgets/search_results.dart';
import 'package:dentigo/providers/search_provider.dart';
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
      key: ValueKey(query), // her sorgu taze provider durumu
      overrides: [
        searchProvider.overrideWith(() => _FixedSearch(query)),
        popularTagsProvider.overrideWith(
          (ref) => const [
            TagModel(id: '1', name: 'implant', slug: 'implant', usageCount: 12),
          ],
        ),
      ],
      child: MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: ExploreResults(onTagTap: (_) {})),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('popüler etiketler yalnızca arama yokken görünür', (
    tester,
  ) async {
    await _pump(tester, '');
    expect(find.text('#implant'), findsOneWidget);
    expect(find.text('12 paylaşım'), findsOneWidget);

    await _pump(tester, 'kanal');
    expect(find.text('#implant'), findsNothing);
  });
}
