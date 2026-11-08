import 'package:dentigo/core/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_dimensions.dart';
import '../widgets/login_background.dart';

/// Açılış ekranı: kayıtlı oturumun profili yüklenirken görünür, sonra router
/// akışa, kayda ya da girişe yönlendirir.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          const RepaintBoundary(child: LoginBackground()),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/logo_tooth.png',
                  height: 96,
                  excludeFromSemantics: true,
                ),
                const SizedBox(height: AppDimensions.spacing24),
                Text(
                  AppLocalizations.of(context)!.appName,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacing32),
                const SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
