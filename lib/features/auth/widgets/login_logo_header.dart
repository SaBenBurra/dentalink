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

    final glassBgColor = isDark
        ? Colors.black.withValues(alpha: 0.4)
        : Colors.white.withValues(alpha: 0.6);
    final glassBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.8);
    final textPrimaryColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondaryColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Column(
      children: [
        // Logo dairesi
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: glassBgColor,
            border: Border.all(color: glassBorderColor, width: 1),
            boxShadow: const [
              BoxShadow(
                color: AppColors.glassShadow,
                blurRadius: 40,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: CustomPaint(
              size: const Size(48, 48),
              painter: ToothPainter(
                colors: [
                  isDark ? AppColors.primaryLight : const Color(0xFF13B9A5),
                  isDark ? AppColors.secondaryLight : const Color(0xFF3B82F6),
                ],
              ),
            ),
          ),
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
                        'DentLink',
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: textPrimaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacing8),
                      Text(
                        'E-posta veya telefon numaranızla giriş yapın',
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
                        'Doğrulama Kodu',
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: textPrimaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacing8),
                      Text(
                        '$inputText adresine gönderilen kodu girin',
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

/// Diş logosu çizen CustomPainter.
class ToothPainter extends CustomPainter {
  final List<Color> colors;

  ToothPainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width * 0.5, size.height * 0.28);
    path.cubicTo(
      size.width * 0.38,
      size.height * 0.12,
      size.width * 0.12,
      size.height * 0.15,
      size.width * 0.18,
      size.height * 0.45,
    );
    path.cubicTo(
      size.width * 0.20,
      size.height * 0.60,
      size.width * 0.22,
      size.height * 0.85,
      size.width * 0.32,
      size.height * 0.88,
    );
    path.cubicTo(
      size.width * 0.36,
      size.height * 0.89,
      size.width * 0.44,
      size.height * 0.75,
      size.width * 0.50,
      size.height * 0.75,
    );
    path.cubicTo(
      size.width * 0.56,
      size.height * 0.75,
      size.width * 0.64,
      size.height * 0.89,
      size.width * 0.68,
      size.height * 0.88,
    );
    path.cubicTo(
      size.width * 0.78,
      size.height * 0.85,
      size.width * 0.80,
      size.height * 0.60,
      size.width * 0.82,
      size.height * 0.45,
    );
    path.cubicTo(
      size.width * 0.88,
      size.height * 0.15,
      size.width * 0.62,
      size.height * 0.12,
      size.width * 0.50,
      size.height * 0.28,
    );

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
