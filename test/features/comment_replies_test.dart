import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'package:dentlink/core/utils/paging.dart';
import 'package:dentlink/data/models/comment_model.dart';
import 'package:dentlink/data/models/enums.dart';
import 'package:dentlink/data/models/post_model.dart';
import 'package:dentlink/data/models/user_model.dart';
import 'package:dentlink/data/providers/repository_providers.dart';
import 'package:dentlink/data/repositories/comment_repository.dart';
import 'package:dentlink/features/post/widgets/comments/comment_card.dart';
import 'package:dentlink/features/post/widgets/comments/comments_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _author = UserModel(
  id: 'u2',
  fullName: 'Bora',
  username: 'bora',
  title: UserTitle.disHekimi,
  createdAt: DateTime(2024),
);

CommentModel _c(String id, String content, {String? parentId, int replies = 0}) =>
    CommentModel(
      id: id,
      postId: 'p1',
      userId: 'u2',
      parentId: parentId,
      replyCount: replies,
      content: content,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
      author: _author,
    );

/// Bellekte ağaç: c1 → r1; yeni yanıtlar ebeveynin listesine eklenir.
class _Repo implements CommentRepository {
  final replies = <String, List<CommentModel>>{
    'c1': [_c('r1', 'first reply', parentId: 'c1')],
  };
  final added = <String?>[];

  @override
  Future<PageResult<CommentModel>> getComments(String postId, {PageCursor? after}) async =>
      (items: [_c('c1', 'top comment', replies: 1)], next: null);

  @override
  Future<PageResult<CommentModel>> getReplies(String parentId, {PageCursor? after}) async =>
      (items: [...?replies[parentId]], next: null);

  @override
  Future<CommentModel> addComment(String postId, String content, {String? parentId}) async {
    added.add(parentId);
    final c = _c('n${added.length}', content, parentId: parentId);
    if (parentId != null) (replies[parentId] ??= []).add(c);
    return c;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('yanıtlar açılır, yanıta yanıt yazılır ve altında görünür', (tester) async {
    final repo = _Repo();
    final post = QuestionPostModel(
      id: 'p1',
      userId: 'u1',
      title: 't',
      content: 'c',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
      author: _author,
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [commentRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: CommentsSheet(post: post)),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('first reply'), findsNothing);
    await tester.tap(find.text('Show 1 reply'));
    await tester.pumpAndSettle();
    expect(find.text('first reply'), findsOneWidget);

    // r1'e (2. seviye) yanıt ver.
    final r1Card = find.widgetWithText(CommentCard, 'first reply');
    await tester.tap(find.descendant(of: r1Card, matching: find.text('Reply')));
    await tester.pumpAndSettle();
    expect(find.text('Replying to Bora'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'deep reply');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(repo.added, ['r1']);
    expect(find.text('Replying to Bora'), findsNothing);
    expect(find.text('deep reply'), findsOneWidget);
    // r1'in sayacı arttı ve yanıtları açıldı.
    expect(
      find.descendant(of: find.widgetWithText(CommentCard, 'first reply'), matching: find.text('Hide replies')),
      findsOneWidget,
    );
  });
}
