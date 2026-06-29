import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../data/datasources/mock_datasource.dart';

enum LoginStep { emailOrPhone, otp }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _inputController = TextEditingController();
  final _inputFocusNode = FocusNode();

  // OTP Controllers & FocusNodes
  final List<TextEditingController> _otpControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());

  LoginStep _currentStep = LoginStep.emailOrPhone;
  bool _showContinueButton = false;
  bool _isLoading = false;
  bool _isSuccess = false;
  bool _isRegisteredUser = false;
  String? _errorText;

  // Shake animation controller
  late AnimationController _shakeController;

  // Timer for OTP resend
  Timer? _resendTimer;
  int _resendCountdown = 59;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _inputFocusNode.addListener(() => setState(() {}));
    _inputController.addListener(_onInputChanged);

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocusNode.dispose();
    _shakeController.dispose();
    _resendTimer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onInputChanged() {
    final text = _inputController.text.trim();
    // Validate if email format or phone format (digits only, minimum length 8)
    final isEmail = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(text);
    final isPhone = RegExp(r'^\+?[0-9]{8,15}$').hasMatch(text);

    setState(() {
      _showContinueButton = isEmail || isPhone;
    });
  }

  double _getShakeOffset(double progress) {
    final double sine = double.parse((progress * 3 * 3.14159).toString());
    return 8 *
        double.parse((progress < 0.5 ? progress : 1.0 - progress).toString()) *
        double.parse((sine >= 0 ? 1 : -1).toString());
  }

  void _startResendTimer() {
    setState(() {
      _resendCountdown = 59;
      _canResend = false;
    });
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown == 0) {
        setState(() {
          _canResend = true;
          _resendTimer?.cancel();
        });
      } else {
        setState(() {
          _resendCountdown--;
        });
      }
    });
  }

  void _handleContinue() {
    if (_isLoading) return;
    _clearError();

    final inputVal = _inputController.text.trim().toLowerCase();

    setState(() {
      _isLoading = true;
    });

    // Simulate database lookup
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;

      // Check if user is registered in MockDatasource
      _isRegisteredUser =
          MockDatasource.users.any(
            (u) => u.email.toLowerCase() == inputVal || u.phone == inputVal,
          ) ||
          inputVal.contains('test') ||
          inputVal.endsWith('@dentlink.com') ||
          inputVal == '5551234567';

      setState(() {
        _isLoading = false;
        _currentStep = LoginStep.otp;
      });
      _startResendTimer();
      // Focus first OTP field after frame renders
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _otpFocusNodes[0].requestFocus();
      });
    });
  }

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 3) {
        _otpFocusNodes[index + 1].requestFocus();
      } else {
        _otpFocusNodes[index].unfocus();
        _verifyOtp(); // Auto-verify when 4 digits are completed
      }
    } else {
      if (index > 0) {
        _otpFocusNodes[index - 1].requestFocus();
      }
    }
  }

  void _verifyOtp() {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 4) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate OTP validation
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      // Any 4 digit code is accepted in mock
      setState(() {
        _isSuccess = true;
      });

      // Navigate based on registration status
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          if (_isRegisteredUser) {
            context.go('/feed');
          } else {
            context.go('/register');
          }
        }
      });
    });
  }

  void _clearError() {
    if (_errorText != null) {
      setState(() {
        _errorText = null;
      });
    }
  }

  void _goBack() {
    setState(() {
      _currentStep = LoginStep.emailOrPhone;
      _clearError();
    });
    // Focus main input after transition
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inputFocusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark
        ? const Color(0xFF11211F)
        : AppColors.bgGradientStart;
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

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // 1. Background Gradients and Decorative Blurred Circles
          if (!isDark)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.bgGradientStart,
                      AppColors.bgGradientEnd,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),

          Positioned(
            left: -100,
            top: -100,
            width: 300,
            height: 300,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? AppColors.primaryLight : AppColors.primary)
                    .withValues(alpha: isDark ? 0.08 : 0.12),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: const SizedBox.shrink(),
              ),
            ),
          ),

          Positioned(
            right: -100,
            bottom: -100,
            width: 350,
            height: 350,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? AppColors.secondaryLight : AppColors.secondary)
                    .withValues(alpha: isDark ? 0.06 : 0.10),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                child: const SizedBox.shrink(),
              ),
            ),
          ),

          // 2. Main Scrollable Container
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacing24,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                      maxWidth: AppDimensions.maxContentWidth,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppDimensions.maxContentWidth,
                        ),
                        child: AnimatedBuilder(
                          animation: _shakeController,
                          builder: (context, child) {
                            final shakeVal = _shakeController.value;
                            final offset = _getShakeOffset(shakeVal);
                            return Transform.translate(
                              offset: Offset(offset, 0),
                              child: child,
                            );
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: AppDimensions.spacing32),
                              // Tooth Logo Circle Panel
                              _buildLogoHeader(
                                isDark,
                                glassBgColor,
                                glassBorderColor,
                              ),
                              const SizedBox(height: AppDimensions.spacing24),

                              // Dynamic Header (Giriş Yap vs Doğrulama Kodu)
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: _currentStep == LoginStep.emailOrPhone
                                    ? Column(
                                        key: const ValueKey(
                                          'email_phone_header',
                                        ),
                                        children: [
                                          Text(
                                            'DentLink',
                                            style: AppTextStyles.headlineMedium
                                                .copyWith(
                                                  color: textPrimaryColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          const SizedBox(
                                            height: AppDimensions.spacing8,
                                          ),
                                          Text(
                                            'E-posta veya telefon numaranızla giriş yapın',
                                            style: AppTextStyles.bodyMedium
                                                .copyWith(
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
                                            style: AppTextStyles.headlineMedium
                                                .copyWith(
                                                  color: textPrimaryColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          const SizedBox(
                                            height: AppDimensions.spacing8,
                                          ),
                                          Text(
                                            '${_inputController.text.trim()} adresine gönderilen kodu girin',
                                            style: AppTextStyles.bodyMedium
                                                .copyWith(
                                                  color: textSecondaryColor,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                              ),

                              const SizedBox(height: AppDimensions.spacing40),

                              // Form Steps with switcher
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0.1, 0),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  );
                                },
                                child: _currentStep == LoginStep.emailOrPhone
                                    ? _buildEmailPhoneInput(
                                        isDark,
                                        glassBgColor,
                                        glassBorderColor,
                                      )
                                    : _buildOtpInput(
                                        isDark,
                                        glassBgColor,
                                        glassBorderColor,
                                      ),
                              ),

                              const SizedBox(height: AppDimensions.spacing32),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoHeader(
    bool isDark,
    Color glassBgColor,
    Color glassBorderColor,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
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
      ),
    );
  }

  Widget _buildEmailPhoneInput(
    bool isDark,
    Color glassBgColor,
    Color glassBorderColor,
  ) {
    final hasFocus = _inputFocusNode.hasFocus;
    final hasError = _errorText != null;

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
              child: Center(
                child: TextField(
                  controller: _inputController,
                  focusNode: _inputFocusNode,
                  keyboardType: TextInputType.emailAddress,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'E-posta veya telefon numarası',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.lightIcon.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: Icon(
                      Icons.alternate_email_rounded,
                      color: hasFocus && !hasError
                          ? const Color(0xFF13B9A5)
                          : (hasError ? AppColors.error : AppColors.lightIcon),
                      size: AppDimensions.iconMedium,
                    ),
                    suffixIcon: _isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(AppDimensions.spacing12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF13B9A5),
                                ),
                              ),
                            ),
                          )
                        : AnimatedScale(
                            scale: _showContinueButton ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutBack,
                            child: AnimatedOpacity(
                              opacity: _showContinueButton ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: Padding(
                                padding: const EdgeInsets.all(
                                  AppDimensions.spacing6,
                                ),
                                child: Material(
                                  color: const Color(0xFF13B9A5),
                                  shape: const CircleBorder(),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    onPressed: _showContinueButton
                                        ? _handleContinue
                                        : null,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 36,
                                      minHeight: 36,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: AppDimensions.spacing16,
                    ),
                  ),
                  onSubmitted: (_) {
                    if (_showContinueButton) _handleContinue();
                  },
                ),
              ),
            ),
          ),
        ),
        if (_errorText != null) ...[
          const SizedBox(height: AppDimensions.spacing8),
          Padding(
            padding: const EdgeInsets.only(left: AppDimensions.spacing8),
            child: Text(
              _errorText!,
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

  Widget _buildOtpInput(
    bool isDark,
    Color glassBgColor,
    Color glassBorderColor,
  ) {
    final textPrimaryColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    return Column(
      key: const ValueKey('otp_fields_container'),
      children: [
        if (_isSuccess)
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
                    color: _otpFocusNodes[index].hasFocus
                        ? const Color(0xFF13B9A5)
                        : glassBorderColor,
                    width: _otpFocusNodes[index].hasFocus ? 2.0 : 1.0,
                  ),
                ),
                child: Center(
                  child: TextField(
                    controller: _otpControllers[index],
                    focusNode: _otpFocusNodes[index],
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
                    onChanged: (val) => _onOtpChanged(val, index),
                  ),
                ),
              );
            }),
          ),
        const SizedBox(height: AppDimensions.spacing24),
        if (!_isSuccess) ...[
          if (_isLoading)
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
              onPressed: _canResend ? _startResendTimer : null,
              child: Text(
                _canResend
                    ? 'Kodu Tekrar Gönder'
                    : 'Kodu Tekrar Gönder (${_resendCountdown}s)',
                style: TextStyle(
                  color: _canResend ? const Color(0xFF13B9A5) : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(height: AppDimensions.spacing16),
          TextButton.icon(
            onPressed: _goBack,
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
