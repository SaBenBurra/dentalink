import 'dart:io';

import 'package:dentlink/data/repositories/supabase_post_repository.dart';
import 'package:dentlink/domain/enums/enums.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../mocks/generate_mocks.mocks.dart';

void main() {
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
        branch: DentalBranch.endodonti,
        imageFiles: [File('a.JPG'), File('b.png')],
        tags: const [],
      );

  test('create_post başarısız olursa yüklenen görseller silinir', () async {
    when(bucket.upload(any, any, fileOptions: anyNamed('fileOptions')))
        .thenAnswer((_) async => 'ok');
    when(client.rpc('create_post', params: anyNamed('params')))
        .thenThrow(const PostgrestException(message: 'invalid image path', code: '22023'));

    await expectLater(createCase(), throwsA(anything));

    final uploaded = verify(bucket.upload(captureAny, any, fileOptions: anyNamed('fileOptions')))
        .captured
        .cast<String>();
    expect(uploaded, hasLength(2));
    expect(uploaded.every((p) => p.startsWith('u1/')), isTrue);
    expect(uploaded.first, endsWith('.jpg'));
    expect(verify(bucket.remove(captureAny)).captured.single, uploaded);
  });

  test('yükleme yarıda kalırsa post oluşturulmaz, yüklenenler silinir', () async {
    var n = 0;
    when(bucket.upload(any, any, fileOptions: anyNamed('fileOptions'))).thenAnswer((_) async {
      if (n++ == 1) throw const StorageException('network');
      return 'ok';
    });

    await expectLater(createCase(), throwsA(anything));

    verifyNever(client.rpc(any, params: anyNamed('params')));
    expect(verify(bucket.remove(captureAny)).captured.single, hasLength(2));
  });
}
