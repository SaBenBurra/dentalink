import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

/// Gönderi kaydetme (yer imi) için animasyonlu buton.
///
/// Dokunulduğunda hafif dokunsal geri bildirim verir ve ikon 1.3x
/// ölçeğe büyüyüp geri döner (150 ms). [LikeButton] ile paralel
/// kod yapısına sahiptir.
///
/// Örnek kullanım:
/// ```dart
/// BookmarkButton(
///   isBookmarked: false,
///   onToggle: () => ref.read(postProvider.notifier).toggleBookmark(postId),
/// )
/// ```
class BookmarkButton extends StatefulWidget {
  /// Yeni bir [BookmarkButton] oluşturur.
  const BookmarkButton({
    super.key,
    required this.isBookmarked,
    this.onToggle,
    this.size = AppDimensions.iconDefault,
    this.showCount = false,
    this.bookmarkCount = 0,
  });

  /// Kaydedilmiş durumda olup olmadığı.
  final bool isBookmarked;

  /// Yer imi durumu değiştirildiğinde çağrılır.
  final VoidCallback? onToggle;

  /// İkon boyutu (varsayılan: 24).
  final double size;

  /// Sayacın gösterilip gösterilmeyeceği (varsayılan: false).
  final bool showCount;

  /// Toplam kaydetme sayısı.
  final int bookmarkCount;

  @override
  State<BookmarkButton> createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends State<BookmarkButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppDimensions.animFast,
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onToggle == null) return;
    HapticFeedback.lightImpact();
    _controller.forward(from: 0);
    widget.onToggle!();
  }

  /// Sayıyı kısa biçimde formatlar (ör. 1200 → "1.2K").
  static String _formatCount(int count) {
    if (count >= 1000) {
      final value = count / 1000;
      return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}K';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          customBorder: const CircleBorder(),
          onTap: _handleTap,
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              );
            },
            child: Icon(
              widget.isBookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: widget.isBookmarked
                  ? AppColors.bookmark
                  : colorScheme.onSurfaceVariant,
              size: widget.size,
            ),
          ),
        ),
        if (widget.showCount) ...[
          const SizedBox(width: AppDimensions.spacing4),
          Text(
            _formatCount(widget.bookmarkCount),
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
