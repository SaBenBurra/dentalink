import 'package:dentigo/data/models/enums.dart';
import 'package:dentigo/data/providers/repository_providers.dart';
import 'package:dentigo/features/messaging/screens/chat_screen.dart';
import 'package:dentigo/features/post/screens/post_screen.dart';
import 'package:dentigo/features/post/widgets/comments/post_comments.dart';
import 'package:dentigo/providers/feed_provider.dart';
import 'package:dentigo/shared/widgets/like_button.dart';
import 'package:dentigo/shared/widgets/listing_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../integration_test/app_flow.dart';
import '../../integration_test/fake_repositories.dart';

void main() {
  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));

  Future<void> openListingsTab(WidgetTester tester) async {
    await pumpDentigo(tester);
    await tester.tap(find.text('Ticaret'));
    await tester.pumpAndSettle();
  }

  Finder inPage(Finder f) =>
      find.descendant(of: find.byType(PostScreen), matching: f);

  testWidgets('Ticaret sekmesi ilanı fiyat, durum ve şehirle gösterir; '
      'beğeni yok', (tester) async {
    await openListingsTab(tester);
    expect(find.text(seedListing.title), findsOneWidget);
    expect(find.text('2.500 ₺'), findsOneWidget);
    expect(find.text('Az kullanılmış'), findsOneWidget);
    expect(find.text('İzmir'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ListingCard),
        matching: find.byType(LikeButton),
      ),
      findsNothing,
    );
  });

  testWidgets('kategori çipi listeyi o kategoriyle yeniden çeker', (
    tester,
  ) async {
    await openListingsTab(tester);
    final repo = container(tester).read(listingRepositoryProvider) as dynamic;
    await tester.tap(find.widgetWithText(ChoiceChip, 'El aletleri'));
    await tester.pumpAndSettle();
    expect(repo.listingRequests, [null, ListingCategory.handInstruments]);
    expect(find.text(seedListing.title), findsNothing);
  });

  testWidgets('ilan sayfasında yorum yok; "Satıcıya yaz" sohbeti hazır '
      'mesajla açar', (tester) async {
    await openListingsTab(tester);
    await tester.tap(find.text(seedListing.title));
    await tester.pumpAndSettle();
    expect(find.byType(PostScreen), findsOneWidget);
    expect(inPage(find.byType(PostComments)), findsNothing);
    expect(inPage(find.text('Satıldı olarak işaretle')), findsNothing);

    await tester.tap(find.text('Satıcıya yaz'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatScreen), findsOneWidget);
    expect(
      find.text('Merhaba, "${seedListing.title}" ilanınız hakkında yazıyorum.'),
      findsOneWidget,
    );
  });

  testWidgets('sahibi ilanı satıldı yapınca "Satıldı" görünür, Ticaret '
      'listesinden düşer', (tester) async {
    await pumpDentigo(tester);
    final c = container(tester);
    final mine = await c
        .read(listingRepositoryProvider)
        .createListing(
          title: 'Kendi ilanım',
          content: 'açıklama',
          images: const [],
          category: ListingCategory.books,
          condition: ItemCondition.used,
          city: 'Ankara',
        );
    c.listen(listingFeedProvider, (_, _) {});
    expect(
      (await c.read(listingFeedProvider.future)).map((p) => p.id),
      contains(mine.id),
    );

    GoRouter.of(
      tester.element(find.text(seedCase.title)),
    ).push('/post/${mine.id}');
    await tester.pumpAndSettle();
    expect(inPage(find.text('Fiyat sorunuz')), findsOneWidget);
    expect(find.text('Satıcıya yaz'), findsNothing);

    await tester.tap(find.text('Satıldı olarak işaretle'));
    await tester.pumpAndSettle();
    expect(inPage(find.text('Satıldı')), findsOneWidget);
    expect(find.text('Yeniden satışa çıkar'), findsOneWidget);
    expect(
      c.read(listingFeedProvider).value!.map((p) => p.id),
      isNot(contains(mine.id)),
    );
  });

  test('copyWith fiyatı null\'a çekebilir', () {
    final noPrice = seedListing.copyWith(price: () => null);
    expect(noPrice.price, isNull);
    expect(seedListing.copyWith(isSold: true).price, 2500);
  });

  test('bilinmeyen kategori ve durum güvenli varsayılana düşer', () {
    expect(ListingCategory.fromDbValue('x'), ListingCategory.other);
    expect(ItemCondition.fromDbValue(null), ItemCondition.used);
    expect(PostType.fromDbValue('listing'), PostType.listing);
    expect(PostType.listing.allowsSocial, isFalse);
  });
}

