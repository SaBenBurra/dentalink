import 'package:dentigo/core/l10n/generated/app_localizations.dart';
import 'package:dentigo/data/models/enums.dart';
import 'package:dentigo/data/models/user_model.dart';
import 'package:dentigo/features/search/screens/popular_people_screen.dart';
import 'package:dentigo/providers/search_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('gerçek sıra gösterilir, engellenenin numarası atlanır', (
    tester,
  ) async {
    UserModel u(String name) => UserModel(
      id: name,
      fullName: name,
      username: name,
      title: UserTitle.disHekimi,
      createdAt: DateTime(2024),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // 2. sıradaki kişi engelli: sunucu onu döndürmez.
          topPeopleProvider.overrideWith(
            (ref) => [(user: u('Ali'), rank: 1), (user: u('Can'), rank: 3)],
          ),
        ],
        child: MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PopularPeopleScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsNothing);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Can'), findsOneWidget);
  });
}
