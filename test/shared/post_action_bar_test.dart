import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'package:dentlink/shared/widgets/post_action_bar.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'beğeni ve yorum sayacı ikona eşit uzaklıkta; paylaş kaydetin solunda',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: PostActionBar(
              likeCount: 7,
              commentCount: 3,
              isLiked: false,
              isBookmarked: false,
              onLikeToggle: () {},
              onCommentTap: () {},
              onBookmarkToggle: () {},
            ),
          ),
        ),
      );

      double gap(IconData icon, String count) =>
          tester.getTopLeft(find.text(count)).dx -
          tester.getTopRight(find.byIcon(icon)).dx;

      expect(
        gap(Icons.favorite_border_rounded, '7'),
        gap(CupertinoIcons.chat_bubble, '3'),
      );
      expect(
        tester.getTopRight(find.byIcon(Icons.share_outlined)).dx,
        lessThan(
          tester.getTopLeft(find.byIcon(Icons.bookmark_border_rounded)).dx,
        ),
      );
      expect(find.byTooltip('Paylaş'), findsOneWidget);
    },
  );
  group('beğeni sayacı', () {
    Future<(List<int>, List<int>)> pump(WidgetTester tester, int count) async {
      final toggles = <int>[];
      final opens = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: PostActionBar(
              likeCount: count,
              commentCount: 3,
              isLiked: false,
              isBookmarked: false,
              onLikeToggle: () => toggles.add(1),
              onLikesTap: () => opens.add(1),
            ),
          ),
        ),
      );
      return (toggles, opens);
    }

    testWidgets('sayı beğenenleri açar, kalp beğenir; alan 48dp', (
      tester,
    ) async {
      final (toggles, opens) = await pump(tester, 7);

      await tester.tap(find.text('7'));
      expect((toggles.length, opens.length), (0, 1));

      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      expect((toggles.length, opens.length), (1, 1));

      expect(
        tester.getSize(find.byTooltip('Beğenenler')).width,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('kalbe basılı tutmak beğenmeden beğenenleri açar', (
      tester,
    ) async {
      final (toggles, opens) = await pump(tester, 7);

      await tester.longPress(find.byIcon(Icons.favorite_border_rounded));
      await tester.pump();

      expect((toggles.length, opens.length), (0, 1));
      expect(find.text('Beğen'), findsNothing); // ipucu açılmaz
    });

    testWidgets('beğeni yokken sayı beğenir, basılı tutmak liste açmaz', (
      tester,
    ) async {
      final (toggles, opens) = await pump(tester, 0);

      await tester.tap(find.text('0'));
      expect((toggles.length, opens.length), (1, 0));

      await tester.longPress(find.byIcon(Icons.favorite_border_rounded));
      await tester.pump();
      expect((toggles.length, opens.length), (1, 0));
    });
  });
}
