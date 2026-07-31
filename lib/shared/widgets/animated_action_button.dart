import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/utils/number_formatter.dart';

/// Dokunulduğunda scale animasyonu ve dokunsal geri bildirim uygulayan
/// genel amaçlı etkileşim butonu.
///
/// [LikeButton] ve [BookmarkButton] gibi widget'ların ortak davranışını
/// merkezileştirir (DRY prensibi).
class AnimatedActionButton extends StatefulWidget {
  const AnimatedActionButton({
    super.key,
    required this.isActive,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.activeColor,
    this.onToggle,
    this.size = AppDimensions.iconDefault,
    this.showCount = false,
    this.count = 0,
  });

  final bool isActive;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final Color activeColor;
  final VoidCallback? onToggle;
  final double size;
  final bool showCount;
  final int count;

  @override
  State<AnimatedActionButton> createState() => _AnimatedActionButtonState();
}

class _AnimatedActionButtonState extends State<AnimatedActionButton>
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
              widget.isActive ? widget.activeIcon : widget.inactiveIcon,
              color: widget.isActive
                  ? widget.activeColor
                  : colorScheme.onSurfaceVariant,
              size: widget.size,
            ),
          ),
        ),
        if (widget.showCount) ...[
          const SizedBox(width: AppDimensions.spacing4),
          Text(
            formatCount(widget.count),
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
