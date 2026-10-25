import 'package:dentlink/data/models/post_model.dart';
import 'package:dentlink/data/repositories/supabase_post_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../mocks/generate_mocks.mocks.dart';

/// SEC-9: post-images private; görseller tek istekte imzalanır.
void main() {
  test('getPostById görselleri sırayla imzalar, imzalanamayanı atlar', () async {
    final client = MockSupabaseClient();
    final auth = MockGoTrueClient();
    final user = MockUser();
    when(client.auth).thenReturn(auth);
    when(auth.currentUser).thenReturn(user);
    when(user.id).thenReturn('u1');

    final query = MockSupabaseQueryBuilder();
    final filter = MockPostgrestFilterBuilderList();
    final single = MockPostgrestTransformBuilderMap();
    when(client.from('posts')).thenAnswer((_) => query);
    when(query.select(any)).thenAnswer((_) => filter);
    when(filter.eq(any, any)).thenAnswer((_) => filter);
    when(filter.single()).thenAnswer((_) => single);
    final now = DateTime.now().toIso8601String();
    when(single.then(any, onError: anyNamed('onError'))).thenAnswer((inv) {
      final cb = inv.positionalArguments[0] as dynamic Function(Map<String, dynamic>);
      return Future.value(cb({
        'id': 'p1', 'user_id': 'a1', 'type': 'case', 'title': 't', 'content': 'c',
        'branch': 'endodonti', 'created_at': now, 'updated_at': now,
        'users': {'id': 'a1', 'full_name': 'A', 'username': 'a', 'created_at': now, 'updated_at': now},
        'post_images': [
          {'image_url': 'a1/2.webp', 'sort_order': 1},
          {'image_url': 'a1/gone.webp', 'sort_order': 2},
          {'image_url': 'a1/1.webp', 'sort_order': 0},
        ],
        'post_tags': [], 'likes': [], 'bookmarks': [],
      }));
    });

    final storage = MockSupabaseStorageClient();
    final bucket = MockStorageFileApi();
    when(client.storage).thenReturn(storage);
    when(storage.from('post-images')).thenReturn(bucket);
    when(bucket.createSignedUrlsResult(any, any)).thenAnswer((_) async => const [
          SignedUrlSuccess(path: 'a1/2.webp', signedUrl: 'https://s/2?token=x'),
          SignedUrlSuccess(path: 'a1/1.webp', signedUrl: 'https://s/1?token=x'),
          SignedUrlFailure(path: 'a1/gone.webp', error: 'not found'),
        ]);

    final post = await SupabasePostRepository(client).getPostById('p1') as CasePostModel;

    expect(post.imageUrls, ['https://s/1?token=x', 'https://s/2?token=x']);
    final call = verify(bucket.createSignedUrlsResult(captureAny, captureAny)).captured;
    expect(call[0], hasLength(3));
    expect(call[1], SupabasePostRepository.signedUrlTtl.inSeconds);
  });
}
