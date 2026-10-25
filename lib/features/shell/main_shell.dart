import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:go_router/go_router.dart';
import '../../providers/message_provider.dart';
import '../../shared/widgets/app_bottom_nav_bar.dart';

/// Alt menünün görünürlük animasyonu (1 = görünür, 0 = gizli; yay 0–1 dışına
/// taşabilir). Üst barlar bunu izleyerek alt menüyle aynı karede kayar.
final bottomBarAnimationProvider = Provider<ProxyAnimation>(
  (ref) => ProxyAnimation(kAlwaysCompleteAnimation),
);

/// Ana shell — go_router ShellRoute tarafından sarılır.
/// [child] parametresi aktif sekme ekranıdır.
///
/// Tab → Route eşlemesi:
///   0 → /feed
///   1 → /search
///   2 → (create sheet — route yok)
///   3 → /messages
///   4 → /profile
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: BottomBar(
        layout: BottomBarLayout(
          width: MediaQuery.of(context).size.width - 32,
          borderRadius: BorderRadius.circular(28),
          offset: 12,
          clip: Clip.none,
        ),
        motion: const BottomBarMotion.cupertino(
          preset: BottomBarCupertinoMotion.snappy,
          duration: Duration(milliseconds: 400),
          transitionBuilder: _barTransition,
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
                color: colorScheme.primary.withValues(
                  alpha: isDark ? 0.08 : 0.04,
                ),
                blurRadius: 40,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        showIcon: false,
        // Yüzen bar içeriğin üstünde durur; listeler son öğeyi barın üstüne
        // kaydırabilsin diye bar yüksekliği alt boşluk (MediaQuery) olarak verilir.
        body: Builder(
          builder: (context) => ValueListenableBuilder<double>(
            valueListenable: BottomBarScope.of(context).barHeight,
            builder: (context, barHeight, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: MediaQuery.paddingOf(
                  context,
                ).copyWith(bottom: barHeight),
              ),
              child: child!,
            ),
            child: SizedBox.expand(child: child),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: AppBottomNavBar(
            currentIndex: _currentIndex(context),
            onTap: (index) => _onNavTap(context, index),
            onCreateTap: () => showCreatePostSheet(context),
            unreadMessages: ref.watch(totalUnreadMessagesProvider),
          ),
        ),
      ),
    );
  }

  /// Paketin varsayılan kayma geçişi; ayrıca barın animasyonunu
  /// [bottomBarAnimationProvider]'a bağlar. Statik: motion eşitliği sabit kalsın.
  static Widget _barTransition(
    BuildContext context,
    Animation<double> animation,
    Widget child,
  ) {
    final proxy = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(bottomBarAnimationProvider);
    if (proxy.parent != animation) proxy.parent = animation;
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 2),
        end: Offset.zero,
      ).animate(animation),
      child: child,
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
