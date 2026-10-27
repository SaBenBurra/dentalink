import 'package:dentlink/core/constants/app_dimensions.dart';
import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'package:dentlink/features/feed/widgets/feed_filter_segments.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../shared/widgets/user_avatar.dart';

/// Feed üst barı: profil avatarı, tür segmentleri, arama ve bildirim.
class FeedScreenAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FeedScreenAppBar({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.visibility = kAlwaysCompleteAnimation,
    this.position,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// 1 = tam görünür, 0 = yukarı kaymış (durum çubuğu alanı kalır).
  final Animation<double> visibility;

  /// Sayfa konumu (ör. 1.25); verilirse segment göstergesi onu izler.
  final ValueListenable<double>? position;

  // Alt çizgiyle birlikte 56dp (Material toolbar); alt menüyle (~58dp) dengeli.
  static const double _height = 55;
  static const double _iconPad = (48 - AppDimensions.iconMedium) / 2;
  static const double _searchGap = AppDimensions.spacing10;
  // Sekmeler ekranda ortalıya yakın dursun: sağdaki alan (boşluk + iki 48dp
  // ikon) kadar solda da yer bırakılır, ray sonra sola 16dp uzatılır.
  static const double _avatarGap =
      _searchGap + 48 * 2 - _avatarLeftPad - 48 - AppDimensions.spacing16;
  // 32dp avatarın 48dp alanında 8dp payı var; avatar kenardan 14dp görünür.
  static const double _avatarLeftPad = _iconPad - (48 - 32) / 2;

  @override
  Size get preferredSize => const Size.fromHeight(_height + 1); // + alt çizgi

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    // AppBar kullanılmadığı için durum çubuğu ikon rengini kendimiz veriyoruz.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Material(
        color: colorScheme.surface.withValues(alpha: 0.96),
        child: SafeArea(
          bottom: false,
          child: AnimatedBuilder(
            animation: visibility,
            builder: (context, child) {
              final v = visibility.value.clamp(0.0, 1.0);
              // Alta yaslı kırpma: yükseklik azaldıkça bar yukarı kayar.
              return ClipRect(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  heightFactor: v,
                  child: ExcludeSemantics(excluding: v == 0, child: child),
                ),
              );
            },
            child: Container(
              height: _height + 1,
              // 20dp ikonun 48dp alanında iki yanda 14dp payı var; sol kenar da 14dp.
              padding: const EdgeInsets.only(left: _avatarLeftPad),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: colorScheme.surfaceContainerHigh),
                ),
              ),
              child: Row(
                children: [
                  const _ProfileAvatarButton(),
                  const SizedBox(width: _avatarGap),
                  Expanded(
                    child: FeedFilterSegments(
                      labels: labels,
                      selectedIndex: selectedIndex,
                      onSelected: onSelected,
                      position: position,
                    ),
                  ),
                  // Arama ikonu 48dp alanının sağına yaslı (sağ payı 2dp):
                  // segment-arama 10+26 = 36dp, arama-zil 2+14 = 16dp.
                  const SizedBox(width: _searchGap),
                  HeaderIconButton(
                    alignment: Alignment.centerRight,
                    icon: Icons.search_rounded,
                    tooltip: l10n.searchHint,
                    onTap: () => context.go('/search'),
                  ),
                  const _NotificationBell(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Çerçevesiz 20dp ikon; dokunma alanı 48x48.
class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.showDot = false,
    this.alignment = Alignment.center,
  });

  /// İkonun 48dp dokunma alanı içindeki yeri; sağa yaslıysa 2dp pay kalır.
  final Alignment alignment;
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacing2,
              ),
              child: Align(
                alignment: alignment,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      icon,
                      size: AppDimensions.iconMedium,
                      color: colorScheme.onSurface,
                    ),
                    if (showDot)
                      Positioned(
                        top: 0,
                        right: 1,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: colorScheme.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationBell extends ConsumerWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationCountProvider);
    return HeaderIconButton(
      icon: Icons.notifications_none_rounded,
      tooltip: AppLocalizations.of(context)!.notificationsTitle,
      showDot: unread > 0,
      onTap: () => context.push('/notifications'),
    );
  }
}

/// Oturumdaki kullanıcının avatarı; dokununca Profil sekmesine gider.
class _ProfileAvatarButton extends ConsumerWidget {
  const _ProfileAvatarButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return Tooltip(
      message: AppLocalizations.of(context)!.navProfile,
      child: Semantics(
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => context.go('/profile'),
          child: SizedBox.square(
            dimension: 48,
            child: Center(
              child: ExcludeSemantics(
                child: UserAvatar(
                  name: user?.fullName ?? '',
                  imageUrl: user?.avatarUrl,
                  size: AvatarSize.small,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
