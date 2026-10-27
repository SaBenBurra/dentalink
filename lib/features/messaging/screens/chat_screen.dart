import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';
import 'package:dentlink/core/constants/app_dimensions.dart';
import '../../../providers/message_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/load_more_footer.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../data/models/conversation_model.dart';
import '../../../providers/user_provider.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../shared/utils/moderation_actions.dart';
import '../../../data/models/enums.dart';
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

    // Deep link/bildirimden açılınca isim ve avatar query'de olmayabilir.
    final needsPeer = widget.userName.isEmpty;
    final peer = needsPeer
        ? ref.watch(userProfileProvider(widget.userId)).valueOrNull
        : null;
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
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            UserAvatar(
              name: userName,
              imageUrl: avatarUrl,
              size: AvatarSize.medium,
            ),
            const SizedBox(width: AppDimensions.spacing12),
            Expanded(
              child: Text(
                userName,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
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
              loading: () => const DentLinkLoadingSpinner(),
              error: (err, st) {
                debugPrint('ChatScreen: mesaj yükleme hatası: $err\n$st');
                return DentLinkErrorWidget(
                  message: l10n.chatLoadError,
                  onRetry: () =>
                      ref.invalidate(activeChatProvider(widget.userId)),
                );
              },
              data: (state) {
                final messages = state.messages;

                if (messages.isEmpty) {
                  return Center(child: Text(l10n.chatEmpty));
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
                    final bubble = MessageBubble(
                      text: message.content,
                      isMe: isMe,
                      time: _timeFormatter.format(message.createdAt),
                    );

                    // Günün ilk mesajının üstüne gün ayırıcısı.
                    final startsDay =
                        position == 0 ||
                        !DateUtils.isSameDay(
                          messages[position - 1].createdAt,
                          message.createdAt,
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

/// Sohbetteki gün ayırıcısının metni: Bugün, Dün, aynı yıl "5 Mart", eski yıl "5 Mart 2025".
String chatDayLabel(DateTime day, DateTime now, AppLocalizations l10n) {
  final today = DateUtils.dateOnly(now);
  final date = DateUtils.dateOnly(day);
  // Yaz saati geçişinde gün 23/25 saat olabilir, yuvarla.
  final days = (today.difference(date).inHours / 24).round();
  if (days == 0) return l10n.chatToday;
  if (days == 1) return l10n.chatYesterday;
  // Gün/ay sırası dile göre: TR "5 Mart", EN "March 5".
  final format = date.year == today.year
      ? DateFormat.MMMMd(l10n.localeName)
      : DateFormat.yMMMMd(l10n.localeName);
  return format.format(date);
}

class _DaySeparator extends StatelessWidget {
  const _DaySeparator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacing12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacing12,
          vertical: AppDimensions.spacing4,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
        ),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
