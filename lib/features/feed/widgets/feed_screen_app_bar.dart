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
    required this._tabController,
    required this.l10n,
  });

  final bool isDark;
  final Color glassBorderColor;
  final TextTheme textTheme;
  final ColorScheme colorScheme;
  final TabController _tabController;
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
        'Feed',
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
    );
  }
}
