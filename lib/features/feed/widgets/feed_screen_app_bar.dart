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
    return SliverAppBar(
      floating: true,
      pinned: true,
      snap: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.black.withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.92),
          border: Border(bottom: BorderSide(color: glassBorderColor, width: 1)),
        ),
      ),
      title: Text(
        'Dentlink',
        style: textTheme.titleLarge?.copyWith(
          color: isDark
              ? AppColors.darkTextPrimary
              : AppColors.lightTextPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded),
          onPressed: () {
            context.push('/notifications');
          },
          color: colorScheme.primary,
          tooltip: 'Notifications',
        ),
        const SizedBox(width: AppDimensions.spacing8),
      ],
      bottom: TabBar(
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
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing8),
        labelPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacing12,
        ),
        tabs: [
          Tab(text: l10n.feedFilterAll),
          Tab(text: l10n.feedFilterCases),
          Tab(text: l10n.feedFilterQuestions),
        ],
      ),
    );
  }
}
