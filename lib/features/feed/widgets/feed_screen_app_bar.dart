import 'dart:ui' show ImageFilter;

import 'package:dentlink/core/constants/app_colors.dart';
import 'package:dentlink/core/constants/app_dimensions.dart';
import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FeedScreenAppBar extends StatelessWidget {
  const FeedScreenAppBar({
    super.key,
    required this.isDark,
    required this.glassBorderColor,
    required this.textTheme,
    required this.colorScheme,
    required this.tabController,
    required this.l10n,
  });

  final bool isDark;
  final Color glassBorderColor;
  final TextTheme textTheme;
  final ColorScheme colorScheme;
  final TabController tabController;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    // Status bar / notch height - the header must always clear this, both
    // expanded and collapsed, or its content sits under the system icons.
    final double topPadding = MediaQuery.paddingOf(context).top;

    return SliverPersistentHeader(
      pinned: true,
      delegate: _FeedAppBarDelegate(
        isDark: isDark,
        glassBorderColor: glassBorderColor,
        textTheme: textTheme,
        colorScheme: colorScheme,
        tabController: tabController,
        l10n: l10n,
        topPadding: topPadding,
      ),
    );
  }
}

/// Collapsing header for the feed screen.
///
/// On scroll, the "Dentlink" title fades away and the bar morphs from a
/// flush, full-width bar into a floating, rounded "pill". The notification
/// bell is a single widget that glides from beside the title to the end of
/// the tab row - it never fades out/in, it just moves, so nothing appears
/// to vanish and reappear.
///
/// Everything is driven directly by [shrinkOffset] (fed in on every scroll
/// frame), so the transition is tied 1:1 to the user's finger - no separate
/// AnimationController/Tween ticking is needed for it to feel smooth.
class _FeedAppBarDelegate extends SliverPersistentHeaderDelegate {
  _FeedAppBarDelegate({
    required this.isDark,
    required this.glassBorderColor,
    required this.textTheme,
    required this.colorScheme,
    required this.tabController,
    required this.l10n,
    required this.topPadding,
  });

  final bool isDark;
  final Color glassBorderColor;
  final TextTheme textTheme;
  final ColorScheme colorScheme;
  final TabController tabController;
  final AppLocalizations l10n;
  final double topPadding;

  // Tune these to adjust proportions / how quickly the header collapses.
  static const double _titleHeight = 56;
  static const double _barHeight = 52;
  static const double _floatingMarginTop = 8;
  static const double _floatingMarginH = 16;
  static const double _maxBlurSigma = 12;
  static const double _iconBox = 48;
  static const double _iconRightInset = 4;
  static const double _contentLeftPadding = 16;
  static const double _tabTrailingReserve = 56; // clears the bell overlay

  @override
  double get maxExtent => topPadding + _titleHeight + _barHeight;

  @override
  double get minExtent => topPadding + _floatingMarginTop * 2 + _barHeight;

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  // num.clamp() returns num, not double, so a plain .clamp(0.0, 1.0) call
  // won't type-check against double-typed params like opacity/heightFactor.
  static double _clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final double range = maxExtent - minExtent;
    final double progress = range > 0 ? _clamp01(shrinkOffset / range) : 0.0;

    final Color barColor = isDark
        ? Colors.black.withValues(alpha: 0.85)
        : Colors.white.withValues(alpha: 0.92);

    final double horizontalMargin = _lerp(0, _floatingMarginH, progress);
    final double cardTop = topPadding + _lerp(0, _floatingMarginTop, progress);
    final double cardHeight = _lerp(
      _titleHeight + _barHeight,
      _barHeight,
      progress,
    );
    final double tabRowTop = cardTop + cardHeight - _barHeight;
    final BorderRadius radius = BorderRadius.circular(
      _lerp(0, _barHeight / 2, progress),
    );
    final List<BoxShadow> shadow =
        BoxShadow.lerpList(const [], [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ], progress) ??
        const [];

    // Bell glides from the title row's vertical center to the tab row's -
    // one widget, one continuous path, never faded out.
    final double iconCenterY = _lerp(
      topPadding + _titleHeight / 2,
      tabRowTop + _barHeight / 2,
      progress,
    );
    final double iconTop = iconCenterY - _iconBox / 2;
    final double iconRight = horizontalMargin + _iconRightInset;

    // Card background: color + uniform border + rounded corners (+ a
    // frosted blur once it starts floating). A *uniform* Border.all is
    // required here - a non-uniform Border combined with borderRadius
    // throws at paint time.
    final BoxDecoration cardFill = BoxDecoration(
      color: barColor,
      border: Border.all(color: glassBorderColor, width: 1),
      borderRadius: radius,
    );

    final Widget cardBackground = Container(
      decoration: BoxDecoration(borderRadius: radius, boxShadow: shadow),
      child: progress > 0
          ? ClipRRect(
              borderRadius: radius,
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: _lerp(0, _maxBlurSigma, progress),
                  sigmaY: _lerp(0, _maxBlurSigma, progress),
                ),
                child: Container(decoration: cardFill),
              ),
            )
          : Container(decoration: cardFill),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: cardTop,
          left: horizontalMargin,
          right: horizontalMargin,
          height: cardHeight,
          child: cardBackground,
        ),
        Positioned(
          top: tabRowTop,
          left: horizontalMargin + _contentLeftPadding,
          right: horizontalMargin + _tabTrailingReserve,
          height: _barHeight,
          child: TabBar(
            controller: tabController,
            labelColor: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
            unselectedLabelColor: isDark
                ? AppColors.darkTextTertiary
                : AppColors.lightTextTertiary,
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            indicatorColor: colorScheme.primary,
            indicatorWeight: 2.5,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            tabAlignment: TabAlignment.start,
            isScrollable: true,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacing8,
            ),
            labelPadding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacing12,
            ),
            tabs: [
              Tab(text: l10n.feedFilterAll),
              Tab(text: l10n.feedFilterCases),
              Tab(text: l10n.feedFilterQuestions),
            ],
          ),
        ),
        Positioned(
          top: topPadding,
          left: horizontalMargin + _contentLeftPadding,
          right: horizontalMargin + _tabTrailingReserve,
          height: _titleHeight,
          child: IgnorePointer(
            child: Opacity(
              opacity: _clamp01(1 - progress),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Dentlink',
                  style: textTheme.titleLarge?.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: iconTop,
          right: iconRight,
          width: _iconBox,
          height: _iconBox,
          child: IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => context.push('/notifications'),
            color: colorScheme.primary,
            tooltip: 'Notifications',
          ),
        ),
      ],
    );
  }

  @override
  bool shouldRebuild(covariant _FeedAppBarDelegate oldDelegate) {
    return isDark != oldDelegate.isDark ||
        glassBorderColor != oldDelegate.glassBorderColor ||
        textTheme != oldDelegate.textTheme ||
        colorScheme != oldDelegate.colorScheme ||
        tabController != oldDelegate.tabController ||
        l10n != oldDelegate.l10n ||
        topPadding != oldDelegate.topPadding;
  }
}
