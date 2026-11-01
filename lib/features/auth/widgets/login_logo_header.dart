import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../models/login_step.dart';

/// Login ekranı logo + dinamik başlık bileşeni.
///
/// [currentStep] değerine göre farklı başlık metni gösterir:
/// - emailOrPhone → "DentLink" + "E-posta veya telefon numaranızla giriş yapın"
/// - otp → "Doğrulama Kodu" + "{adres}e gönderilen kodu girin"
class LoginLogoHeader extends StatelessWidget {
  const LoginLogoHeader({
    super.key,
    required this.currentStep,
    required this.inputText,
    this.transitionDuration = const Duration(milliseconds: 420),
  });

  final LoginStep currentStep;
  final String inputText;

  /// Başlık geçiş süresi. Login ekranındaki form geçişiyle senkron kalması
  /// için tek merkezden verilir.
  final Duration transitionDuration;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textPrimaryColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondaryColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Column(
      children: [
        // Logo (yalnızca diş, saydam arka plan)
        Image.asset(
          'assets/logo_tooth.png',
          height: 96,
          excludeFromSemantics: true,
        ),

        const SizedBox(height: AppDimensions.spacing24),

        // Dinamik başlık
        AnimatedSize(
          duration: transitionDuration,
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: transitionDuration,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            layoutBuilder: (currentChild, previousChildren) {
              return Stack(
                alignment: Alignment.topCenter,
                clipBehavior: Clip.none,
                children: [
                  for (final child in previousChildren)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: IgnorePointer(child: child),
                    ),
                  ?currentChild,
                ],
              );
            },
            transitionBuilder: (child, animation) {
              // Yalnızca fade; dikey boyut değişimini AnimatedSize yönetir.
              return FadeTransition(opacity: animation, child: child);
            },
            child: currentStep == LoginStep.emailOrPhone
                ? Column(
                    key: const ValueKey('email_phone_header'),
                    children: [
                      Text(
                        AppLocalizations.of(context)!.appName,
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: textPrimaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacing8),
                      Text(
                        AppLocalizations.of(context)!.loginHeaderSubtitle,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: textSecondaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : Column(
                    key: const ValueKey('otp_header'),
                    children: [
                      Text(
                        AppLocalizations.of(context)!.verificationCode,
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: textPrimaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacing8),
                      Text(
                        AppLocalizations.of(context)!.otpSentTo(inputText),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: textSecondaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
