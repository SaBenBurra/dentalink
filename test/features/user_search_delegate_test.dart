import 'package:dentlink/data/models/user_model.dart';
import 'package:dentlink/data/providers/repository_providers.dart';
import 'package:dentlink/data/repositories/user_repository.dart';
import 'package:dentlink/features/messaging/widgets/user_search_delegate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeUserRepo implements UserRepository {
  final queries = <String>[];

  @override
  Future<List<UserModel>> searchUsers(String query) async {
    queries.add(query);
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('hızlı yazınca yalnızca son sorgu için istek gider (BUG-22)',
      (tester) async {
    final repo = _FakeUserRepo();
    await tester.pumpWidget(ProviderScope(
      overrides: [userRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        home: Consumer(
          builder: (context, ref, _) => Scaffold(
            body: TextButton(
              onPressed: () =>
                  showSearch(context: context, delegate: UserSearchDelegate(ref)),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    for (final q in ['ay', 'ayş', 'ayşe']) {
      await tester.enterText(find.byType(TextField), q);
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle(const Duration(milliseconds: 400));

    expect(repo.queries, ['ayşe']);
  });
}
