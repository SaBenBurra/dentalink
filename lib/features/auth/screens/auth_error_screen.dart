import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../providers/auth_provider.dart';

/// Oturum var ama profil yüklenemedi (ağ/sunucu hatası).
///
/// Bu durum "profil yok" ile karıştırılmamalı; aksi halde mevcut kullanıcı
/// kayıt ekranına atılır (AUDIT AUTH-1). Router, yükleme düzelince
/// kullanıcıyı otomatik olarak /feed'e taşır.
class AuthErrorScreen extends ConsumerWidget {
  const AuthErrorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacing24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_rounded, size: 64, color: theme.colorScheme.error),
                const SizedBox(height: AppDimensions.spacing16),
                Text(
                  l10n.authProfileLoadError,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppDimensions.spacing24),
                FilledButton(
                  onPressed: () => ref.invalidate(authProvider),
                  child: Text(l10n.retry),
                ),
                TextButton(
                  onPressed: () => ref.read(authProvider.notifier).signOut(),
                  child: Text(l10n.settingsLogout),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
