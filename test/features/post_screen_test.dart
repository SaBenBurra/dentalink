import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:dentigo/core/constants/app_dimensions.dart';
import 'package:dentigo/core/router/app_router.dart';
import 'package:dentigo/features/post/screens/post_screen.dart';
import 'package:dentigo/features/post/widgets/comments/post_comments.dart';
import 'package:dentigo/features/post/widgets/detail/detail_states.dart';
import 'package:dentigo/features/shell/main_shell.dart';
import 'package:dentigo/data/providers/repository_providers.dart';
import 'package:dentigo/providers/post_provider.dart';
import 'package:dentigo/shared/widgets/app_bottom_nav_bar.dart';
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

  testWidgets('yorum ikonuyla açılınca yorum başlığı ekranın tepesine gelir', (
    tester,
  ) async {
    await pumpDentigo(tester);
    final anchor = tester.element(find.text(seedCase.title));
    final repo = ProviderScope.containerOf(
      anchor,
    ).read(commentRepositoryProvider);
    for (var i = 0; i < 15; i++) {
      await repo.addComment(seedCase.id, 'eski yorum $i');
    }
    GoRouter.of(anchor).push('/post/${seedCase.id}?comments=1');
    await tester.pumpAndSettle();

    final appBar = find.descendant(
      of: find.byType(PostScreen),
      matching: find.byType(AppBar),
    );
    expect(
      tester.getRect(inPage(find.text('Tartışma'))).top,
      moreOrLessEquals(
        tester.getRect(appBar).bottom + AppDimensions.spacing40,
        epsilon: 1,
      ),
    );
  });

  testWidgets('gönderilen yorum giriş alanının üstüne kaydırılır', (
    tester,
  ) async {
    await pumpDentigo(tester);
    final anchor = tester.element(find.text(seedCase.title));
    // Liste ekrandan uzun olsun: yeni yorum açılışta görünmez.
    final repo = ProviderScope.containerOf(
      anchor,
    ).read(commentRepositoryProvider);
    for (var i = 0; i < 15; i++) {
      await repo.addComment(seedCase.id, 'eski yorum $i');
    }
    GoRouter.of(anchor).push('/post/${seedCase.id}');
    await tester.pumpAndSettle();

    final input = inPage(find.byType(TextField)).last;
    await tester.enterText(input, 'yeni yorum');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();

    final sent = inPage(find.text('yeni yorum'));
    expect(sent, findsOneWidget);
    final rect = tester.getRect(sent);
    expect(rect.top, greaterThan(0));
    expect(rect.bottom, lessThanOrEqualTo(tester.getRect(input).top));
  });

  testWidgets(
    'yorum satırı başlığın altında; tam görününce barın üstüne sabitlenir',
    (tester) async {
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpDentigo(tester);
      final anchor = tester.element(find.text(seedCase.title));
      final container = ProviderScope.containerOf(anchor);
      final repo = container.read(commentRepositoryProvider);
      for (var i = 0; i < 15; i++) {
        await repo.addComment(seedCase.id, 'eski yorum $i');
      }
      pushDetailOn(GoRouter.of(anchor), '/post/${seedCase.id}');
      await tester.pumpAndSettle();
      final bar = container.read(bottomBarControllerProvider);
      final barTop = tester.getRect(find.byType(AppBottomNavBar)).top;
      final input = find
          .descendant(
            of: find.byType(PostComments, skipOffstage: false),
            matching: find.byType(TextField, skipOffstage: false),
            skipOffstage: false,
          )
          .last;
      final list = inPage(find.byType(CustomScrollView));

      // Açılışta doğal yerinde: başlığın hemen altında, ekranın dışında.
      final title = find.descendant(
        of: find.byType(PostComments, skipOffstage: false),
        matching: find.text('Tartışma', skipOffstage: false),
        skipOffstage: false,
      );
      expect(
        tester.getRect(input).top,
        greaterThan(tester.getRect(title).bottom),
      );
      expect(tester.getRect(input).bottom, greaterThan(barTop));

      // İçerikle birlikte yukarı gelir, barın üstüne değince orada kalır;
      // geri sıçrama ya da kaybolma yok.
      var last = tester.getRect(input).top;
      for (var i = 0; i < 80; i++) {
        await tester.drag(list, const Offset(0, -20));
        await tester.pump();
        final top = tester.getRect(input).top;
        expect(tester.getRect(input).bottom, greaterThan(barTop - 16));
        expect(top, lessThanOrEqualTo(last));
        expect(bar.isVisible, isTrue);
        last = top;
      }
      await tester.pumpAndSettle();
      final stuck = tester.getRect(input);
      expect(stuck.bottom, inInclusiveRange(barTop - 16, barTop));
      // Son yorum sabit satırın arkasında kalmaz.
      expect(
        tester.getRect(inPage(find.text('eski yorum 14'))).bottom,
        lessThanOrEqualTo(stuck.top),
      );

      // Biraz geri kaydırınca da sabit kalır; başlığa kadar dönünce yerine iner.
      await tester.drag(list, const Offset(0, 200));
      await tester.pumpAndSettle();
      expect(tester.getRect(input), stuck);
      await tester.drag(list, const Offset(0, 5000));
      await tester.pumpAndSettle();
      expect(tester.getRect(input).bottom, greaterThan(barTop));
    },
  );
}
