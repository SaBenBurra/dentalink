import 'package:dentlink/core/constants/app_colors.dart';
import 'package:dentlink/core/constants/app_dimensions.dart';
import 'package:dentlink/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';

class RegisterHeader extends StatelessWidget {
  const RegisterHeader({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.prevStep,
    required this.nextStep,
  });

  final int currentStep;
  final int totalSteps;
  final void Function() prevStep;
  final void Function() nextStep;

  @override
  Widget build(BuildContext context) {
    final progress = (currentStep + 1) / totalSteps;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimaryColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacing24,
        vertical: AppDimensions.spacing16,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: textPrimaryColor,
                  size: 20,
                ),
                onPressed: () => prevStep,
              ),
              Text(
                'Kayıt Ol',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textPrimaryColor,
                ),
              ),
              Opacity(
                opacity: currentStep > 0 ? 1.0 : 0.0,
                child: TextButton(
                  onPressed: currentStep > 0 ? () => nextStep : null,
                  child: const Text(
                    'Geç',
                    style: TextStyle(
                      color: Color(0xFF13B9A5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing16),
          // Progress bar
          Stack(
            children: [
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 6,
                width: MediaQuery.of(context).size.width * progress - 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF13B9A5), Color(0xFF3B82F6)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF13B9A5).withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                getStepTitle(),
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Adım ${currentStep + 1} / $totalSteps',
                style: AppTextStyles.bodySmall.copyWith(
                  color: const Color(0xFF13B9A5),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String getStepTitle() {
    switch (currentStep) {
      case 0:
        return 'Temel Bilgiler';
      case 1:
        return 'Mesleki Bilgiler';
      case 2:
        return 'Profil Detayları';
      default:
        return '';
    }
  }
}
