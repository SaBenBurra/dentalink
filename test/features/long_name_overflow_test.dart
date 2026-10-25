import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'package:dentlink/data/models/comment_model.dart';
import 'package:dentlink/data/models/user_model.dart';
import 'package:dentlink/data/models/enums.dart';
import 'package:dentlink/features/post/widgets/comments/comment_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final isCase in [true, false]) {
    testWidgets('uzun isim yorum kartında taşmaz (UX-9, isCase: $isCase)',
        (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final comment = CommentModel(
        id: 'c1',
        postId: 'p1',
        userId: 'u1',
        content: 'Yorum',
        isBestAnswer: !isCase,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
        author: UserModel(
          id: 'u1',
          fullName: 'Ayşe ' * 15,
          username: 'ayse',
          title: UserTitle.restoratifDisTedavisi,
          createdAt: DateTime(2024),
        ),
      );
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: CommentCard(
                comment: comment,
                postId: 'p1',
                isPostOwner: false,
                isCase: isCase,
              ),
            ),
          ),
        ),
      ));

      expect(tester.takeException(), isNull);
    });
  }
}
