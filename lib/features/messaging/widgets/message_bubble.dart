import 'package:flutter/material.dart';
import 'package:dentigo/core/constants/app_dimensions.dart';

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String time;

  /// Aynı göndericinin ardışık mesajları gruplanır: grubun ilki üstte boşluk
  /// alır, saat yalnızca sonuncuda görünür, gönderici tarafındaki köşeler
  /// birbirine bağlanır.
  final bool isFirstInGroup;
  final bool isLastInGroup;

  /// Karşı tarafın avatarı; grubun son balonunun yanında gösterilir.
  final Widget? avatar;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isMe,
    required this.time,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
    this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    const radius = Radius.circular(AppDimensions.radiusXLarge);
    const tail = Radius.circular(AppDimensions.radiusSmall);
    final senderTop = isFirstInGroup ? radius : tail;

    final bubble = Container(
      constraints: const BoxConstraints(
        maxWidth: AppDimensions.maxContentWidth,
      ),
      decoration: BoxDecoration(
        color: isMe ? colorScheme.primary : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.only(
          topLeft: isMe ? radius : senderTop,
          topRight: isMe ? senderTop : radius,
          bottomLeft: isMe ? radius : tail,
          bottomRight: isMe ? tail : radius,
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacing16,
        vertical: AppDimensions.spacing10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: textTheme.bodyMedium?.copyWith(
              color: isMe ? colorScheme.onPrimary : colorScheme.onSurface,
              height: 1.35,
            ),
          ),
          if (isLastInGroup) ...[
            const SizedBox(height: AppDimensions.spacing2),
            Text(
              time,
              style: textTheme.labelSmall?.copyWith(
                color: isMe
                    ? colorScheme.onPrimary.withValues(alpha: 0.75)
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? AppDimensions.spacing56 : AppDimensions.spacing12,
        right: isMe ? AppDimensions.spacing12 : AppDimensions.spacing56,
        top: isFirstInGroup ? AppDimensions.spacing12 : AppDimensions.spacing2,
      ),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            SizedBox.square(
              dimension: AppDimensions.avatarSmall,
              child: isLastInGroup ? avatar : null,
            ),
            const SizedBox(width: AppDimensions.spacing8),
          ],
          Flexible(child: bubble),
        ],
      ),
    );
  }
}
