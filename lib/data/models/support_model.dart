// Destek sohbeti modelleri — `support_threads` ve `support_messages` (049).

/// open: ekip bekliyor, answered: kullanıcı bekliyor, resolved: kapandı.
/// Kullanıcı yazınca sohbet yeniden open olur.
enum SupportStatus {
  open,
  answered,
  resolved;

  static SupportStatus parse(String? value) => SupportStatus.values.firstWhere(
    (s) => s.name == value,
    orElse: () => SupportStatus.open,
  );
}

/// İlk mesajda seçilir; DB'deki CHECK listesiyle aynı.
enum SupportCategory { bug, account, suggestion, complaint, other }

class SupportThread {
  final String id;
  final SupportStatus status;
  final DateTime lastMessageAt;
  final DateTime? userReadAt;
  final DateTime? staffReadAt;

  const SupportThread({
    required this.id,
    required this.status,
    required this.lastMessageAt,
    this.userReadAt,
    this.staffReadAt,
  });

  factory SupportThread.fromJson(Map<String, dynamic> json) => SupportThread(
    id: json['id'] as String,
    status: SupportStatus.parse(json['status'] as String?),
    lastMessageAt: DateTime.parse(json['last_message_at'] as String).toLocal(),
    userReadAt: _date(json['user_read_at']),
    staffReadAt: _date(json['staff_read_at']),
  );

  /// Ekibin cevabı kullanıcı tarafından henüz görülmedi. Cevap sohbeti
  /// answered yapar ve last_message_at'i ilerletir; iç not ikisini de değiştirmez.
  bool get hasUnread =>
      status == SupportStatus.answered &&
      (userReadAt == null || userReadAt!.isBefore(lastMessageAt));

  /// Ekip, kullanıcının [at] zamanındaki mesajını okudu mu.
  bool staffReadSince(DateTime at) =>
      staffReadAt != null && !staffReadAt!.isBefore(at);
}

class SupportMessage {
  final String id;
  final bool fromStaff;

  /// Cevaplayan personelin adı; kullanıcı mesajında ve silinmiş hesapta null.
  final String? staffName;
  final String content;
  final DateTime createdAt;

  const SupportMessage({
    required this.id,
    required this.fromStaff,
    this.staffName,
    required this.content,
    required this.createdAt,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) => SupportMessage(
    id: json['id'] as String,
    fromStaff: json['from_staff'] as bool,
    staffName: json['from_staff'] == true
        ? ((json['sender'] as Map<String, dynamic>?)?['full_name'] as String?)
        : null,
    content: json['content'] as String,
    createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SupportMessage && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

DateTime? _date(Object? v) =>
    v == null ? null : DateTime.parse(v as String).toLocal();

/// Sohbetin altındaki durum notu.
enum SupportNote { received, seen, resolved }

/// Son mesaj kullanıcınınsa ekip bekleniyor (okudu mu), çözüldüyse kapanış notu.
SupportNote? supportNoteOf(
  SupportThread? thread,
  List<SupportMessage> messages,
) {
  if (thread == null || messages.isEmpty) return null;
  if (thread.status == SupportStatus.resolved) return SupportNote.resolved;
  final last = messages.last;
  if (last.fromStaff) return null;
  return thread.staffReadSince(last.createdAt)
      ? SupportNote.seen
      : SupportNote.received;
}
