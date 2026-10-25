import 'package:flutter/material.dart';
import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/glass_theme.dart';

/// E-posta veya telefon numarası giriş alanı.
///
/// Glassmorphism stilinde input field + animasyonlu devam butonu.
/// Geçerli bir e-posta/telefon girildiğinde sağ tarafta ok butonu belirir.
class LoginEmailPhoneInput extends StatelessWidget {
  const LoginEmailPhoneInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.showContinueButton,
    this.errorText,
    required this.onContinue,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final bool showContinueButton;
  final String? errorText;
  final VoidCallback onContinue;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final glassBgColor = GlassTheme.getBgColor(context);
    final glassBorderColor = GlassTheme.getBorderColor(context);

    final hasFocus = focusNode.hasFocus;
    final hasError = errorText != null;

    Color borderColor = glassBorderColor;
    Color bgOpacityColor = glassBgColor;

    if (hasError) {
      borderColor = AppColors.error.withValues(alpha: 0.8);
      bgOpacityColor = AppColors.error.withValues(alpha: isDark ? 0.08 : 0.03);
    } else if (hasFocus) {
      borderColor = Theme.of(context).colorScheme.primary;
      bgOpacityColor = const Color(
        0xFF13B9A5,
      ).withValues(alpha: isDark ? 0.15 : 0.08);
    }

    return Column(
      key: const ValueKey('email_phone_field'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedContainer(
          duration: AppDimensions.animFast,
          height: AppDimensions.buttonHeightLarge,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            color: bgOpacityColor,
            border: Border.all(color: borderColor, width: hasFocus ? 1.5 : 1.0),
            boxShadow: hasFocus
                ? [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              enableSuggestions: false,
              style: AppTextStyles.bodyLarge.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.loginInputHint,
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.lightIcon.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Icon(
                  Icons.alternate_email_rounded,
                  color: hasFocus && !hasError
                      ? Theme.of(context).colorScheme.primary
                      : (hasError ? AppColors.error : AppColors.lightIcon),
                  size: AppDimensions.iconMedium,
                ),
                suffixIcon: _buildSuffixIcon(context),
                filled: true,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: AppDimensions.spacing16,
                ),
              ),
              // resizeToAvoidBottomInset kapalı; klavye scroll'u ekran
              // seviyesinde yönetiliyor. Küçük bir tampon yeterli.
              scrollPadding: const EdgeInsets.only(bottom: 24),
              onSubmitted: onSubmitted,
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppDimensions.spacing8),
          Padding(
            padding: const EdgeInsets.only(left: AppDimensions.spacing8),
            child: Text(
              errorText!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSuffixIcon(BuildContext context) {
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.all(AppDimensions.spacing12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
          ),
        ),
      );
    }

    return AnimatedScale(
      scale: showContinueButton ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      child: AnimatedOpacity(
        opacity: showContinueButton ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacing6),
          child: Material(
            color: Theme.of(context).colorScheme.primary,
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: AppLocalizations.of(context)!.loginButton,
              icon: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 18,
              ),
              onPressed: showContinueButton ? onContinue : null,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ),
        ),
      ),
    );
  }
}
