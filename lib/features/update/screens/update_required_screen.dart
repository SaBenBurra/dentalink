import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../providers/app_version_provider.dart';

/// Sürüm `min_supported_version` altındayken (062) tek ekran. Geri tuşu çıkamaz;
/// uygulama ön plana dönünce yeniden kontrol edilir, sürüm yeterliyse router çıkarır.
class UpdateRequiredScreen extends ConsumerWidget {
  const UpdateRequiredScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final storeUrl = ref
        .watch(versionCheckProvider)
        .valueOrNull
        ?.config
        ?.storeUrl;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacing24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.system_update_rounded,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: AppDimensions.spacing16),
                  Text(
                    l10n.updateRequiredTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppDimensions.spacing8),
                  Text(
                    storeUrl == null
                        ? '${l10n.updateRequiredBody}\n\n${l10n.updateRequiredNoStore}'
                        : l10n.updateRequiredBody,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (storeUrl != null) ...[
                    const SizedBox(height: AppDimensions.spacing24),
                    FilledButton(
                      onPressed: () => launchUrl(
                        Uri.parse(storeUrl),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: Text(l10n.updateGoToStore),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
