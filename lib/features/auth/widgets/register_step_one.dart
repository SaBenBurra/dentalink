import 'dart:ui';

import 'package:dentlink/core/constants/app_colors.dart';
import 'package:dentlink/core/constants/app_dimensions.dart';
import 'package:dentlink/core/constants/app_text_styles.dart';
import 'package:dentlink/data/models/enums.dart';
import 'package:dentlink/shared/widgets/glass_field.dart';
import 'package:flutter/material.dart';

class RegisterStepOne extends StatelessWidget {
  const RegisterStepOne({
    super.key,
    required this.nameController,
    required this.nameError,
    required this.nameFocusNode,
    required this.selectedTitle,
    required this.onNameChanged,
    required this.onTitleSelected,
  });
  final TextEditingController nameController;
  final String? nameError;
  final FocusNode nameFocusNode;
  final UserTitle? selectedTitle;

  final ValueChanged<String> onNameChanged;
  final ValueChanged<UserTitle> onTitleSelected;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondaryColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    final textPrimaryColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final glassBgColor = isDark
        ? Colors.black.withValues(alpha: 0.3)
        : Colors.white.withValues(alpha: 0.5);
    final glassBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.white.withValues(alpha: 0.6);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppDimensions.spacing12),
          Text(
            'Sizi Tanıyalım',
            style: AppTextStyles.headlineSmall.copyWith(
              color: textPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.spacing8),
          Text(
            'Lütfen adınızı girin ve uzmanlık alanınızı seçin.',
            style: AppTextStyles.bodyMedium.copyWith(color: textSecondaryColor),
          ),
          const SizedBox(height: AppDimensions.spacing24),

          // Name field
          GlassField(
            controller: nameController,
            focusNode: nameFocusNode,
            hintText: 'Ad Soyad',
            icon: Icons.person_outline_rounded,
            errorText: nameError,
            onChanged: onNameChanged,
          ),

          const SizedBox(height: AppDimensions.spacing32),
          Text(
            'Unvanınız',
            style: AppTextStyles.titleMedium.copyWith(
              color: textPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.spacing12),

          // Grid of Titles
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 3,
            ),
            itemCount: UserTitle.values.length,
            itemBuilder: (context, index) {
              final title = UserTitle.values[index];
              final isSelected = selectedTitle == title;

              return InkWell(
                onTap: () => onTitleSelected(title),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacing12,
                    vertical: AppDimensions.spacing8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark
                              ? const Color(0xFF13B9A5).withValues(alpha: 0.15)
                              : const Color(0xFF13B9A5).withValues(alpha: 0.08))
                        : glassBgColor,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusMedium,
                    ),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF13B9A5)
                          : glassBorderColor,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(
                                0xFF13B9A5,
                              ).withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          title.titleIcon,
                          size: 16,
                          color: isSelected
                              ? const Color(0xFF13B9A5)
                              : (isDark ? Colors.white60 : Colors.black54),
                        ),
                        const SizedBox(width: AppDimensions.spacing8),
                        Expanded(
                          child: Text(
                            title.displayName,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? const Color(0xFF13B9A5)
                                  : textPrimaryColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppDimensions.spacing32),
        ],
      ),
    );
  }
}
