import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';
import 'package:dentigo/core/constants/app_dimensions.dart';
import '../../../providers/message_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/load_more_footer.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/extensions/user_title_ui.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/models/message_model.dart';
import '../../../providers/user_provider.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../shared/utils/moderation_actions.dart';
import '../../../data/models/enums.dart';
import '../../../core/push/message_notifications.dart';
import 'package:go_router/go_router.dart';

/// Saat formatı — her build/itemBuilder çağrısında yeniden oluşturulmasını
/// önlemek için modül seviyesinde tanımlanır.
final _timeFormatter = DateFormat('HH:mm');

class ChatScreen extends ConsumerStatefulWidget {
  final String userId;
  final String userName;
  final String avatarUrl;

  const ChatScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.avatarUrl = '',
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // Ekran ilk açıldığında okunmamış mesajları kontrol et (Side-effect'i initState'te yapıyoruz)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndMarkAsRead();
    });
  }

  void _markAsReadIfNeeded(List<ConversationModel> convs) {
    final c = convs.firstWhereOrNull((c) => c.otherUser.id == widget.userId);
    if (c != null && c.unreadCount > 0) {
      ref.read(activeChatProvider(widget.userId).notifier).markAsRead(c.id);
      cancelMessageNotification(c.id);
    }
  }

  void _checkAndMarkAsRead() {
    final convs = ref.read(conversationsProvider).valueOrNull ?? [];
    _markAsReadIfNeeded(convs);
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      // 4. Gönderim asenkron bekleniyor, hatalar yakalanıyor.
      await ref
          .read(activeChatProvider(widget.userId).notifier)
          .sendMessage(text);

      // 5. Başarılı olursa input'u temizle; başarısız olursa kullanıcının yazdığı metin kalır.
      if (mounted) {
        _messageController.clear();
      }
    } catch (e) {
      if (mounted) {
        debugPrint('ChatScreen: _sendMessage hatası: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.chatSendError)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final currentUser = ref.watch(currentUserProvider);

    // Deep link/bildirimden açılınca isim ve avatar query'de olmayabilir;
    // unvan her durumda profilden gelir.
    final peer = ref.watch(userProfileProvider(widget.userId)).valueOrNull;
    final needsPeer = widget.userName.isEmpty;
    final userName = needsPeer ? (peer?.fullName ?? '') : widget.userName;
    final avatarUrl = needsPeer ? (peer?.avatarUrl ?? '') : widget.avatarUrl;

    // Tek provider — konuşma bulma, mesaj yükleme ve okundu işaretleme
    // mantığının tamamı ActiveChatNotifier içinde kapsüllenmiştir.
    final chatState = ref.watch(activeChatProvider(widget.userId));

    // Ekran açıkken gelen YENİ mesajları okundu işaretlemek için ConversationsProvider'ı dinliyoruz.
    ref.listen(conversationsProvider, (previous, next) {
      final convs = next.valueOrNull ?? [];
      _markAsReadIfNeeded(convs);
    });

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        title: InkWell(
          onTap: () => context.push('/profile/${widget.userId}'),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.spacing4,
            ),
            child: Row(
              children: [
                UserAvatar(
                  name: userName,
                  imageUrl: avatarUrl,
                  size: AvatarSize.medium,
                ),
                const SizedBox(width: AppDimensions.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        userName,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (peer != null)
                        Text(
                          peer.title.displayName(context),
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          ModerationMenuButton(
            target: ReportTarget.user,
            targetId: widget.userId,
            userId: widget.userId,
            onBlocked: () =>
                context.canPop() ? context.pop() : context.go('/messages'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chatState.when(
              loading: () => const DentigoLoadingSpinner(),
              error: (err, st) {
                debugPrint('ChatScreen: mesaj yükleme hatası: $err\n$st');
                return DentigoErrorWidget(
                  message: l10n.chatLoadError,
                  onRetry: () =>
                      ref.invalidate(activeChatProvider(widget.userId)),
                );
              },
              data: (state) {
                final messages = state.messages;

                if (messages.isEmpty) {
                  return _ChatIntro(
                    name: userName,
                    avatarUrl: avatarUrl,
                    title: peer?.title.displayName(context),
                  );
                }

                // reversed.toList() yerine index matematiği ile ters sıralama.
                // Her build'de yeni liste tahsisini (allocation) önler.
                final messageCount = messages.length;
                final notifier = ref.read(
                  activeChatProvider(widget.userId).notifier,
                );
                final hasMore = notifier.hasMore;

                return ListView.builder(
                  reverse: true, // Listeyi alttan üste doğru dizer.
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.spacing16,
                  ),
                  itemCount: messageCount + (hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    // En üstte: yukarı kaydırınca daha eski mesajlar gelir.
                    if (index == messageCount) {
                      return LoadMoreFooter(onLoadMore: notifier.loadMore);
                    }
                    // reverse: true ile index 0 = en alttaki eleman.
                    // Kronolojik listeyi (eski→yeni) ters okuyarak
                    // en yeni mesajı alta yerleştiriyoruz.
                    final position = messageCount - 1 - index;
                    final message = messages[position];
                    final isMe =
                        currentUser != null &&
                        message.senderId == currentUser.id;
                    final prev = position > 0 ? messages[position - 1] : null;
                    final next = position < messageCount - 1
                        ? messages[position + 1]
                        : null;
                    // Günün ilk mesajının üstüne gün ayırıcısı.
                    final startsDay =
                        prev == null ||
                        !DateUtils.isSameDay(prev.createdAt, message.createdAt);
                    final bubble = MessageBubble(
                      text: message.content,
                      isMe: isMe,
                      time: _timeFormatter.format(message.createdAt),
                      isFirstInGroup: !isSameMessageGroup(prev, message),
                      isLastInGroup: !isSameMessageGroup(message, next),
                      avatar: UserAvatar(
                        name: userName,
                        imageUrl: avatarUrl,
                        size: AvatarSize.small,
                      ),
                    );
                    if (!startsDay) {
                      return KeyedSubtree(
                        key: ValueKey(message.id),
                        child: bubble,
                      );
                    }
                    return Column(
                      key: ValueKey(message.id),
                      children: [
                        _DaySeparator(
                          label: chatDayLabel(
                            message.createdAt,
                            DateTime.now(),
                            l10n,
                          ),
                        ),
                        bubble,
                      ],
                    );
                  },
                );
              },
            ),
          ),
          ChatInput(
            controller: _messageController,
            isSending: _isSending,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

/// Aynı göndericiden, aynı gün ve 5 dakika içinde gelen ardışık mesajlar tek grup.
bool isSameMessageGroup(MessageModel? a, MessageModel? b) =>
    a != null &&
    b != null &&
    a.senderId == b.senderId &&
    DateUtils.isSameDay(a.createdAt, b.createdAt) &&
    b.createdAt.difference(a.createdAt).abs() < const Duration(minutes: 5);

/// Sohbet listesindeki zaman (WhatsApp gibi): bugün "14:32", dün "Dün", son
/// bir hafta gün adı "Pazartesi", daha eskisi "5.11.2026".
String chatListTime(DateTime at, DateTime now, AppLocalizations l10n) {
  final local = at.toLocal();
  final days = _daysBetween(local, now);
  if (days == 0) return _timeFormatter.format(local);
  if (days == 1) return l10n.chatYesterday;
  if (days < 7) return DateFormat.EEEE(l10n.localeName).format(local);
  return DateFormat.yMd(l10n.localeName).format(local);
}

/// Takvim günü farkı; yaz saati geçişinde gün 23/25 saat olabilir, yuvarlanır.
int _daysBetween(DateTime day, DateTime now) =>
    (DateUtils.dateOnly(now).difference(DateUtils.dateOnly(day)).inHours / 24)
        .round();

/// Sohbetteki gün ayırıcısının metni: Bugün, Dün, aynı yıl "5 Mart", eski yıl "5 Mart 2025".
String chatDayLabel(DateTime day, DateTime now, AppLocalizations l10n) {
  final today = DateUtils.dateOnly(now);
  final date = DateUtils.dateOnly(day);
  final days = _daysBetween(date, today);
  if (days == 0) return l10n.chatToday;
  if (days == 1) return l10n.chatYesterday;
  // Gün/ay sırası dile göre: TR "5 Mart", EN "March 5".
  final format = date.year == today.year
      ? DateFormat.MMMMd(l10n.localeName)
      : DateFormat.yMMMMd(l10n.localeName);
  return format.format(date);
}

/// Henüz mesaj yokken sohbetin kiminle olduğunu gösterir.
class _ChatIntro extends StatelessWidget {
  const _ChatIntro({required this.name, required this.avatarUrl, this.title});

  final String name;
  final String avatarUrl;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      // Klavye açılınca alan daralır; taşmasın diye kaydırılabilir.
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.spacing32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            UserAvatar(
              name: name,
              imageUrl: avatarUrl,
              size: AvatarSize.xLarge,
            ),
            const SizedBox(height: AppDimensions.spacing16),
            Text(
              name,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (title != null)
              Text(
                title!,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: AppDimensions.spacing12),
            Text(
              AppLocalizations.of(context)!.chatEmpty,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DaySeparator extends StatelessWidget {
  const _DaySeparator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(
        top: AppDimensions.spacing24,
        bottom: AppDimensions.spacing4,
      ),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          shape: const StadiumBorder(),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacing12,
            vertical: AppDimensions.spacing4,
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }
}
