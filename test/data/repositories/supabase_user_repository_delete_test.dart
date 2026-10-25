import 'package:dentlink/core/error/app_failures.dart';
import 'package:dentlink/data/repositories/supabase_user_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../mocks/generate_mocks.mocks.dart';

FileObject _file(String name) => FileObject.fromJson({'name': name});

void main() {
  late MockSupabaseClient client;
  late MockStorageFileApi avatars;
  late MockStorageFileApi postImages;
  late SupabaseUserRepository repo;

  setUp(() {
    client = MockSupabaseClient();
    final auth = MockGoTrueClient();
    final user = MockUser();
    final storage = MockSupabaseStorageClient();
    avatars = MockStorageFileApi();
    postImages = MockStorageFileApi();
    when(user.id).thenReturn('me');
    when(auth.currentUser).thenReturn(user);
    when(client.auth).thenReturn(auth);
    when(client.storage).thenReturn(storage);
    when(storage.from('avatars')).thenReturn(avatars);
    when(storage.from('post-images')).thenReturn(postImages);
    // RPC'ye ulaşıldığını bu hatayla anlarız (builder mock'u gerekmez).
    when(client.rpc('delete_account')).thenThrow(StateError('rpc reached'));
    repo = SupabaseUserRepository(client: client);
  });

  test('önce iki klasör sayfa sayfa boşaltılır, sonra RPC çağrılır', () async {
    final avatarPages = [[_file('a.webp')], <FileObject>[]];
    when(avatars.list(path: 'me', searchOptions: anyNamed('searchOptions')))
        .thenAnswer((_) async => avatarPages.removeAt(0));
    final postPages = [[_file('1.webp'), _file('2.webp')], [_file('3.webp')], <FileObject>[]];
    when(postImages.list(path: 'me', searchOptions: anyNamed('searchOptions')))
        .thenAnswer((_) async => postPages.removeAt(0));
    when(avatars.remove(any)).thenAnswer((inv) async =>
        [for (final p in inv.positionalArguments[0] as List<String>) _file(p)]);
    when(postImages.remove(any)).thenAnswer((inv) async =>
        [for (final p in inv.positionalArguments[0] as List<String>) _file(p)]);

    await expectLater(repo.deleteAccount(), throwsA(isA<StateError>()));

    verify(avatars.remove(['me/a.webp'])).called(1);
    verify(postImages.remove(['me/1.webp', 'me/2.webp'])).called(1);
    verify(postImages.remove(['me/3.webp'])).called(1);
  });

  test('dosyalar silinemezse hesaba dokunulmaz', () async {
    when(avatars.list(path: 'me', searchOptions: anyNamed('searchOptions')))
        .thenAnswer((_) async => [_file('a.webp')]);
    when(avatars.remove(any)).thenAnswer((_) async => []);

    await expectLater(repo.deleteAccount(), throwsA(isA<ServerFailure>()));
    verifyNever(client.rpc('delete_account'));
  });
}
