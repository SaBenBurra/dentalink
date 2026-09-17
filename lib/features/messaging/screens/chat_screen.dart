import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';
import 'package:dentlink/core/constants/app_dimensions.dart';
import '../../../providers/message_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../data/models/conversation_model.dart';
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
      await ref.read(activeChatProvider(widget.userId).notifier).sendMessage(text);
      
      // 5. Başarılı olursa input'u temizle; başarısız olursa kullanıcının yazdığı metin kalır.
      if (mounted) {
        _messageController.clear();
      }
    } catch (e) {
      if (mounted) {
        debugPrint('ChatScreen: _sendMessage hatası: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          // TODO(l10n): Localizations dosyasına taşınacak
          const SnackBar(content: Text('Mesaj gönderilemedi, lütfen tekrar deneyin.')),
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
    final currentUser = ref.watch(currentUserProvider);

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
              name: widget.userName,
              imageUrl: widget.avatarUrl,
              size: AvatarSize.medium,
            ),
            const SizedBox(width: AppDimensions.spacing12),
            Expanded(
              child: Text(
                widget.userName,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO(E4): Sohbet detayları / şikayet et vb. menü eklenecek
            },
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
                  message: 'Mesajlar yüklenemedi',
                  onRetry: () =>
                      ref.invalidate(activeChatProvider(widget.userId)),
                );
              },
              data: (state) {
                final messages = state.messages;

                if (messages.isEmpty) {
                  return const Center(
                    // TODO(l10n): Localizations dosyasına taşınacak
                    child: Text('Henüz mesaj yok. İlk mesajı siz gönderin!'),
                  );
                }

                // reversed.toList() yerine index matematiği ile ters sıralama.
                // Her build'de yeni liste tahsisini (allocation) önler.
                final messageCount = messages.length;

                return ListView.builder(
                  reverse: true, // Listeyi alttan üste doğru dizer.
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.spacing16,
                  ),
                  itemCount: messageCount,
                  itemBuilder: (context, index) {
                    // reverse: true ile index 0 = en alttaki eleman.
                    // Kronolojik listeyi (eski→yeni) ters okuyarak
                    // en yeni mesajı alta yerleştiriyoruz.
                    final message = messages[messageCount - 1 - index];
                    final isMe = currentUser != null &&
                        message.senderId == currentUser.id;

                    return MessageBubble(
                      key: ValueKey(message.id),
                      text: message.content,
                      isMe: isMe,
                      time: _timeFormatter.format(message.createdAt),
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
            onAttachment: () {
              // TODO(E4): Görsel mesaj gönderme — Faz 3'te implemente edilecek.
            },
          ),
        ],
      ),
    );
  }
}

