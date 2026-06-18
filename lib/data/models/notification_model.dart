import 'enums.dart';
import 'user_model.dart';

/// Bildirim modeli — Supabase `notifications` tablosuyla eşleşir.
class NotificationModel {
  final String id;
  final NotificationType type;

  /// Bildirimi tetikleyen kullanıcı.
  final UserModel actor;

  /// İlgili gönderi ID'si (varsa).
  final String? postId;

  /// İlgili yorum ID'si (varsa).
  final String? commentId;

  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.actor,
    this.postId,
    this.commentId,
    this.isRead = false,
    required this.createdAt,
  });

  NotificationModel copyWith({
    String? id,
    NotificationType? type,
    UserModel? actor,
    String? postId,
    String? commentId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      actor: actor ?? this.actor,
      postId: postId ?? this.postId,
      commentId: commentId ?? this.commentId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Bildirim için okunabilir metin üretir.
  String get bodyText {
    switch (type) {
      case NotificationType.like:
        return '${actor.fullName} gönderini beğendi.';
      case NotificationType.comment:
        return '${actor.fullName} gönderine yorum yaptı.';
      case NotificationType.follow:
        return '${actor.fullName} seni takip etmeye başladı.';
      case NotificationType.message:
        return '${actor.fullName} sana mesaj gönderdi.';
      case NotificationType.bestAnswer:
        return '${actor.fullName} cevabını en iyi cevap olarak seçti.';
      case NotificationType.badge:
        return 'Yeni bir rozet kazandın!';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is NotificationModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
