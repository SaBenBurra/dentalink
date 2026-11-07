import 'dart:io';

import 'package:dentigo/core/error/app_failures.dart';
import 'package:dentigo/data/repositories/supabase_post_repository.dart';
import 'package:dentigo/data/models/case_treatment.dart';
import 'package:dentigo/data/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../mocks/generate_mocks.mocks.dart';

void main() {
  group('video', videoTests);

  late MockSupabaseClient client;
  late MockStorageFileApi bucket;
  late SupabasePostRepository repository;

  setUp(() {
    client = MockSupabaseClient();
    final auth = MockGoTrueClient();
    final user = MockUser();
    final storage = MockSupabaseStorageClient();
    bucket = MockStorageFileApi();
    when(client.auth).thenReturn(auth);
    when(auth.currentUser).thenReturn(user);
    when(user.id).thenReturn('u1');
    when(client.storage).thenReturn(storage);
    when(storage.from('post-images')).thenReturn(bucket);
    when(bucket.remove(any)).thenAnswer((_) async => []);
    repository = SupabasePostRepository(client);
  });

  Future<void> createCase() => repository.createCase(
    title: 't',
    content: 'c',
    treatments: [CaseTreatment.listed(TreatmentType.kanalTedavisi)],
    media: [
      (image: File('a.JPG'), video: null),
      (image: File('b.png'), video: null),
    ],
    tags: const [],
  );

  test('create_post başarısız olursa yüklenen görseller silinir', () async {
    when(
      bucket.upload(any, any, fileOptions: anyNamed('fileOptions')),
    ).thenAnswer((_) async => 'ok');
    when(client.rpc('create_post', params: anyNamed('params'))).thenThrow(
      const PostgrestException(message: 'invalid image path', code: '22023'),
    );

    await expectLater(createCase(), throwsA(anything));

    final uploaded = verify(
      bucket.upload(captureAny, any, fileOptions: anyNamed('fileOptions')),
    ).captured.cast<String>();
    expect(uploaded, hasLength(2));
    expect(uploaded.every((p) => p.startsWith('u1/')), isTrue);
    expect(uploaded.first, endsWith('.jpg'));
    expect(verify(bucket.remove(captureAny)).captured.single, uploaded);
  });

  test(
    'yükleme yarıda kalırsa post oluşturulmaz, yüklenenler silinir',
    () async {
      var n = 0;
      when(
        bucket.upload(any, any, fileOptions: anyNamed('fileOptions')),
      ).thenAnswer((_) async {
        if (n++ == 1) throw const StorageException('network');
        return 'ok';
      });

      await expectLater(createCase(), throwsA(anything));

      verifyNever(client.rpc(any, params: anyNamed('params')));
      expect(verify(bucket.remove(captureAny)).captured.single, hasLength(2));
    },
  );

  test(
    'update_post: parametreler gönderilir, başkasının/olmayan post NotFound olur',
    () async {
      when(client.rpc('update_post', params: anyNamed('params'))).thenThrow(
        const PostgrestException(message: 'post not found', code: 'P0002'),
      );

      await expectLater(
        repository.updatePost(
          postId: 'p1',
          title: 't',
          content: 'c',
          treatments: [
            CaseTreatment.listed(TreatmentType.kanalTedavisi),
            const CaseTreatment(
              slug: 'zirkonya-inley',
              name: 'zirkonya-inley',
              branch: DentalBranch.protetikDisTedavisi,
            ),
          ],
          tags: const ['İmplant', 'implant'],
          mediaOrder: const ['m2', 'm1'],
        ),
        throwsA(isA<NotFoundFailure>()),
      );

      final params =
          verify(
                client.rpc('update_post', params: captureAnyNamed('params')),
              ).captured.single
              as Map<String, dynamic>;
      expect(params['p_post_id'], 'p1');
      // Listedekinin branşını sunucu bilir; kullanıcı tedavisinde branş gider.
      expect(params['p_treatments'], [
        {'name': 'kanal-tedavisi', 'slug': 'kanal-tedavisi'},
        {
          'name': 'zirkonya-inley',
          'slug': 'zirkonya-inley',
          'branch': 'protez_uzmani',
        },
      ]);
      expect(params['p_tags'], [
        {'name': 'İmplant', 'slug': 'implant'},
      ]);
      expect(params['p_media_order'], ['m2', 'm1']);
    },
  );
}

void videoTests() {
  late MockSupabaseClient client;
  late MockStorageFileApi images;
  late MockStorageFileApi videos;
  late SupabasePostRepository repository;

  setUp(() {
    client = MockSupabaseClient();
    final auth = MockGoTrueClient();
    final user = MockUser();
    final storage = MockSupabaseStorageClient();
    images = MockStorageFileApi();
    videos = MockStorageFileApi();
    when(client.auth).thenReturn(auth);
    when(auth.currentUser).thenReturn(user);
    when(user.id).thenReturn('u1');
    when(client.storage).thenReturn(storage);
    when(storage.from('post-images')).thenReturn(images);
    when(storage.from('post-videos')).thenReturn(videos);
    for (final b in [images, videos]) {
      when(b.remove(any)).thenAnswer((_) async => []);
      when(
        b.upload(any, any, fileOptions: anyNamed('fileOptions')),
      ).thenAnswer((_) async => 'ok');
    }
    repository = SupabasePostRepository(client);
  });

  test('forum: medya sırası korunur, video kapağı sırasında; '
      'hata olursa yüklenenler silinir', () async {
    when(client.rpc('create_post', params: anyNamed('params'))).thenThrow(
      const PostgrestException(message: 'invalid video path', code: '22023'),
    );

    await expectLater(
      repository.createQuestion(
        title: 't',
        content: 'c',
        media: [
          (image: File('a.webp'), video: null),
          (image: File('v.jpg'), video: File('v.mp4')),
          (image: File('b.webp'), video: null),
        ],
        tags: const [],
      ),
      throwsA(anything),
    );

    final videoPaths = verify(
      videos.upload(captureAny, any, fileOptions: anyNamed('fileOptions')),
    ).captured.cast<String>();
    final imagePaths = verify(
      images.upload(captureAny, any, fileOptions: anyNamed('fileOptions')),
    ).captured.cast<String>();
    expect(videoPaths.single, allOf(startsWith('u1/'), endsWith('.mp4')));
    expect(imagePaths.map((p) => p.split('.').last), ['webp', 'jpg', 'webp']);

    final params =
        verify(
              client.rpc('create_post', params: captureAnyNamed('params')),
            ).captured.single
            as Map<String, dynamic>;
    expect(params['p_type'], 'question');
    expect(params['p_image_paths'], imagePaths);
    expect(params['p_video_path'], videoPaths.single);
    expect(params['p_video_index'], 1);

    expect(verify(images.remove(captureAny)).captured.single, imagePaths);
    expect(verify(videos.remove(captureAny)).captured.single, videoPaths);
  });

  test('video yüklenemezse görsel yüklenmez, post oluşturulmaz', () async {
    when(
      videos.upload(any, any, fileOptions: anyNamed('fileOptions')),
    ).thenThrow(const StorageException('network'));

    await expectLater(
      repository.createCase(
        title: 't',
        content: 'c',
        treatments: [CaseTreatment.listed(TreatmentType.kanalTedavisi)],
        media: [
          (image: File('a.webp'), video: null),
          (image: File('v.jpg'), video: File('v.mp4')),
        ],
        tags: const [],
      ),
      throwsA(anything),
    );

    verifyNever(images.upload(any, any, fileOptions: anyNamed('fileOptions')));
    verifyNever(client.rpc(any, params: anyNamed('params')));
  });
}
