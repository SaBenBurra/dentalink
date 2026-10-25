import 'package:dentlink/core/error/app_failures.dart';
import 'package:dentlink/data/models/enums.dart';
import 'package:dentlink/data/repositories/supabase_moderation_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../mocks/generate_mocks.mocks.dart';

void main() {
  late MockSupabaseClient client;
  late MockGoTrueClient auth;
  late MockSupabaseQueryBuilder query;
  late MockPostgrestFilterBuilderList insert;
  late SupabaseModerationRepository repo;

  setUp(() {
    client = MockSupabaseClient();
    auth = MockGoTrueClient();
    query = MockSupabaseQueryBuilder();
    insert = MockPostgrestFilterBuilderList();
    when(client.auth).thenReturn(auth);
    final user = MockUser();
    when(user.id).thenReturn('me');
    when(auth.currentUser).thenReturn(user);
    when(client.from(any)).thenAnswer((_) => query);
    when(query.insert(any, defaultToNull: anyNamed('defaultToNull')))
        .thenAnswer((_) => insert);
    repo = SupabaseModerationRepository(client: client);
  });

  void insertResult({PostgrestException? error}) {
    // await, then(onValue, onError) ile bağlanır; sonucu ikisine de ilet.
    when(insert.then(any, onError: anyNamed('onError'))).thenAnswer((inv) {
      final result = error == null
          ? Future<List<Map<String, dynamic>>>.value([])
          : Future<List<Map<String, dynamic>>>.error(error);
      return result.then(
        inv.positionalArguments[0] as dynamic Function(List<Map<String, dynamic>>),
        onError: inv.namedArguments[#onError] as Function?,
      );
    });
  }

  test('report: DB değerleriyle reports satırı ekler, boş not gönderilmez', () async {
    insertResult();
    await repo.report(ReportTarget.post, 'p1', ReportReason.patientPrivacy, note: '  ');

    verify(client.from('reports')).called(1);
    final row = verify(query.insert(captureAny, defaultToNull: anyNamed('defaultToNull')))
        .captured
        .single;
    expect(row, {
      'reporter_id': 'me',
      'target_type': 'post',
      'target_id': 'p1',
      'reason': 'patient_privacy',
    });
  });

  test('aynı hedefi ikinci kez raporlamak (23505) hata vermez', () async {
    insertResult(error: const PostgrestException(message: 'dup', code: '23505'));
    await repo.report(ReportTarget.user, 'u1', ReportReason.spam);
  });

  test('blockUser: diğer DB hataları AppFailure olur', () async {
    insertResult(error: const PostgrestException(message: 'rls', code: '42501'));
    await expectLater(repo.blockUser('u1'), throwsA(isA<PermissionDeniedFailure>()));
    final row = verify(query.insert(captureAny, defaultToNull: anyNamed('defaultToNull')))
        .captured
        .single;
    expect(row, {'blocker_id': 'me', 'blocked_id': 'u1'});
  });

  test('oturum yoksa istek atılmaz', () async {
    when(auth.currentUser).thenReturn(null);
    await expectLater(repo.blockUser('u1'), throwsA(isA<AuthRequiredFailure>()));
    verifyNever(client.from(any));
  });
}
