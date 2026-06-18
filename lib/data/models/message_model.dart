/// Mesaj modeli — Supabase `messages` tablosuyla eşleşir.
class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final bool isRead;

  /// Soft delete — null ise mesaj aktif, dolu ise silinmiş.
  final DateTime? deletedAt;

  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.isRead = false,
    this.deletedAt,
    required this.createdAt,
  });

  bool get isDeleted => deletedAt != null;

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    bool? isRead,
    DateTime? deletedAt,
    DateTime? createdAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MessageModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
