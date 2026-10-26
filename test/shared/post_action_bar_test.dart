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
}
