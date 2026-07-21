import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Login ekranı arka planı — gradient + dekoratif bulanık daireler.
class LoginBackground extends StatelessWidget {
  const LoginBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Light tema gradient arka plan
        if (!isDark)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.bgGradientStart, AppColors.bgGradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

        // Sol üst dekoratif daire
        Positioned(
          left: -100,
          top: -100,
          width: 300,
          height: 300,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isDark ? AppColors.primaryLight : AppColors.primary)
                        .withValues(alpha: isDark ? 0.08 : 0.12),
                    (isDark ? AppColors.primaryLight : AppColors.primary)
                        .withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Sağ alt dekoratif daire
        Positioned(
          right: -100,
          bottom: -100,
          width: 350,
          height: 350,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isDark ? AppColors.secondaryLight : AppColors.secondary)
                        .withValues(alpha: isDark ? 0.06 : 0.10),
                    (isDark ? AppColors.secondaryLight : AppColors.secondary)
                        .withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
