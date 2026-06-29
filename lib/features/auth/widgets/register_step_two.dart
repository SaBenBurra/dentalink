import 'package:dentlink/core/constants/app_colors.dart';
import 'package:dentlink/core/constants/app_dimensions.dart';
import 'package:dentlink/core/constants/app_text_styles.dart';
import 'package:dentlink/shared/widgets/glass_field.dart';
import 'package:flutter/material.dart';

class RegisterStepTwo extends StatelessWidget {
  const RegisterStepTwo({
    super.key,
    required this.uniController,
    required this.uniFocusNode,
    required this.cityController,
    required this.cityFocusNode,
    required this.clinicController,
    required this.clinicFocusNode,
    required this.expController,
    required this.expFocusNode,
    required this.isDark,
    required this.textPrimaryColor,
  });

  final TextEditingController uniController;
  final FocusNode uniFocusNode;
  final TextEditingController cityController;
  final FocusNode cityFocusNode;
  final TextEditingController clinicController;
  final FocusNode clinicFocusNode;
  final TextEditingController expController;
  final FocusNode expFocusNode;
  final bool isDark;
  final Color textPrimaryColor;

  @override
  Widget build(BuildContext context) {
    final textSecondaryColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppDimensions.spacing12),
          Text(
            'Mesleki Bilgiler',
            style: AppTextStyles.headlineSmall.copyWith(
              color: textPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.spacing8),
          Text(
            'Profesyonel geçmişinizi doldurarak diş hekimleri ağı ile daha iyi etkileşim kurun (İsteğe bağlı).',
            style: AppTextStyles.bodyMedium.copyWith(color: textSecondaryColor),
          ),
          const SizedBox(height: AppDimensions.spacing24),

          // University
          GlassField(
            controller: uniController,
            focusNode: uniFocusNode,
            hintText: 'Üniversite',
            icon: Icons.school_outlined,
          ),
          const SizedBox(height: AppDimensions.spacing16),

          // City
          GlassField(
            controller: cityController,
            focusNode: cityFocusNode,
            hintText: 'Şehir',
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: AppDimensions.spacing16),

          // Clinic
          GlassField(
            controller: clinicController,
            focusNode: clinicFocusNode,
            hintText: 'Çalıştığı Klinik/Hastane',
            icon: Icons.business_outlined,
          ),
          const SizedBox(height: AppDimensions.spacing16),

          // Experience Years
          GlassField(
            controller: expController,
            focusNode: expFocusNode,
            hintText: 'Deneyim Yılı',
            icon: Icons.trending_up_outlined,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppDimensions.spacing32),
        ],
      ),
    );
  }
}
