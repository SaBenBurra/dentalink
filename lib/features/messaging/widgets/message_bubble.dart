import 'package:flutter/material.dart';
import 'package:dentlink/core/constants/app_dimensions.dart';

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String time;

  /// Aynı göndericinin ardışık mesajları gruplanır: grubun ilki üstte boşluk
  /// alır, yalnızca sonuncusu "kuyruklu" köşe gösterir.
  final bool isFirstInGroup;
  final bool isLastInGroup;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isMe,
    required this.time,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    const radius = Radius.circular(AppDimensions.radiusXLarge);
    const tail = Radius.circular(AppDimensions.radiusSmall);

    // Align: üst ebeveyn (ör. gün ayırıcılı Column) ortalasa bile balon kendi tarafında kalır.
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isMe ? AppDimensions.spacing56 : AppDimensions.spacing16,
          right: isMe ? AppDimensions.spacing16 : AppDimensions.spacing56,
          top: isFirstInGroup ? AppDimensions.spacing8 : AppDimensions.spacing2,
        ),
        constraints: const BoxConstraints(
          maxWidth: AppDimensions.maxContentWidth,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          border: isMe ? null : Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.only(
            topLeft: radius,
            topRight: radius,
            bottomLeft: isMe || !isLastInGroup ? radius : tail,
            bottomRight: !isMe || !isLastInGroup ? radius : tail,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.spacing12,
          AppDimensions.spacing8,
          AppDimensions.spacing12,
          AppDimensions.spacing6,
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
        ),
      ),
    );
  }
}
