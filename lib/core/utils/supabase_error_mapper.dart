import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../error/app_failures.dart';

/// Tüm Supabase repository'leri için ortak hata yakalama (guard) metodu.
Future<T> guardSupabase<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on AppFailure {
    rethrow;
  } on AuthRetryableFetchException catch (_, st) {
    Error.throwWithStackTrace(const NetworkFailure(), st);
  } on AuthException catch (_, st) {
    Error.throwWithStackTrace(const AuthRequiredFailure(), st);
  } on PostgrestException catch (e, st) {
    Error.throwWithStackTrace(_mapPostgrest(e), st);
  } on IOException catch (_, st) {
    Error.throwWithStackTrace(const NetworkFailure(), st);
  } on http.ClientException catch (_, st) {
    Error.throwWithStackTrace(const NetworkFailure(), st);
  }
}

AppFailure _mapPostgrest(PostgrestException e) {
  switch (e.code) {
    case '42501':
      return const PermissionDeniedFailure();
    case 'PGRST116': // single() returned 0 rows
    case 'P0002':    // rpc no_data_found
    case '23503':    // foreign key violation
      return const NotFoundFailure();
    case 'PGRST301':
      return const AuthRequiredFailure();
    case '23514': // check violation
      return ValidationFailure(e.message);
    // 23502 (not null) bir programlama/veri hatası olduğundan ServerFailure olarak döner.
    default:
      return ServerFailure(code: e.code, message: e.message);
  }
}
