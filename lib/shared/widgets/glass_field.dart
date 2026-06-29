import 'dart:ui';

import 'package:dentlink/core/constants/app_colors.dart';
import 'package:dentlink/core/constants/app_dimensions.dart';
import 'package:dentlink/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';

class GlassField extends StatelessWidget {
  const GlassField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.icon,
    this.errorText,
    this.keyboardType,
    this.maxLines = 1,
    this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final IconData icon;
  final String? errorText;
  final TextInputType? keyboardType;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final hasFocus = focusNode.hasFocus;
    final hasError = errorText != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassBgColor = isDark
        ? Colors.black.withValues(alpha: 0.3)
        : Colors.white.withValues(alpha: 0.5);
    final glassBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.white.withValues(alpha: 0.6);

    Color borderColor = glassBorderColor;
    Color bgOpacityColor = glassBgColor;

    if (hasError) {
      borderColor = AppColors.error.withValues(alpha: 0.8);
      bgOpacityColor = AppColors.error.withValues(alpha: isDark ? 0.08 : 0.03);
    } else if (hasFocus) {
      borderColor = const Color(0xFF13B9A5);
      bgOpacityColor = const Color(
        0xFF13B9A5,
      ).withValues(alpha: isDark ? 0.15 : 0.08);
    }

    return AnimatedContainer(
      duration: AppDimensions.animFast,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        color: bgOpacityColor,
        border: Border.all(color: borderColor, width: hasFocus ? 1.5 : 1.0),
        boxShadow: hasFocus
            ? [
                BoxShadow(
                  color: const Color(0xFF13B9A5).withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            maxLines: maxLines,
            onChanged: onChanged,
            style: AppTextStyles.bodyLarge.copyWith(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.lightIcon.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: maxLines > 1 ? 72.0 : 0.0),
                child: Icon(
                  icon,
                  color: hasFocus && !hasError
                      ? const Color(0xFF13B9A5)
                      : (hasError ? AppColors.error : AppColors.lightIcon),
                  size: AppDimensions.iconMedium,
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: AppDimensions.spacing16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
