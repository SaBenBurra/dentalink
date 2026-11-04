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
    required this.tooltip,
    this.onToggle,
    this.size = AppDimensions.iconDefault,
    this.showCount = false,
    this.count = 0,
    this.onCountTap,
    this.countTooltip,
  });

  final bool isActive;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final Color activeColor;

  /// Ekran okuyucu etiketi ve uzun basma ipucu (UX-13).
  final String tooltip;
  final VoidCallback? onToggle;
  final double size;
  final bool showCount;
  final int count;

  /// Sayaca dokununca ya da ikona basılı tutunca çağrılır. Sayaç 0 iken
  /// dokunuş [onToggle]'a gider, basılı tutmak bir şey yapmaz.
  final VoidCallback? onCountTap;

  /// Sayacın ekran okuyucu etiketi ve uzun basma ipucu.
  final String? countTooltip;

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

    final count = Text(
      formatCount(widget.count),
      style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
    );

    final openList = widget.count > 0 ? widget.onCountTap : null;

    final pad = ((AppDimensions.spacing48 - widget.size) / 2).clamp(
      0.0,
      double.infinity,
    );

    return Tooltip(
      message: widget.tooltip,
      // Basılı tutma listeyi açıyorsa ipucu onunla yarışmasın.
      triggerMode: openList != null ? TooltipTriggerMode.manual : null,
      child: InkWell(
        customBorder: widget.showCount
            ? const StadiumBorder()
            : const CircleBorder(),
        onTap: _handleTap,
        onLongPress: openList,
        // Dokunma alanı en az 48dp (UX-14). Sayaç da dokunma alanında:
        // ikonla arası yorum sayacındaki gibi 4dp kalır.
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppDimensions.spacing48,
            minHeight: AppDimensions.spacing48,
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: pad,
              right: widget.showCount ? AppDimensions.spacing4 : pad,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
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
                if (widget.showCount) ...[
                  const SizedBox(width: AppDimensions.spacing4),
                  if (widget.onCountTap == null)
                    count
                  else
                    Tooltip(
                      message: widget.countTooltip,
                      triggerMode: TooltipTriggerMode.manual,
                      child: InkWell(
                        customBorder: const StadiumBorder(),
                        onTap: openList ?? _handleTap,
                        // Sayaç ayrı dokunma hedefi: en az 48dp (UX-14).
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minWidth: AppDimensions.spacing48,
                            minHeight: AppDimensions.spacing48,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            widthFactor: 1,
                            child: count,
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
