import 'package:dentlink/data/repositories/supabase_follow_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../mocks/generate_mocks.mocks.dart';

void main() {
  test('get_mutual_followers: parametreler gider, kullanıcılar ve toplam okunur',
      () async {
    final client = MockSupabaseClient();
    final builder = MockPostgrestFilterBuilderMap();
    when(client.rpc<Map<String, dynamic>>('get_mutual_followers',
            params: anyNamed('params')))
        .thenAnswer((_) => builder);
    when(builder.then(any, onError: anyNamed('onError'))).thenAnswer((inv) {
      final callback =
          inv.positionalArguments[0] as dynamic Function(Map<String, dynamic>);
      return Future.value(callback({
        'total': 5,
        'users': [
          {
            'id': 'y',
            'full_name': 'Y',
            'username': 'y',
            'avatar_url': null,
            'title': 'dis_hekimi',
            'is_verified': false,
            'created_at': '2026-10-25T10:00:00+00:00',
          },
        ],
      }));
    });

    final mutual =
        await SupabaseFollowRepository(client: client).getMutualFollowers('p');

    expect(mutual.total, 5);
    expect(mutual.users.single.id, 'y');
    final params = verify(client.rpc<Map<String, dynamic>>(
      'get_mutual_followers',
      params: captureAnyNamed('params'),
    )).captured.single;
    expect(params, {'p_user_id': 'p', 'p_limit': 3});
  });
}
