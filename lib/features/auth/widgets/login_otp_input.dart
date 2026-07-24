import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';

/// OTP doğrulama kodu giriş alanı.
///
/// Rakamlar sırayla yukarı/aşağıdan kayarak girer.
/// Hatalı doğrulamada rakamlar dağılma efektiyle kaybolur.
class LoginOtpInput extends StatefulWidget {
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
    required this.onScatterComplete,
    this.errorText,
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
  final VoidCallback onScatterComplete;
  final String? errorText;

  @override
  State<LoginOtpInput> createState() => _LoginOtpInputState();
}

class _LoginOtpInputState extends State<LoginOtpInput>
    with TickerProviderStateMixin {
  static const _brandTeal = Color(0xFF13B9A5);

  static const _scatterOffsets = [
    Offset(-42, -16),
    Offset(38, -22),
    Offset(-46, 14),
    Offset(44, -12),
    Offset(-40, 20),
    Offset(48, 18),
  ];

  static const _scatterRotations = [-0.35, 0.3, 0.4, -0.32, 0.38, -0.42];

  /// Kutulardan satır merkezine doğru birleşme ofsetleri.
  static const _mergeOffsets = [
    Offset(110, 0),
    Offset(66, 0),
    Offset(22, 0),
    Offset(-22, 0),
    Offset(-66, 0),
    Offset(-110, 0),
  ];

  late final AnimationController _scatterController;
  late final AnimationController _successController;
  late List<String> _displayDigits;
  bool _scattering = false;
  bool _succeeding = false;

  @override
  void initState() {
    super.initState();
    _displayDigits = widget.otpControllers.map((c) => c.text).toList();
    for (final controller in widget.otpControllers) {
      controller.addListener(_syncDigits);
    }
    _scatterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          widget.onScatterComplete();
          setState(() {
            _scattering = false;
            _displayDigits = List.filled(widget.otpControllers.length, '');
          });
          _scatterController.reset();
        }
      });
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
  }

  @override
  void didUpdateWidget(LoginOtpInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.errorText == null &&
        widget.errorText != null &&
        !_scattering &&
        !_succeeding) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _beginScatter();
      });
    }
    if (!oldWidget.isSuccess && widget.isSuccess && !_succeeding) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _beginSuccess();
      });
    }
  }

  @override
  void dispose() {
    for (final controller in widget.otpControllers) {
      controller.removeListener(_syncDigits);
    }
    _scatterController.dispose();
    _successController.dispose();
    super.dispose();
  }

  void _syncDigits() {
    if (_scattering || _succeeding || !mounted) return;
    setState(() {
      _displayDigits = widget.otpControllers.map((c) => c.text).toList();
    });
  }

  void _beginScatter() {
    final hasDigits = _displayDigits.any((d) => d.isNotEmpty);
    if (!hasDigits) {
      widget.onScatterComplete();
      return;
    }
    setState(() => _scattering = true);
    _scatterController.forward(from: 0);
  }

  void _beginSuccess() {
    HapticFeedback.mediumImpact();
    setState(() => _succeeding = true);
    _successController.forward(from: 0);
  }

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

    final showSuccess = widget.isSuccess || _succeeding;

    return Column(
      key: const ValueKey('otp_fields_container'),
      children: [
        if (showSuccess)
          _OtpSuccessCelebration(
            animation: _successController,
            digits: _displayDigits,
            mergeOffsets: _mergeOffsets,
            brandColor: _brandTeal,
          )
        else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(widget.otpControllers.length, (index) {
              return _OtpDigitBox(
                index: index,
                digit: _displayDigits[index],
                controller: widget.otpControllers[index],
                focusNode: widget.otpFocusNodes[index],
                hasError: widget.errorText != null,
                isDark: isDark,
                glassBgColor: glassBgColor,
                glassBorderColor: glassBorderColor,
                textPrimaryColor: textPrimaryColor,
                scattering: _scattering,
                scatterAnimation: _scatterController,
                scatterOffset: _scatterOffsets[index % _scatterOffsets.length],
                scatterRotation:
                    _scatterRotations[index % _scatterRotations.length],
                enabled: !_scattering && !widget.isLoading,
                onChanged: (val) => widget.onOtpChanged(val, index),
              );
            }),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final slide = Tween<Offset>(
                  begin: const Offset(0, -0.2),
                  end: Offset.zero,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(position: slide, child: child),
                );
              },
              child: widget.errorText == null
                  ? const SizedBox.shrink(key: ValueKey('otp_error_empty'))
                  : Padding(
                      key: ValueKey(widget.errorText),
                      padding: const EdgeInsets.only(
                        top: AppDimensions.spacing12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: AppDimensions.iconSmall,
                            color: AppColors.error.withValues(alpha: 0.9),
                          ),
                          const SizedBox(width: AppDimensions.spacing6),
                          Flexible(
                            child: Text(
                              widget.errorText!,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
        const SizedBox(height: AppDimensions.spacing24),
        if (!showSuccess) ...[
          if (widget.isLoading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(_brandTeal),
              ),
            )
          else
            TextButton(
              onPressed: widget.canResend ? widget.onResend : null,
              child: Text(
                widget.canResend
                    ? 'Kodu Tekrar Gönder'
                    : 'Kodu Tekrar Gönder (${widget.resendCountdown}s)',
                style: TextStyle(
                  color: widget.canResend ? _brandTeal : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(height: AppDimensions.spacing16),
          TextButton.icon(
            onPressed: widget.onGoBack,
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

/// Başarılı doğrulama: rakamlar merkeze birleşir → check + halka + metin.
class _OtpSuccessCelebration extends StatelessWidget {
  const _OtpSuccessCelebration({
    required this.animation,
    required this.digits,
    required this.mergeOffsets,
    required this.brandColor,
  });

  final Animation<double> animation;
  final List<String> digits;
  final List<Offset> mergeOffsets;
  final Color brandColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final mergeT = const Interval(
          0.0,
          0.42,
          curve: Curves.easeInCubic,
        ).transform(animation.value);
        final checkT = const Interval(
          0.28,
          0.72,
          curve: Curves.elasticOut,
        ).transform(animation.value);
        final ringT = const Interval(
          0.32,
          0.85,
          curve: Curves.easeOutCubic,
        ).transform(animation.value);
        final textT = const Interval(
          0.52,
          0.82,
          curve: Curves.easeOutCubic,
        ).transform(animation.value);

        final digitStyle = AppTextStyles.titleLarge.copyWith(
          color: brandColor,
          fontWeight: FontWeight.bold,
          height: 1.0,
        );

        return SizedBox(
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Birleşen OTP kutuları
              Opacity(
                opacity: (1.0 - mergeT).clamp(0.0, 1.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(digits.length, (index) {
                    final pulse = 1.0 + (0.12 * math.sin(mergeT * math.pi));
                    return Transform.translate(
                      offset: mergeOffsets[index % mergeOffsets.length] * mergeT,
                      child: Transform.scale(
                        scale: pulse * (1.0 - 0.25 * mergeT),
                        child: Container(
                          width: 48,
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: brandColor.withValues(
                              alpha: 0.12 + (0.1 * mergeT),
                            ),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusMedium,
                            ),
                            border: Border.all(
                              color: brandColor,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            digits[index],
                            style: digitStyle,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Yayılan halka
              if (ringT > 0)
                Opacity(
                  opacity: (1.0 - ringT).clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.55 + (ringT * 1.15),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: brandColor.withValues(alpha: 0.45),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),

              // Check ikonu
              if (checkT > 0)
                Transform.scale(
                  scale: checkT.clamp(0.0, 1.0),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: brandColor.withValues(alpha: 0.12),
                      border: Border.all(color: brandColor, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: brandColor.withValues(alpha: 0.25),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 40,
                      color: brandColor,
                    ),
                  ),
                ),

              // Metin
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: textT.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, 8 * (1.0 - textT)),
                    child: Text(
                      'Giriş Yapıldı!',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: brandColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OtpDigitBox extends StatelessWidget {
  const _OtpDigitBox({
    required this.index,
    required this.digit,
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.isDark,
    required this.glassBgColor,
    required this.glassBorderColor,
    required this.textPrimaryColor,
    required this.scattering,
    required this.scatterAnimation,
    required this.scatterOffset,
    required this.scatterRotation,
    required this.enabled,
    required this.onChanged,
  });

  final int index;
  final String digit;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final bool isDark;
  final Color glassBgColor;
  final Color glassBorderColor;
  final Color textPrimaryColor;
  final bool scattering;
  final Animation<double> scatterAnimation;
  final Offset scatterOffset;
  final double scatterRotation;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final hasFocus = focusNode.hasFocus;
    final fromTop = index.isEven;

    final digitStyle = AppTextStyles.titleLarge.copyWith(
      color: textPrimaryColor,
      fontWeight: FontWeight.bold,
      height: 1.0,
    );

    return RepaintBoundary(
      child: AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      width: 48,
      height: 56,
      decoration: BoxDecoration(
        color: hasError
            ? AppColors.error.withValues(alpha: isDark ? 0.12 : 0.06)
            : glassBgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: hasError
              ? AppColors.error.withValues(alpha: 0.85)
              : hasFocus
                  ? const Color(0xFF13B9A5)
                  : glassBorderColor,
          width: hasError || hasFocus ? 2.0 : 1.0,
        ),
      ),
      child: Stack(
        clipBehavior: scattering ? Clip.none : Clip.hardEdge,
        alignment: Alignment.center,
        children: [
          // Scatter yalnızca hata anında çalışır. Normal durumda (klavye
          // açma/kapama gibi sık rebuild'ler dahil) scatterAnimation'ı
          // dinlemeyiz; böylece klavye insets değişimi bu kutu için
          // gereksiz repaint tetiklemez.
          if (scattering)
            AnimatedBuilder(
              animation: scatterAnimation,
              builder: (context, child) {
                final t = Curves.easeInCubic.transform(scatterAnimation.value);
                return Opacity(
                  opacity: (1.0 - t).clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: scatterOffset * t,
                    child: Transform.rotate(
                      angle: scatterRotation * t * math.pi,
                      child: Transform.scale(
                        scale: 1.0 - (0.35 * t),
                        child: child,
                      ),
                    ),
                  ),
                );
              },
              child: Text(digit, style: digitStyle),
            )
          else
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.hardEdge,
                  children: [
                    ...previousChildren,
                    ?currentChild,
                  ],
                );
              },
              transitionBuilder: (child, animation) {
                final offsetAnimation = Tween<Offset>(
                  begin: Offset(0, fromTop ? -1.1 : 1.1),
                  end: Offset.zero,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  ),
                );
              },
              child: digit.isEmpty
                  ? const SizedBox.shrink(key: ValueKey('empty'))
                  : Text(
                      digit,
                      key: ValueKey('digit-$index-$digit'),
                      style: digitStyle,
                    ),
            ),
          TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            keyboardType: TextInputType.number,
            textInputAction: index == 5
                ? TextInputAction.done
                : TextInputAction.next,
            textAlign: TextAlign.center,
            textAlignVertical: TextAlignVertical.center,
            showCursor: true,
            cursorColor: const Color(0xFF13B9A5),
            style: digitStyle.copyWith(color: Colors.transparent),
            // resizeToAvoidBottomInset kapalı; scroll ekran seviyesinde
            // yönetiliyor, küçük tampon yeterli.
            scrollPadding: const EdgeInsets.only(bottom: 24),
            maxLength: 1,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              counterText: '',
              filled: true,
              fillColor: Colors.transparent,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: onChanged,
          ),
        ],
      ),
      ),
    );
  }
}
