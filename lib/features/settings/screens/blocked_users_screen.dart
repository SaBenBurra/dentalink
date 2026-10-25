import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../providers/feed_provider.dart';
import '../../../providers/moderation_provider.dart';
import '../../../shared/utils/error_messages.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/user_tile.dart';

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  Future<void> _unblock(BuildContext context, WidgetRef ref, String userId) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(blockedUsersProvider.notifier).unblock(userId);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(getErrorMessage(l10n, e))));
      return;
    }
    // Kişinin postları feed'e geri gelsin (nadir işlem, tam yenileme yeterli).
    ref.invalidate(feedProvider);
    messenger.showSnackBar(SnackBar(content: Text(l10n.userUnblocked)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final blocked = ref.watch(blockedUsersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsBlocked)),
      body: blocked.when(
        loading: () => const DentLinkLoadingSpinner(),
        error: (e, _) => DentLinkErrorWidget(
          message: getErrorMessage(l10n, e),
          onRetry: () => ref.invalidate(blockedUsersProvider),
        ),
        data: (users) => users.isEmpty
            ? DentLinkEmptyState(icon: Icons.block_outlined, title: l10n.blockedEmpty)
            : ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, i) {
                  final user = users[i];
                  return UserTile(
                    user: user,
                    onTap: () => context.push('/profile/${user.id}'),
                    trailing: OutlinedButton(
                      onPressed: () => _unblock(context, ref, user.id),
                      child: Text(l10n.unblock),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
