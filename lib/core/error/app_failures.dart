import 'package:equatable/equatable.dart';

sealed class AppFailure extends Equatable implements Exception {
  const AppFailure();

  @override
  List<Object?> get props => [];
}

final class AuthRequiredFailure extends AppFailure {
  const AuthRequiredFailure();
}

final class PermissionDeniedFailure extends AppFailure {
  const PermissionDeniedFailure();
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure();
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure();
}

final class ValidationFailure extends AppFailure {
  final String message;
  const ValidationFailure(this.message);

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'ValidationFailure(message: $message)';
}

final class ServerFailure extends AppFailure {
  final String? code;
  final String? message;
  
  const ServerFailure({this.code, this.message});

  @override
  List<Object?> get props => [code, message];

  @override
  String toString() => 'ServerFailure(code: $code, message: $message)';
}
