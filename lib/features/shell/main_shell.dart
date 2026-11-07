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

/// Barların açılıp kapanma yayı; feed üst barı da sekme kaydırırken aynısını
/// kullanır.
/// Alt menüyü koddan göstermek için (kaydırılamayan sayfada geri getirme).
final bottomBarControllerProvider = Provider<BottomBarController>((ref) {
  final controller = BottomBarController();
  ref.onDispose(controller.dispose);
  return controller;
});

const barMotionPreset = BottomBarCupertinoMotion.snappy;
const barMotionDuration = Duration(milliseconds: 400);

/// Ana shell — go_router StatefulShellRoute tarafından sarılır.
/// [navigationShell] sekmeleri canlı tutan IndexedStack'tir.
///
/// Tab → Route eşlemesi:
///   0 → /feed
///   1 → /search
///   2 → (create sheet — route yok)
///   3 → /messages
///   4 → /profile
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Klavye açıkken bar klavyenin arkasında kalır; sekme içindeki sayfalar
    // (ör. post sayfasındaki yorum alanı) klavyeye göre kendileri yerleşir.
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: BottomBar(
        controller: ref.watch(bottomBarControllerProvider),
        layout: BottomBarLayout(
          width: MediaQuery.of(context).size.width - 32,
          borderRadius: BorderRadius.circular(28),
          offset: 12,
          clip: Clip.none,
        ),
        motion: const BottomBarMotion.cupertino(
          preset: barMotionPreset,
          duration: barMotionDuration,
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
                padding: keyboardOpen
                    ? MediaQuery.paddingOf(context)
                    : MediaQuery.paddingOf(context).copyWith(bottom: barHeight),
              ),
              child: child!,
            ),
            // İçerik kaydırılamayacak kadar kısaldıysa (ör. boş liste) gizli
            // bar bir daha kaydırmayla açılamaz; burada geri getirilir.
            child: NotificationListener<ScrollMetricsNotification>(
              onNotification: (n) {
                final m = n.metrics;
                if (m.axis == Axis.vertical &&
                    m.maxScrollExtent <= m.minScrollExtent) {
                  ref.read(bottomBarControllerProvider).show();
                }
                return false;
              },
              child: SizedBox.expand(child: navigationShell),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: AppBottomNavBar(
            currentIndex: _currentIndex,
            onTap: _onNavTap,
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

  /// Alt menü indeksi (2 = oluştur, route yok) ↔ shell branch indeksi.
  static const _branchOfTab = {0: 0, 1: 1, 3: 2, 4: 3};

  int get _currentIndex => _branchOfTab.entries
      .firstWhere((e) => e.value == navigationShell.currentIndex)
      .key;

  void _onNavTap(int index) {
    final branch = _branchOfTab[index];
    if (branch == null) return;
    // Aktif sekmeye tekrar dokunmak o sekmenin köküne döner.
    navigationShell.goBranch(
      branch,
      initialLocation: branch == navigationShell.currentIndex,
    );
  }
}
