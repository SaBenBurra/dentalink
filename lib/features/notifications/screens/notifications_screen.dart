import 'package:dentlink/data/models/notification_model.dart';
import 'package:dentlink/features/notifications/widgets/notifications_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../data/models/enums.dart';
import '../../../data/providers/repository_providers.dart';
import '../../../providers/notification_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../widgets/notification_tile.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF11211F)
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
    final localizations = AppLocalizations.of(context)!;
    ref.read(notificationsProvider.notifier).markRead(notification.id);

    final type = notification.type;
    if (type == NotificationType.follow) {
      context.push('/profile/${notification.actor.id}');
    } else if (type == NotificationType.message) {
      context.push(
        Uri(
          path: '/chat/${notification.actor.id}',
          queryParameters: {
            'name': notification.actor.fullName,
            'avatar': notification.actor.avatarUrl ?? '',
          },
        ).toString(),
      );
    } else if (notification.postId != null) {
      // Yükleme göstergesi
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        final postRepo = ref.read(feedRepositoryProvider);
        final post = await postRepo.getPostById(notification.postId!);
        
        if (!context.mounted) return;
        context.pop(); // Yükleme göstergesini kapat

        if (post.type == PostType.casePost) {
          context.push('/feed/case/${post.id}');
        } else if (post.type == PostType.question) {
          context.push('/feed/question/${post.id}');
        }
      } catch (e) {
        if (!context.mounted) return;
        context.pop(); // Yükleme göstergesini kapat
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.postNotFound),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
              onTap: () => _handleNotificationTap(context, ref, notification),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: DentLinkErrorWidget(
          message: localizations.postLoadError,
          onRetry: () => ref.refresh(notificationsProvider),
        ),
      ),
    );
  }
}
