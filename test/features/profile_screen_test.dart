import 'package:dentigo/core/l10n/generated/app_localizations.dart';
import 'package:dentigo/data/models/enums.dart';
import 'package:dentigo/data/models/user_model.dart';
import 'package:dentigo/features/profile/widgets/profile_header.dart';
import 'package:dentigo/providers/user_provider.dart';
import 'package:dentigo/providers/search_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentigo/features/profile/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../integration_test/app_flow.dart';
import '../../integration_test/fake_repositories.dart';

void main() {
  testWidgets('kendi profili: sayaçlar, düzenle, segmentle sekme geçişi', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpDentigo(tester);
    await tester.tap(find.text('Profil').last);
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.textContaining('Gönderi', findRichText: true), findsOneWidget);
    expect(find.text('Profili Düzenle'), findsOneWidget);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    // Segment sekme rayı TabBarView'u sürer.
    final tabs = DefaultTabController.of(
      tester.element(find.byType(TabBarView)),
    );
    expect(tabs.index, 0);
    await tester.tap(find.text('Forum'));
    await tester.pumpAndSettle();
    expect(tabs.index, 2);
    handle.dispose();
  });

  testWidgets('başka profil: ad, mesaj ve geri', (tester) async {
    await pumpDentigo(tester);
    GoRouter.of(
      tester.element(find.text(seedCase.title)),
    ).push('/profile/${otherUser.id}');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(otherUser.fullName), findsWidgets);
    expect(find.text('Mesaj'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsNothing);
  });

  testWidgets('profil başlığı 320dp ekranda uzun alanlarla taşmaz', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final user = UserModel(
      id: otherUser.id,
      fullName: 'Ayşe ' * 15,
      username: 'ayse',
      title: UserTitle.restoratifDisTedavisi,
      bio: 'Biyografi ' * 20,
      university: 'Hacettepe Üniversitesi Diş Hekimliği Fakültesi',
      city: 'İstanbul',
      workplace: 'Çok Uzun İsimli Ağız ve Diş Sağlığı Polikliniği',
      experienceYears: 12,
      followersCount: 123456,
      followingCount: 9876543,
      postsCount: 42,
      isVerified: true,
      createdAt: DateTime(2024),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: fakeRepositoryOverrides(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(child: ProfileHeader(user: user)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('123.5K', findRichText: true), findsOneWidget);
  });

  testWidgets('ortak takipçiler: ilk iki ad ve kalan sayı', (tester) async {
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
          ...fakeRepositoryOverrides(),
          mutualFollowersProvider(otherUser.id).overrideWith(
            (ref) async => (users: [u('Ali'), u('Veli'), u('Can')], total: 7),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: ProfileHeader(user: otherUser)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ali, Veli ve 5 kişi daha takip ediyor'), findsOneWidget);
  });

  testWidgets('ilk 50 popüler kişideyse profilde sırası görünür', (
    tester,
  ) async {
    Future<void> pump(int? rank) async {
      await tester.pumpWidget(
        ProviderScope(
          key: ValueKey(rank),
          overrides: [
            ...fakeRepositoryOverrides(),
            popularRankProvider(otherUser.id).overrideWith((ref) async => rank),
          ],
          child: MaterialApp(
            locale: const Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: ProfileHeader(user: otherUser)),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pump(7);
    expect(find.text('Popüler #7'), findsOneWidget);

    await pump(null);
    expect(find.textContaining('Popüler #'), findsNothing);
  });
}
