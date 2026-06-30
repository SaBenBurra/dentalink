import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/app_bottom_nav_bar.dart';

/// Ana shell — go_router ShellRoute tarafından sarılır.
/// [child] parametresi aktif sekme ekranıdır.
///
/// Tab → Route eşlemesi:
///   0 → /feed
///   1 → /search
///   2 → (create sheet — route yok)
///   3 → /messages
///   4 → /profile
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: BottomBar(
        layout: BottomBarLayout(
          width: MediaQuery.of(context).size.width - 32,
          borderRadius: BorderRadius.circular(28),
          offset: 12,
          fit: StackFit.expand,
          clip: Clip.none,
        ),
        motion: const BottomBarMotion.cupertino(
          preset: BottomBarCupertinoMotion.snappy,
          duration: Duration(milliseconds: 400),
        ),
        scrollBehavior: const BottomBarScrollBehavior(
          hideOnScroll: true,
          deltaThreshold: 12,
        ),
        theme: BottomBarThemeData(
          barDecoration: BoxDecoration(
            color: isDark
                ? colorScheme.surface.withValues(alpha: 0.92)
                : colorScheme.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.06),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: -2,
              ),
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: isDark ? 0.08 : 0.04),
                blurRadius: 40,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        showIcon: false,
        body: child,
        child: AppBottomNavBar(
          currentIndex: _currentIndex(context),
          onTap: (index) => _onNavTap(context, index),
          onCreateTap: () => showCreatePostSheet(context),
        ),
      ),
    );
  }

  /// Aktif route'a göre seçili sekme indeksini döndürür.
  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/messages')) return 3;
    if (location.startsWith('/profile')) return 4;
    // /feed ya da root → 0
    return 0;
  }

  void _onNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/feed');
      case 1:
        context.go('/search');
      case 3:
        context.go('/messages');
      case 4:
        context.go('/profile');
    }
  }
}
