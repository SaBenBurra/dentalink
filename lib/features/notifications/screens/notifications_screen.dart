import 'package:dentlink/data/models/notification_model.dart';
import 'package:dentlink/features/notifications/widgets/notifications_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/router/notification_route.dart';
import '../../../providers/notification_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/utils/error_messages.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../widgets/notification_tile.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: NotificationsAppBar(),
      body: const _NotificationListView(),
    );
  }
}

class _NotificationListView extends ConsumerWidget {
  const _NotificationListView();

  Future<void> _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notification,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    // Gezinmeyi bekletme; hata olursa notifier geri alır, burada yalnızca bildir.
    ref
        .read(notificationsProvider.notifier)
        .markRead(notification.id)
        .catchError((Object e) => messenger.showSnackBar(
              SnackBar(content: Text(getErrorMessage(l10n, e))),
            ));

    final route = notificationRoute(
      type: notification.type,
      actorId: notification.actor.id,
      actorName: notification.actor.fullName,
      actorAvatar: notification.actor.avatarUrl,
      postId: notification.postId,
      commentId: notification.commentId,
    );
    if (route != null) context.push(route);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notificationsState = ref.watch(notificationsProvider);
    final localizations = AppLocalizations.of(context)!;

    return notificationsState.when(
      data: (notifications) {
        if (notifications.isEmpty) {
          return Center(
            child: DentLinkEmptyState(
              icon: Icons.notifications_off_outlined,
              title: localizations.notificationsTitle,
              subtitle: localizations.noNotifications,
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(notificationsProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacing8),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
              indent: 72,
            ),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return NotificationTile(
                notification: notification,
                onTap: () => _handleNotificationTap(context, ref, notification),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: DentLinkErrorWidget(
          message: localizations.notificationsLoadError,
          onRetry: () => ref.refresh(notificationsProvider),
        ),
      ),
    );
  }
}
