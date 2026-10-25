import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/l10n/generated/app_localizations.dart';

/// Detay ekranından geri dön; deep link ile açıldıysa (geri yığını boş) feed'e git.
void popOrGoFeed(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/feed');
  }
}

/// Detay yüklenirken: geri butonu olan boş iskelet.
class PostDetailLoading extends StatelessWidget {
  const PostDetailLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => popOrGoFeed(context))),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}

/// Detay yüklenemedi / yanlış tipte post: kullanıcı ekranda sıkışmaz.
class PostDetailError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const PostDetailError({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => popOrGoFeed(context))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacing24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.onSurfaceVariant),
              const SizedBox(height: AppDimensions.spacing16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: AppDimensions.spacing16),
              if (onRetry != null)
                FilledButton.tonal(onPressed: onRetry, child: Text(l10n.retry)),
              TextButton(
                onPressed: () => popOrGoFeed(context),
                child: Text(l10n.back),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
