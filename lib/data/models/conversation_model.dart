import 'user_model.dart';

/// Konuşma modeli — Supabase `conversations` tablosuyla eşleşir.
/// `last_message_id` dairesel FK kaldırıldı; yerine timestamp + preview kullanılır.
class ConversationModel {
  final String id;

  /// Mevcut kullanıcının karşı taraftaki kullanıcısı.
  final UserModel otherUser;

  final DateTime? lastMessageAt;
  final String? lastMessagePreview;

  /// Mevcut kullanıcının okunmamış mesaj sayısı.
  /// (Supabase'de user1_unread_count veya user2_unread_count'a karşılık gelir.)
  final int unreadCount;

  const ConversationModel({
    required this.id,
    required this.otherUser,
    this.lastMessageAt,
    this.lastMessagePreview,
    this.unreadCount = 0,
  });

  ConversationModel copyWith({
    String? id,
    UserModel? otherUser,
    DateTime? lastMessageAt,
    String? lastMessagePreview,
    int? unreadCount,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      otherUser: otherUser ?? this.otherUser,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ConversationModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
