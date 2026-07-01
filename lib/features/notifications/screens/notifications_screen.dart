import 'package:dentlink/data/models/notification_model.dart';
import 'package:dentlink/features/notifications/widgets/notifications_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../providers/notification_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_widget.dart';
import '../widgets/notification_tile.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notificationsState = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF11211F)
          : AppColors.lightBackground,
      appBar: NotificationsAppBar(),
      body: listNotifications(notificationsState, isDark, ref),
    );
  }

  Widget? listNotifications(
    AsyncValue<List<NotificationModel>> notificationsState,
    bool isDark,
    WidgetRef ref,
  ) {
    return notificationsState.when(
      data: (notifications) {
        if (notifications.isEmpty) {
          return const Center(
            child: DentLinkEmptyState(
              icon: Icons.notifications_off_outlined,
              title: 'Bildirim Yok',
              subtitle: 'Henüz yeni bir bildiriminiz bulunmuyor.',
            ),
          );
        }

        return ListView.separated(
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
              onTap: () {
                ref
                    .read(notificationsProvider.notifier)
                    .markRead(notification.id);
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: DentLinkErrorWidget(
          message: 'Bildirimler yüklenemedi.',
          onRetry: () => ref.refresh(notificationsProvider),
        ),
      ),
    );
  }
}
