import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../providers/app_version_provider.dart';

/// Feed üstünde "Yeni sürüm var" şeridi (062). Kapatma o `latest_version` için
/// saklanır; daha yeni sürüm yayınlanınca yeniden görünür.
class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final check = ref.watch(versionCheckProvider).valueOrNull;
    final config = check?.config;
    final dismissed = ref.watch(dismissedUpdateProvider);
    if (check?.status != AppVersionStatus.updateAvailable ||
        config == null ||
        dismissed == config.latestVersion) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final storeUrl = config.storeUrl;
    return Material(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
          start: AppDimensions.spacing16,
        ),
        child: Row(
          children: [
            Icon(
              Icons.system_update_rounded,
              size: 20,
              color: colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: AppDimensions.spacing8),
            Expanded(
              child: Text(
                l10n.updateAvailableBanner,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            // Mağaza bağlantısı yoksa (iOS kaydı açılmadan) buton gizli.
            if (storeUrl != null)
              TextButton(
                onPressed: () => launchUrl(
                  Uri.parse(storeUrl),
                  mode: LaunchMode.externalApplication,
                ),
                child: Text(l10n.updateAvailableAction),
              ),
            IconButton(
              tooltip: l10n.close,
              icon: Icon(
                Icons.close_rounded,
                color: colorScheme.onPrimaryContainer,
              ),
              onPressed: () => ref
                  .read(dismissedUpdateProvider.notifier)
                  .dismiss(config.latestVersion),
            ),
          ],
        ),
      ),
    );
  }
}
