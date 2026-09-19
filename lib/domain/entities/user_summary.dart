import 'package:equatable/equatable.dart';
import '../enums/enums.dart';

class UserSummary extends Equatable {
  final String id;
  final String fullName;
  final String username;
  final String? avatarUrl;
  final UserTitle title;
  final bool isVerified;
  final DateTime createdAt;

  const UserSummary({
    required this.id,
    required this.fullName,
    required this.username,
    this.avatarUrl,
    required this.title,
    this.isVerified = false,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        fullName,
        username,
        avatarUrl,
        title,
        isVerified,
        createdAt,
      ];
}
