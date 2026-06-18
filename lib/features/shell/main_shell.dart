import 'package:flutter/material.dart';
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
    return Scaffold(
      body: child,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex(context),
        onTap: (index) => _onNavTap(context, index),
        onCreateTap: () => showCreatePostSheet(context),
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
