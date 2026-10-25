import 'dart:async';

import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'package:dentlink/data/models/enums.dart';
import 'package:dentlink/data/models/post_model.dart';
import 'package:dentlink/data/models/user_model.dart';
import 'package:dentlink/data/providers/repository_providers.dart';
import 'package:dentlink/data/repositories/moderation_repository.dart';
import 'package:dentlink/shared/utils/moderation_actions.dart';
import 'package:dentlink/shared/widgets/post_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repo implements ModerationRepository {
  final reports = <ReportReason>[];
  final gate = Completer<void>();

  @override
  Future<void> report(ReportTarget target, String targetId, ReportReason reason,
      {String? note}) async {
    reports.add(reason);
    await gate.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _app(Widget child, {List<Override> overrides = const []}) => ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );

void main() {
  final post = CasePostModel(
    id: 'p1',
    userId: 'u1',
    title: 'Vaka',
    content: 'İçerik',
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    author: UserModel(
      id: 'u1',
      fullName: 'Ayşe',
      username: 'ayse',
      title: UserTitle.disHekimi,
      createdAt: DateTime(2024),
    ),
  );

  for (final isOwner in [true, false]) {
    testWidgets('post menüsü: sahibine Düzenle/Sil, başkasına Raporla/Engelle (isOwner: $isOwner)',
        (tester) async {
      await tester.pumpWidget(_app(PostHeader(
        post: post,
        badge: const SizedBox(),
        subtitle: '',
        isOwner: isOwner,
        onMenuSelected: (_) {},
      )));
      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();

      expect(find.text('Düzenle'), isOwner ? findsOneWidget : findsNothing);
      expect(find.text('Raporla'), isOwner ? findsNothing : findsOneWidget);
      expect(find.text('Engelle'), isOwner ? findsNothing : findsOneWidget);
    });
  }

  testWidgets('rapor: sebep seçilmeden gönderilemez, gönderirken buton kilitli',
      (tester) async {
    final repo = _Repo();
    await tester.pumpWidget(_app(
      const ReportSheet(target: ReportTarget.post, targetId: 'p1'),
      overrides: [moderationRepositoryProvider.overrideWithValue(repo)],
    ));

    FilledButton submit() => tester.widget(find.byType(FilledButton));
    expect(submit().onPressed, isNull);

    await tester.tap(find.text('Spam veya reklam'));
    await tester.pump();
    expect(submit().onPressed, isNotNull);

    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(submit().onPressed, isNull);
    await tester.tap(find.byType(FilledButton), warnIfMissed: false);
    expect(repo.reports, [ReportReason.spam]);

    repo.gate.complete();
    await tester.pumpAndSettle();
  });
}
