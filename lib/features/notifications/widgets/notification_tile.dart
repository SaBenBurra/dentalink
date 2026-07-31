import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/notification_model.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../shared/extensions/notification_type_l10n.dart';
import '../../../shared/widgets/relative_time_text.dart';

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;

  const NotificationTile({super.key, required this.notification, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final unreadBgColor = isDark
        ? colorScheme.primary.withValues(alpha: 0.1)
        : colorScheme.primary.withValues(alpha: 0.05);

    return InkWell(
      onTap: onTap,
      child: Container(
        color: notification.isRead ? Colors.transparent : unreadBgColor,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacing16,
          vertical: AppDimensions.spacing12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar and Icon Badge
            Stack(
              children: [
                UserAvatar(
                  imageUrl: notification.actor.avatarUrl,
                  name: notification.actor.fullName,
                  size: AvatarSize.large,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(AppDimensions.spacing4),
                    decoration: BoxDecoration(
                      color: _getIconBackgroundColor(
                        notification.type,
                        colorScheme,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF11211F)
                            : AppColors.lightBackground,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _getIconForType(notification.type),
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppDimensions.spacing16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.type.getBodyText(context, notification.actor.fullName),
                    style: textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacing4),
                  Text(
                    RelativeTimeText.format(
                      notification.createdAt,
                      AppLocalizations.of(context),
                    ),
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: notification.isRead
                          ? FontWeight.normal
                          : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Unread Dot Indicator
            if (!notification.isRead)
              Padding(
                padding: const EdgeInsets.only(
                  left: AppDimensions.spacing8,
                  top: AppDimensions.spacing8,
                ),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }


  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.like:
        return Icons.favorite;
      case NotificationType.comment:
        return Icons.mode_comment;
      case NotificationType.follow:
        return Icons.person_add;
      case NotificationType.message:
        return Icons.mail;
      case NotificationType.bestAnswer:
        return Icons.check_circle;
      case NotificationType.badge:
        return Icons.workspace_premium;
    }
  }

  Color _getIconBackgroundColor(
    NotificationType type,
    ColorScheme colorScheme,
  ) {
    switch (type) {
      case NotificationType.like:
        return Colors.red;
      case NotificationType.comment:
        return colorScheme.primary;
      case NotificationType.follow:
        return Colors.green;
      case NotificationType.message:
        return Colors.orange;
      case NotificationType.bestAnswer:
        return Colors.teal;
      case NotificationType.badge:
        return Colors.amber.shade600;
    }
  }
}
