import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';

/// OTP doğrulama kodu giriş alanı.
///
/// 4 haneli OTP kutuları + tekrar gönder butonu + geri butonu.
/// Başarılı doğrulama sonrası yeşil onay ikonu gösterir.
class LoginOtpInput extends StatelessWidget {
  const LoginOtpInput({
    super.key,
    required this.otpControllers,
    required this.otpFocusNodes,
    required this.isLoading,
    required this.isSuccess,
    required this.canResend,
    required this.resendCountdown,
    required this.onOtpChanged,
    required this.onResend,
    required this.onGoBack,
  });

  final List<TextEditingController> otpControllers;
  final List<FocusNode> otpFocusNodes;
  final bool isLoading;
  final bool isSuccess;
  final bool canResend;
  final int resendCountdown;
  final void Function(String value, int index) onOtpChanged;
  final VoidCallback onResend;
  final VoidCallback onGoBack;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final glassBgColor = isDark
        ? Colors.black.withValues(alpha: 0.4)
        : Colors.white.withValues(alpha: 0.6);
    final glassBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.8);
    final textPrimaryColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    return Column(
      key: const ValueKey('otp_fields_container'),
      children: [
        if (isSuccess)
          const Column(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
              SizedBox(height: AppDimensions.spacing16),
              Text(
                'Giriş Yapıldı!',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(4, (index) {
              return Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: glassBgColor,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusMedium,
                  ),
                  border: Border.all(
                    color: otpFocusNodes[index].hasFocus
                        ? const Color(0xFF13B9A5)
                        : glassBorderColor,
                    width: otpFocusNodes[index].hasFocus ? 2.0 : 1.0,
                  ),
                ),
                child: Center(
                  child: TextField(
                    controller: otpControllers[index],
                    focusNode: otpFocusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: textPrimaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLength: 1,
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                    ),
                    onChanged: (val) => onOtpChanged(val, index),
                  ),
                ),
              );
            }),
          ),
        const SizedBox(height: AppDimensions.spacing24),
        if (!isSuccess) ...[
          if (isLoading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF13B9A5)),
              ),
            )
          else
            TextButton(
              onPressed: canResend ? onResend : null,
              child: Text(
                canResend
                    ? 'Kodu Tekrar Gönder'
                    : 'Kodu Tekrar Gönder (${resendCountdown}s)',
                style: TextStyle(
                  color: canResend ? const Color(0xFF13B9A5) : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(height: AppDimensions.spacing16),
          TextButton.icon(
            onPressed: onGoBack,
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: const Text('E-posta/Telefon Değiştir'),
            style: TextButton.styleFrom(
              foregroundColor: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ],
    );
  }
}
