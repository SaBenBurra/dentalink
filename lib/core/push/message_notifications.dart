import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../l10n/generated/app_localizations.dart';

// Android DM bildirimleri (WhatsApp gibi): sunucu DM'i data-only gönderir
// (supabase/functions/push), bildirimi burada MessagingStyle ile çizeriz.
// Sohbet başına bir bildirim (tag = conversation_id) her yeni mesajda okunmamış
// son mesajlarla yeniden çizilir ve yeniden titrer; birden fazla sohbet bir
// özet bildirimin altında toplanır. iOS'ta sistem gösterir (thread-id ile yığın).

const _channelId = 'messages';
const _groupKey = 'com.atlas.dentlink.messages';
const _summaryTag = 'summary';
// Android bildirimi (tag, id) ile tanır; tag sohbeti ayırdığı için id sabit.
const _id = 0;

final _plugin = FlutterLocalNotificationsPlugin();
bool _initialized = false;

/// Bildirime dokunulunca push verisiyle çağrılır (yalnızca ana isolate).
typedef MessageNotificationTap = void Function(Map<String, dynamic> data);

/// Ana isolate'te PushController çağırır: dokunuşları bağlar, uygulamayı bir
/// bildirim açtıysa onun verisini döner.
Future<Map<String, dynamic>?> initMessageNotifications(
  MessageNotificationTap onTap,
) async {
  if (!Platform.isAndroid) return null;
  await _plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
    onDidReceiveNotificationResponse: (r) {
      final data = _decodePayload(r.payload);
      if (data != null) onTap(data);
    },
  );
  _initialized = true;
  final launch = await _plugin.getNotificationAppLaunchDetails();
  if (launch?.didNotificationLaunchApp != true) return null;
  return _decodePayload(launch!.notificationResponse?.payload);
}

/// Uygulama arka plandayken/kapalıyken gelen FCM mesajları (ayrı isolate).
@pragma('vm:entry-point')
Future<void> firebaseBackgroundMessageHandler(RemoteMessage message) =>
    showMessageNotification(message.data);

/// Push verisi DM ise sohbet bildirimini (yeniden) çizer; değilse bir şey yapmaz.
Future<void> showMessageNotification(Map<String, dynamic> data) async {
  if (!Platform.isAndroid || data['type'] != 'message') return;
  final conversationId = data['conversation_id'] as String?;
  final name = data['actor_name'] as String? ?? '';
  final sender = Person(name: name, key: data['actor_id'] as String?);
  final messages = [
    for (final m in parsePushMessages(data['messages'] as String?))
      Message(m.text, m.at, sender),
  ];
  if (conversationId == null || messages.isEmpty) return;

  await _ensureInitialized();
  final l10n = _l10n();
  await _plugin.show(
    id: _id,
    title: name,
    body: messages.last.text,
    payload: jsonEncode({...data}..remove('messages')),
    notificationDetails: NotificationDetails(
      android: _details(
        l10n,
        tag: conversationId,
        when: messages.last.timestamp,
        style: MessagingStyleInformation(
          Person(name: l10n.messageNotificationYou),
          messages: messages,
        ),
      ),
    ),
  );
  await _updateSummary(l10n);
}

/// Sohbet ekranı açılınca o sohbetin bildirimini kaldırır.
Future<void> cancelMessageNotification(String conversationId) async {
  if (!Platform.isAndroid || !_initialized) return;
  try {
    await _plugin.cancel(id: _id, tag: conversationId);
    await _updateSummary(_l10n());
  } catch (e) {
    debugPrint('cancel message notification: $e');
  }
}

/// Sunucunun `messages` alanı: `[{text, at}]`, eskiden yeniye.
List<({String text, DateTime at})> parsePushMessages(String? raw) {
  if (raw == null || raw.isEmpty) return const [];
  final list = jsonDecode(raw) as List<dynamic>;
  return [
    for (final m in list.cast<Map<String, dynamic>>())
      (
        text: m['text'] as String,
        at: DateTime.parse(m['at'] as String).toLocal(),
      ),
  ];
}

Future<void> _ensureInitialized() async {
  if (_initialized) return;
  // Arka plan isolate'i: dokunuş ana isolate'te getNotificationAppLaunchDetails ile okunur.
  await _plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );
  _initialized = true;
}

// Özet: Android'de sohbet bildirimlerini tek grupta toplar; kendisi titremez.
Future<void> _updateSummary(AppLocalizations l10n) async {
  final android = _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  final active = (await android?.getActiveNotifications() ?? const [])
      .where((n) => n.groupKey == _groupKey && n.tag != _summaryTag)
      .toList();
  if (active.isEmpty) {
    await _plugin.cancel(id: _id, tag: _summaryTag);
    return;
  }
  var total = 0;
  for (final n in active) {
    total += int.tryParse(_decodePayload(n.payload)?['unread'] ?? '') ?? 1;
  }
  final summary = l10n.messageNotificationSummary(active.length, total);
  await _plugin.show(
    id: _id,
    title: summary,
    body: summary,
    notificationDetails: NotificationDetails(
      android: _details(
        l10n,
        tag: _summaryTag,
        summary: true,
        style: InboxStyleInformation([
          for (final n in active) '${n.title ?? ''}  ${n.body ?? ''}',
        ], summaryText: summary),
      ),
    ),
  );
}

AndroidNotificationDetails _details(
  AppLocalizations l10n, {
  required String tag,
  required StyleInformation style,
  DateTime? when,
  bool summary = false,
}) => AndroidNotificationDetails(
  _channelId,
  l10n.messageNotificationChannel,
  importance: Importance.high,
  priority: Priority.high,
  category: AndroidNotificationCategory.message,
  tag: tag,
  groupKey: _groupKey,
  setAsGroupSummary: summary,
  groupAlertBehavior: GroupAlertBehavior.children,
  when: when?.millisecondsSinceEpoch,
  styleInformation: style,
);

Map<String, dynamic>? _decodePayload(String? payload) {
  if (payload == null || payload.isEmpty) return null;
  try {
    return jsonDecode(payload) as Map<String, dynamic>;
  } on FormatException {
    return null;
  }
}

// Arka plan isolate'inde context yok: cihaz dili, desteklenmiyorsa Türkçe.
AppLocalizations _l10n() {
  final locale = PlatformDispatcher.instance.locale;
  return AppLocalizations.delegate.isSupported(locale)
      ? lookupAppLocalizations(locale)
      : lookupAppLocalizations(const Locale('tr'));
}

/// Çıkışta: önceki kullanıcının mesaj bildirimleri cihazda kalmasın.
Future<void> cancelAllMessageNotifications() async {
  if (!Platform.isAndroid || !_initialized) return;
  await _plugin.cancelAll();
}
