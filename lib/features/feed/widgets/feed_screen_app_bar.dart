import 'package:dentlink/core/constants/app_dimensions.dart';
import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'package:dentlink/features/feed/widgets/feed_filter_segments.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/notification_provider.dart';

/// Feed üst barı: logo, tür segmentleri, arama ve bildirim.
class FeedScreenAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FeedScreenAppBar({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  // Alt çizgiyle birlikte 56dp (Material toolbar); alt menüyle (~58dp) dengeli.
  static const double _height = 55;
  static const double _iconPad = (48 - AppDimensions.iconMedium) / 2;

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
          child: Container(
            height: _height + 1,
            // 20dp ikonun 48dp alanında iki yanda 14dp payı var; sol kenar da 14dp.
            padding: const EdgeInsets.only(left: _iconPad),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colorScheme.surfaceContainerHigh),
              ),
            ),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.spacing8,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'D', // marka monogramı, çevrilmez
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacing8),
                Expanded(
                  child: FeedFilterSegments(
                    labels: labels,
                    selectedIndex: selectedIndex,
                    onSelected: onSelected,
                  ),
                ),
                // Arama ikonu 48dp alanının sağına yaslı (sağ payı 2dp):
                // segment-arama 10+26 = 36dp, arama-zil 2+14 = 16dp.
                const SizedBox(width: AppDimensions.spacing10),
                _HeaderIconButton(
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
    );
  }
}

/// Çerçevesiz 20dp ikon; dokunma alanı 48x48.
class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
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
    return _HeaderIconButton(
      icon: Icons.notifications_none_rounded,
      tooltip: AppLocalizations.of(context)!.notificationsTitle,
      showDot: unread > 0,
      onTap: () => context.push('/notifications'),
    );
  }
}
