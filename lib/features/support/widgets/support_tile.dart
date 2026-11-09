import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../providers/support_provider.dart';
import '../../../shared/extensions/support_l10n.dart';
import '../../messaging/screens/chat_screen.dart' show chatListTime;
import '../../messaging/widgets/conversation_tile.dart';

/// Destek ekibinin avatarı; personelin kendi fotoğrafı gösterilmez.
class SupportAvatar extends StatelessWidget {
  const SupportAvatar({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: colorScheme.primaryContainer,
      child: Icon(
        Icons.support_agent_rounded,
        size: size * 0.55,
        color: colorScheme.onPrimaryContainer,
      ),
    );
  }
}

/// Mesajlar'ın en üstündeki sabit "Dentigo Destek" satırı.
class SupportTile extends ConsumerWidget {
  const SupportTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final thread = ref.watch(supportThreadProvider).valueOrNull;
    return ConversationTile(
      name: l10n.supportTitle,
      lastMessage: thread?.status.label(l10n) ?? l10n.supportTileHint,
      time: thread == null
          ? ''
          : chatListTime(thread.lastMessageAt, DateTime.now(), l10n),
      unreadCount: thread?.hasUnread == true ? 1 : 0,
      avatar: const SupportAvatar(size: AppDimensions.avatarLarge),
      onTap: () => context.push('/support'),
    );
  }
}
