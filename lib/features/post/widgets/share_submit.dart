import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dentlink/core/constants/app_dimensions.dart';
import 'package:dentlink/core/l10n/generated/app_localizations.dart';

/// Gönderi formlarının altındaki geniş paylaş butonu.
///
/// [shared] true olunca buton kendi içinde başarı animasyonu oynatır: gönder
/// yazı söner, buton daireye daralır, onay işareti belirir ve halka yayılır.
/// Animasyon bitince [onSharedAnimationEnd] çağrılır.
class ShareSubmitBar extends StatefulWidget {
  final bool isLoading;
  final bool shared;
  final VoidCallback onPressed;
  final VoidCallback? onSharedAnimationEnd;

  const ShareSubmitBar({
    super.key,
    required this.isLoading,
    required this.onPressed,
    this.shared = false,
    this.onSharedAnimationEnd,
  });

  static const successDuration = Duration(milliseconds: 1300);

  @override
  State<ShareSubmitBar> createState() => _ShareSubmitBarState();
}

class _ShareSubmitBarState extends State<ShareSubmitBar>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: ShareSubmitBar.successDuration,
  )..addListener(_hapticOnCheck);
  bool _hapticDone = false;

  @override
  void didUpdateWidget(ShareSubmitBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shared && !oldWidget.shared) {
      _controller.forward(from: 0).whenComplete(() {
        if (mounted) widget.onSharedAnimationEnd?.call();
      });
    }
  }

  void _hapticOnCheck() {
    if (!_hapticDone && _controller.value >= 0.45) {
      _hapticDone = true;
      HapticFeedback.mediumImpact();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const height = AppDimensions.buttonHeightLarge;
    final busy = widget.isLoading || widget.shared;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
        AppDimensions.spacing16,
        AppDimensions.spacing8,
        AppDimensions.spacing16,
        AppDimensions.spacing16,
      ),
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, constraints) => AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              double seg(double a, double b, [Curve c = Curves.easeInOut]) =>
                  c.transform(((t - a) / (b - a)).clamp(0.0, 1.0));
              final fade = seg(0, 0.18); // yazı söner
              final shrink = seg(0.18, 0.48, Curves.easeInOutCubic);
              final pop = seg(0.42, 0.72, Curves.elasticOut);
              final ring = seg(0.5, 0.95, Curves.easeOutCubic);

              final width = lerpDouble(constraints.maxWidth, height, shrink)!;
              final radius = lerpDouble(
                AppDimensions.radiusLarge,
                height / 2,
                shrink,
              )!;

              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  if (ring > 0 && ring < 1)
                    Container(
                      width: height * (1 + ring),
                      height: height * (1 + ring),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.primary.withValues(
                            alpha: 1 - ring,
                          ),
                          width: 3 * (1 - ring) + 1,
                        ),
                      ),
                    ),
                  Semantics(
                    button: true,
                    enabled: !busy,
                    child: SizedBox(
                      width: width,
                      height: height,
                      child: Material(
                        color: colorScheme.primary,
                        elevation: 2,
                        shadowColor: colorScheme.primary.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(radius),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: busy ? null : widget.onPressed,
                          child: shrink == 0
                              ? _Label(
                                  isLoading: widget.isLoading && !widget.shared,
                                  opacity: 1 - fade,
                                )
                              : Transform.scale(
                                  scale: pop,
                                  child: Icon(
                                    Icons.check_rounded,
                                    size: AppDimensions.iconXLarge,
                                    color: colorScheme.onPrimary,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final bool isLoading;
  final double opacity;

  const _Label({required this.isLoading, required this.opacity});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onPrimary = theme.colorScheme.onPrimary;
    return Opacity(
      opacity: opacity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox.square(
            dimension: AppDimensions.iconDefault,
            child: isLoading
                ? Padding(
                    padding: const EdgeInsets.all(AppDimensions.spacing2),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: onPrimary,
                    ),
                  )
                : Icon(Icons.send_rounded, color: onPrimary),
          ),
          const SizedBox(width: AppDimensions.spacing8),
          Text(
            AppLocalizations.of(context)!.share,
            style: theme.textTheme.titleMedium?.copyWith(
              color: onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
