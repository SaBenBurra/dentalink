import 'package:dentlink/core/error/app_failures.dart';
import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'package:dentlink/data/models/enums.dart';
import 'package:dentlink/data/models/user_model.dart';
import 'package:dentlink/data/providers/repository_providers.dart';
import 'package:dentlink/data/repositories/user_repository.dart';
import 'package:dentlink/features/messaging/widgets/user_search_delegate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _suggested = UserModel(
  id: 'u1',
  fullName: 'Dr. Ayşe Kaya',
  username: 'aysekaya',
  title: UserTitle.endodontist,
  createdAt: DateTime(2024),
);

class _FakeUserRepo implements UserRepository {
  final queries = <String>[];
  var suggestionCalls = 0;
  var failSuggestions = false;

  @override
  Future<List<UserModel>> getSuggestedUsers() async {
    suggestionCalls++;
    if (failSuggestions) {
      failSuggestions = false;
      throw const ServerFailure();
    }
    return [_suggested];
  }

  @override
  Future<List<UserModel>> searchUsers(String query) async {
    queries.add(query);
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _openSearch(WidgetTester tester, _FakeUserRepo repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [userRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Consumer(
          builder: (context, ref, _) => Scaffold(
            body: TextButton(
              onPressed: () => showSearch(
                context: context,
                delegate: UserSearchDelegate(ref),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('hızlı yazınca yalnızca son sorgu için istek gider (BUG-22)', (
    tester,
  ) async {
    final repo = _FakeUserRepo();
    await _openSearch(tester, repo);

    for (final q in ['ay', 'ayş', 'ayşe']) {
      await tester.enterText(find.byType(TextField), q);
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle(const Duration(milliseconds: 400));

    expect(repo.queries, ['ayşe']);
  });

  testWidgets('açılışta önerilen kişiler listelenir, tekrar çekilmez', (
    tester,
  ) async {
    final repo = _FakeUserRepo();
    await _openSearch(tester, repo);
    expect(find.text('Dr. Ayşe Kaya'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ay');
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    expect(find.text('Dr. Ayşe Kaya'), findsNothing);

    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(find.text('Dr. Ayşe Kaya'), findsOneWidget);
    expect(repo.suggestionCalls, 1);
  });

  testWidgets('öneriler yüklenemezse tekrar dene çalışır', (tester) async {
    final repo = _FakeUserRepo()..failSuggestions = true;
    await _openSearch(tester, repo);
    expect(find.text('Dr. Ayşe Kaya'), findsNothing);

    await tester.tap(find.byType(TextButton).last);
    await tester.pumpAndSettle();
    expect(find.text('Dr. Ayşe Kaya'), findsOneWidget);
  });
}
