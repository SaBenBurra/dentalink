import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:dentigo/features/post/screens/post_screen.dart';
import 'package:dentigo/features/post/widgets/comments/post_comments.dart';
import 'package:dentigo/features/post/widgets/detail/detail_states.dart';
import 'package:dentigo/data/providers/repository_providers.dart';
import 'package:dentigo/providers/post_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../integration_test/app_flow.dart';
import '../../integration_test/fake_repositories.dart';

void main() {
  Future<void> openPost(WidgetTester tester) async {
    await pumpDentigo(tester);
    GoRouter.of(
      tester.element(find.text(seedCase.title)),
    ).push('/post/${seedCase.id}');
    await tester.pumpAndSettle();
  }

  Finder inPage(Finder f) =>
      find.descendant(of: find.byType(PostScreen), matching: f);

  TextField commentField(WidgetTester tester) =>
      tester.widget<TextField>(inPage(find.byType(TextField)).last);

  testWidgets('/post/:id postu kartıyla ve altında yorumlarıyla gösterir', (
    tester,
  ) async {
    await openPost(tester);
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Vaka')),
      findsOneWidget,
    );
    expect(inPage(find.text(seedCase.title)), findsOneWidget);
    expect(inPage(find.byType(PostComments)), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('feed kartına dokununca sayfa yükleniyor ekranı olmadan açılır', (
    tester,
  ) async {
    await pumpDentigo(tester);
    await tester.tap(find.text(seedCase.title));
    await tester.pump();
    await tester.pump(); // geçiş başladı
    expect(find.byType(PostDetailLoading), findsNothing);
    expect(inPage(find.text(seedCase.title)), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byType(PostScreen), findsOneWidget);
  });

  testWidgets('feed yorum ikonu sayfayı açar, klavye açılmaz', (tester) async {
    await pumpDentigo(tester);
    await tester.tap(find.byIcon(CupertinoIcons.chat_bubble).first);
    await tester.pumpAndSettle();
    expect(find.byType(PostScreen), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(commentField(tester).focusNode!.hasFocus, isFalse);
  });

  testWidgets('sayfadaki yorum ikonu giriş alanına odaklanır', (tester) async {
    await openPost(tester);
    await tester.tap(inPage(find.byIcon(CupertinoIcons.chat_bubble)));
    await tester.pumpAndSettle();
    expect(commentField(tester).focusNode!.hasFocus, isTrue);
  });

  testWidgets('yarım yorum sayfadan çıkıp dönünce korunur', (tester) async {
    await openPost(tester);
    await tester.enterText(inPage(find.byType(TextField)).last, 'yarım');
    GoRouter.of(tester.element(find.byType(PostScreen))).pop();
    await tester.pumpAndSettle();
    GoRouter.of(
      tester.element(find.text(seedCase.title)),
    ).push('/post/${seedCase.id}');
    await tester.pumpAndSettle();
    expect(commentField(tester).controller!.text, 'yarım');
  });

  testWidgets('açık post silinince sayfa kapanır', (tester) async {
    await openPost(tester);
    ProviderScope.containerOf(
      tester.element(find.byType(PostScreen)),
    ).read(postDetailProvider(seedCase.id).notifier).markDeleted();
    await tester.pumpAndSettle();
    expect(find.byType(PostScreen), findsNothing);
  });

  testWidgets('olmayan post: "mevcut değil" ve geri butonu', (tester) async {
    await pumpDentigo(tester);
    GoRouter.of(tester.element(find.text(seedCase.title))).push('/post/yok');
    await tester.pumpAndSettle();
    expect(find.text('Bu gönderi artık mevcut değil.'), findsOneWidget);
    expect(find.text('Geri Dön'), findsOneWidget);
  });

  testWidgets('forum postu da aynı sayfada, yorumlar kartın altında', (
    tester,
  ) async {
    await pumpDentigo(tester);
    final anchor = tester.element(find.text(seedCase.title));
    final post = await ProviderScope.containerOf(anchor)
        .read(createPostRepositoryProvider)
        .createQuestion(title: 'Forum başlığı', content: 'içerik', tags: []);
    GoRouter.of(anchor).push('/post/${post.id}?comments=1');
    await tester.pumpAndSettle();

    final inline = inPage(find.byType(PostComments));
    expect(inline, findsOneWidget);
    expect(
      find.descendant(of: inline, matching: find.text('Forum başlığı')),
      findsOneWidget,
    );
    expect(find.byType(BottomSheet), findsNothing);
  });
}
