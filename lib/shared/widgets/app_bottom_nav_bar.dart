import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// DentLink ana bottom navigation bar.
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

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        if (index == 2) {
          onCreateTap();
        } else {
          onTap(index);
        }
      },
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Ana Sayfa',
        ),
        const NavigationDestination(
          icon: Icon(Icons.explore_outlined),
          selectedIcon: Icon(Icons.explore_rounded),
          label: 'Keşfet',
        ),
        NavigationDestination(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.add_rounded,
              color: colorScheme.onPrimary,
              size: 22,
            ),
          ),
          selectedIcon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.add_rounded,
              color: colorScheme.onPrimary,
              size: 22,
            ),
          ),
          label: 'Oluştur',
        ),
        const NavigationDestination(
          icon: Icon(Icons.chat_bubble_outline_rounded),
          selectedIcon: Icon(Icons.chat_bubble_rounded),
          label: 'Mesajlar',
        ),
        const NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Profil',
        ),
      ],
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
          const SizedBox(height: 20),
          Text(
            'Ne paylaşmak istersin?',
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Klinik vakalarını ve sorularını paylaşarak topluluğa katkı sağla.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Vaka Oluştur
          _CreateOptionTile(
            icon: Icons.medical_information_outlined,
            iconColor: colorScheme.primary,
            iconBg: colorScheme.primaryContainer.withValues(alpha: 0.3),
            title: 'Vaka Paylaş',
            subtitle: 'Klinik vakalarını görsellerle paylaş, meslektaşlarından görüş al.',
            onTap: () {
              Navigator.pop(context);
              context.push('/create-case');
            },
          ),
          const SizedBox(height: 12),

          // Soru Sor
          _CreateOptionTile(
            icon: Icons.help_outline_rounded,
            iconColor: colorScheme.secondary,
            iconBg: colorScheme.secondaryContainer.withValues(alpha: 0.3),
            title: 'Soru Sor',
            subtitle: 'Mesleki sorularını toplulukla paylaş, en iyi cevabı bul.',
            onTap: () {
              Navigator.pop(context);
              context.push('/create-question');
            },
          ),
          const SizedBox(height: 8),
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
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
