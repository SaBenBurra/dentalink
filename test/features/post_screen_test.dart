import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart' show AppBar;
import 'package:dentlink/features/post/screens/post_screen.dart';
import 'package:dentlink/features/post/widgets/comments/comments_sheet.dart';
import 'package:dentlink/providers/post_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../integration_test/app_flow.dart';
import '../../integration_test/fake_repositories.dart';

void main() {
  Future<void> openPost(WidgetTester tester) async {
    await pumpDentLink(tester);
    GoRouter.of(
      tester.element(find.text(seedCase.title)),
    ).push('/post/${seedCase.id}');
    await tester.pumpAndSettle();
  }

  testWidgets('/post/:id postu kartıyla gösterir, yorumlar pencerede açılır', (
    tester,
  ) async {
    await openPost(tester);
    final page = find.byType(PostScreen);
    expect(page, findsOneWidget);
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Vaka')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: page, matching: find.text(seedCase.title)),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(
        of: page,
        matching: find.byIcon(CupertinoIcons.chat_bubble),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CommentsSheet), findsOneWidget);
  });

  testWidgets('?comments=1 ile yorumlar penceresi kendiliğinden açılır', (
    tester,
  ) async {
    await pumpDentLink(tester);
    GoRouter.of(
      tester.element(find.text(seedCase.title)),
    ).push('/post/${seedCase.id}?comments=1');
    await tester.pumpAndSettle();
    expect(find.byType(PostScreen), findsOneWidget);
    expect(find.byType(CommentsSheet), findsOneWidget);
  });

  testWidgets('parametresiz açılışta yorumlar kapalı', (tester) async {
    await openPost(tester);
    expect(find.byType(CommentsSheet), findsNothing);
  });

  testWidgets('açık post silinince sayfa kapanır', (tester) async {
    await openPost(tester);
    ProviderScope.containerOf(
      tester.element(find.byType(PostScreen)),
    ).read(postDetailProvider(seedCase.id).notifier).markDeleted();
    await tester.pumpAndSettle();
    expect(find.byType(PostScreen), findsNothing);
  });
}
