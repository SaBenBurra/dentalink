import 'package:dentlink/core/error/app_failures.dart';
import 'package:dentlink/core/utils/supabase_error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  Future<Object> failureOf(Object error) async {
    try {
      await guardSupabase<void>(() async => throw error);
    } catch (e) {
      return e;
    }
    fail('hata bekleniyordu');
  }

  test('23505 ConflictFailure olur, kısıt adı korunur', () async {
    final f = await failureOf(const PostgrestException(
      message: 'duplicate key value violates unique constraint "users_username_key"',
      code: '23505',
    ));
    expect(f, isA<ConflictFailure>());
    expect((f as ConflictFailure).message, contains('username'));
  });

  test('StorageException durum koduna göre eşlenir', () async {
    expect(await failureOf(const StorageException('big', statusCode: '413')), isA<ValidationFailure>());
    expect(await failureOf(const StorageException('rls', statusCode: '403')), isA<PermissionDeniedFailure>());
    expect(await failureOf(const StorageException('gone', statusCode: '404')), isA<NotFoundFailure>());
    expect(await failureOf(const StorageException('jwt', statusCode: '401')), isA<AuthRequiredFailure>());
    expect(
      await failureOf(const StorageException('boom', statusCode: '500')),
      const ServerFailure(code: '500', message: 'boom'),
    );
  });
}
