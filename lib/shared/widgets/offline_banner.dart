import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_dimensions.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../providers/connectivity_provider.dart';

/// Çevrimdışıyken tüm ekranların üstünde şerit gösterir (MaterialApp.builder).
/// Şerit üst güvenli alanı kendisi kullanır; altındaki sayfa çentik boşluğunu
/// ikinci kez bırakmasın diye üst padding kaldırılır.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(isOnlineProvider);
    final colorScheme = Theme.of(context).colorScheme;
    // Ağaç yapısı sabit kalır; navigator yeniden kurulup yığın kaybolmaz.
    return Column(
      children: [
        if (!online)
          Material(
            color: colorScheme.errorContainer,
            child: SafeArea(
              bottom: false,
              child: Semantics(
                liveRegion: true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacing16,
                    vertical: AppDimensions.spacing8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_off_rounded,
                        size: 18,
                        color: colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: AppDimensions.spacing8),
                      Flexible(
                        child: Text(
                          AppLocalizations.of(context)!.offlineBanner,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: colorScheme.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: !online,
            child: child,
          ),
        ),
      ],
    );
  }
}
