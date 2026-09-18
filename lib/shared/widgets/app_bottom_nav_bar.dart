import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dentlink/core/constants/app_dimensions.dart';

/// DentLink ana floating bottom navigation bar.
///
/// 5 sekme:
///   0 — Ana Sayfa (Feed)
///   1 — Keşfet (Search)
///   2 — Oluştur (+) — showModalBottomSheet tetikler
///   3 — Mesajlar
///   4 — Profil
///
/// Ortadaki (index 2) "+" sekmesi normal navigasyon yapmaz;
/// bunun yerine [onCreateTap] callback'ini çağırır.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onCreateTap,
  });

  /// Seçili sekme indeksi (0–4, 2 hariç).
  final int currentIndex;

  /// Sekme değiştiğinde çağrılır. index == 2 buraya gelmez.
  final ValueChanged<int> onTap;

  /// Ortadaki "+" butonuna tıklandığında çağrılır.
  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // 0 — Ana Sayfa
        _NavItem(
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_rounded,
          label: 'Ana Sayfa',
          selected: currentIndex == 0,
          color: isDark ? Colors.white60 : Colors.black54,
          selectedColor: colorScheme.primary,
          onTap: () => onTap(0),
        ),

        // 1 — Keşfet
        _NavItem(
          icon: Icons.explore_outlined,
          selectedIcon: Icons.explore_rounded,
          label: 'Keşfet',
          selected: currentIndex == 1,
          color: isDark ? Colors.white60 : Colors.black54,
          selectedColor: colorScheme.primary,
          onTap: () => onTap(1),
        ),

        // 2 — Oluştur (+) — Özel buton
        _CreateButton(
          colorScheme: colorScheme,
          onTap: onCreateTap,
        ),

        // 3 — Mesajlar
        _NavItem(
          icon: Icons.chat_bubble_outline_rounded,
          selectedIcon: Icons.chat_bubble_rounded,
          label: 'Mesajlar',
          selected: currentIndex == 3,
          color: isDark ? Colors.white60 : Colors.black54,
          selectedColor: colorScheme.primary,
          onTap: () => onTap(3),
        ),

        // 4 — Profil
        _NavItem(
          icon: Icons.person_outline_rounded,
          selectedIcon: Icons.person_rounded,
          label: 'Profil',
          selected: currentIndex == 4,
          color: isDark ? Colors.white60 : Colors.black54,
          selectedColor: colorScheme.primary,
          onTap: () => onTap(4),
        ),
      ],
    );
  }
}

/// Tek bir navigasyon öğesi.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.color,
    required this.selectedColor,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final Color color;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = selected ? selectedColor : color;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? selectedIcon : icon,
                size: 24,
                color: effectiveColor,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: effectiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ortadaki "+" oluştur butonu.
class _CreateButton extends StatelessWidget {
  const _CreateButton({
    required this.colorScheme,
    required this.onTap,
  });

  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacing8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary,
              colorScheme.primary.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(Icons.add_rounded, color: colorScheme.onPrimary, size: 22),
      ),
    );
  }
}

/// "Oluştur" bottom sheet — Vaka veya Soru seçimi.
void showCreatePostSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => const _CreatePostSheet(),
    isScrollControlled: true,
    useSafeArea: true,
  );
}

class _CreatePostSheet extends StatelessWidget {
  const _CreatePostSheet();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spacing20),
          Text('Ne paylaşmak istersin?', style: textTheme.titleLarge),
          const SizedBox(height: AppDimensions.spacing8),
          Text(
            'Klinik vakalarını ve sorularını paylaşarak topluluğa katkı sağla.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppDimensions.spacing24),

          // Vaka Oluştur
          _CreateOptionTile(
            icon: Icons.medical_information_outlined,
            iconColor: colorScheme.primary,
            iconBg: colorScheme.primaryContainer.withValues(alpha: 0.3),
            title: 'Vaka Paylaş',
            subtitle:
                'Klinik vakalarını görsellerle paylaş, meslektaşlarından görüş al.',
            onTap: () {
              Navigator.pop(context);
              context.push('/create-case');
            },
          ),
          const SizedBox(height: AppDimensions.spacing12),

          // Soru Sor
          _CreateOptionTile(
            icon: Icons.help_outline_rounded,
            iconColor: colorScheme.secondary,
            iconBg: colorScheme.secondaryContainer.withValues(alpha: 0.3),
            title: 'Soru Sor',
            subtitle:
                'Mesleki sorularını toplulukla paylaş, en iyi cevabı bul.',
            onTap: () {
              Navigator.pop(context);
              context.push('/create-question');
            },
          ),
          const SizedBox(height: AppDimensions.spacing8),
        ],
      ),
    );
  }
}

class _CreateOptionTile extends StatelessWidget {
  const _CreateOptionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacing16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusLarge,
                  ),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: AppDimensions.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.titleSmall),
                    const SizedBox(height: AppDimensions.spacing2),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.spacing8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
