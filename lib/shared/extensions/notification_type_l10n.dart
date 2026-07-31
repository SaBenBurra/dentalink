import 'package:flutter/material.dart';
import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import '../../data/models/enums.dart';


/// NotificationType için lokalize metin üretimi.
extension NotificationTypeL10n on NotificationType {
  /// Bildirim için lokalize okunabilir metin üretir.
  String getBodyText(BuildContext context, String actorName) {
    final l10n = AppLocalizations.of(context);
    return switch (this) {
      NotificationType.like => l10n.notificationLiked(actorName),
      NotificationType.comment => l10n.notificationCommented(actorName),
      NotificationType.follow => l10n.notificationFollowed(actorName),
      NotificationType.message => l10n.notificationMessaged(actorName),
      NotificationType.bestAnswer => l10n.notificationBestAnswer(actorName),
      NotificationType.badge => l10n.notificationBadge,
    };
  }
}
