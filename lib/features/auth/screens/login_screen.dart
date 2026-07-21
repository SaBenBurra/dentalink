import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../data/datasources/mock_datasource.dart';
import '../widgets/login_background.dart';
import '../widgets/login_logo_header.dart';
import '../widgets/login_email_phone_input.dart';
import '../widgets/login_otp_input.dart';

enum LoginStep { emailOrPhone, otp }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // ── Controllers ──────────────────────────────────────────────────────────
  final _inputController = TextEditingController();
  final _inputFocusNode = FocusNode();

  final List<TextEditingController> _otpControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());

  // ── State ────────────────────────────────────────────────────────────────
  LoginStep _currentStep = LoginStep.emailOrPhone;
  bool _showContinueButton = false;
  bool _isLoading = false;
  bool _isSuccess = false;
  bool _isRegisteredUser = false;
  String? _errorText;

  // ── Animations ───────────────────────────────────────────────────────────
  late AnimationController _shakeController;

  // ── Timer ────────────────────────────────────────────────────────────────
  Timer? _resendTimer;
  int _resendCountdown = 59;
  bool _canResend = false;

  // ── Regex patterns (pre-compiled) ────────────────────────────────────────
  static final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  static final _phoneRegex = RegExp(r'^\+?[0-9]{8,15}$');

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _inputFocusNode.addListener(_onFocusChanged);
    _inputController.addListener(_onInputChanged);

    for (final node in _otpFocusNodes) {
      node.addListener(_onFocusChanged);
    }

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _inputController.removeListener(_onInputChanged);
    _inputController.dispose();
    _inputFocusNode.removeListener(_onFocusChanged);
    _inputFocusNode.dispose();
    _shakeController.dispose();
    _resendTimer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.removeListener(_onFocusChanged);
      node.dispose();
    }
    super.dispose();
  }

  // ── Event handlers ───────────────────────────────────────────────────────

  void _onFocusChanged() => setState(() {});

  void _onInputChanged() {
    final text = _inputController.text.trim();
    final isValid = _emailRegex.hasMatch(text) || _phoneRegex.hasMatch(text);

    if (_showContinueButton != isValid) {
      setState(() => _showContinueButton = isValid);
    }
  }

  void _handleContinue() {
    if (_isLoading) return;
    _clearError();

    final inputVal = _inputController.text.trim().toLowerCase();
    setState(() => _isLoading = true);

    // Simulate database lookup
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;

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
        _verifyOtp();
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

    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });

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
        setState(() => _resendCountdown--);
      }
    });
  }

  void _clearError() {
    if (_errorText != null) {
      setState(() => _errorText = null);
    }
  }

  void _goBack() {
    setState(() {
      _currentStep = LoginStep.emailOrPhone;
      _clearError();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inputFocusNode.requestFocus();
    });
  }

  // ── Shake animation helper ──────────────────────────────────────────────

  double _getShakeOffset(double progress) {
    final double sine = double.parse((progress * 3 * 3.14159).toString());
    return 8 *
        double.parse((progress < 0.5 ? progress : 1.0 - progress).toString()) *
        double.parse((sine >= 0 ? 1 : -1).toString());
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF11211F)
        : AppColors.bgGradientStart;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // 1. Arka plan
          const LoginBackground(),

          // 2. Ana içerik
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
                            final offset = _getShakeOffset(
                              _shakeController.value,
                            );
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

                              // Logo + başlık
                              LoginLogoHeader(
                                currentStep: _currentStep,
                                inputText: _inputController.text.trim(),
                              ),

                              const SizedBox(height: AppDimensions.spacing40),

                              // Form adımları
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
                                    ? LoginEmailPhoneInput(
                                        controller: _inputController,
                                        focusNode: _inputFocusNode,
                                        isLoading: _isLoading,
                                        showContinueButton: _showContinueButton,
                                        errorText: _errorText,
                                        onContinue: _handleContinue,
                                        onSubmitted: (_) {
                                          if (_showContinueButton) {
                                            _handleContinue();
                                          }
                                        },
                                      )
                                    : LoginOtpInput(
                                        otpControllers: _otpControllers,
                                        otpFocusNodes: _otpFocusNodes,
                                        isLoading: _isLoading,
                                        isSuccess: _isSuccess,
                                        canResend: _canResend,
                                        resendCountdown: _resendCountdown,
                                        onOtpChanged: _onOtpChanged,
                                        onResend: _startResendTimer,
                                        onGoBack: _goBack,
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
}
