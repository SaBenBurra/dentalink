import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../providers/support_provider.dart';

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

/// Mesajlar ekranının sağ altındaki destek butonu; okunmamış cevapta rozet.
class SupportFab extends ConsumerWidget {
  const SupportFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasUnread =
        ref.watch(supportThreadProvider).valueOrNull?.hasUnread == true;
    return FloatingActionButton(
      heroTag: null,
      tooltip: AppLocalizations.of(context)!.supportContact,
      onPressed: () => context.push('/support'),
      child: Badge(
        isLabelVisible: hasUnread,
        child: const Icon(Icons.support_agent_rounded),
      ),
    );
  }
}
