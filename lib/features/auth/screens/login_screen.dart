import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../providers/auth_provider.dart';
import '../models/login_step.dart';
import '../providers/login_controller.dart';
import '../widgets/login_background.dart';
import '../widgets/login_email_phone_input.dart';
import '../widgets/login_logo_header.dart';
import '../widgets/login_otp_input.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  static const _otpLength = 6;
  static const _successNavDelay = Duration(milliseconds: 1400);
  static const _stepTransitionDuration = Duration(milliseconds: 420);
  static const _stepTransitionCurve = Curves.easeOutCubic;

  static const _keyboardDismissDelay = Duration(milliseconds: 300);

  static final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  static final _phoneRegex = RegExp(r'^\+?[0-9]{8,15}$');

  final _inputController = TextEditingController();
  final _inputFocusNode = FocusNode();
  final List<TextEditingController> _otpControllers = List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(
    _otpLength,
    (_) => FocusNode(),
  );

  bool _showContinueButton = false;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  Timer? _successNavTimer;
  bool _holdsAuthRedirect = false;
  ProviderContainer? _container;

  @override
  void initState() {
    super.initState();
    _inputFocusNode.addListener(_onFocusChanged);
    _inputController.addListener(_onInputChanged);
    for (final node in _otpFocusNodes) {
      node.addListener(_onFocusChanged);
    }

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _container = ProviderScope.containerOf(context);
  }

  @override
  void dispose() {
    _successNavTimer?.cancel();
    _releaseAuthRedirectHold();

    _inputController.removeListener(_onInputChanged);
    _inputController.dispose();
    _inputFocusNode.removeListener(_onFocusChanged);
    _inputFocusNode.dispose();
    _shakeController.dispose();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final node in _otpFocusNodes) {
      node.removeListener(_onFocusChanged);
      node.dispose();
    }
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  void _onInputChanged() {
    final text = _inputController.text.trim();
    final isValid = _emailRegex.hasMatch(text) || _phoneRegex.hasMatch(text);
    if (_showContinueButton != isValid) {
      setState(() => _showContinueButton = isValid);
    }
  }

  void _setAuthRedirectHold(bool hold) {
    if (_holdsAuthRedirect == hold) return;
    _holdsAuthRedirect = hold;
    final container = _container;
    if (container != null) {
      container.read(authRedirectHoldProvider.notifier).state = hold;
    } else if (mounted) {
      ref.read(authRedirectHoldProvider.notifier).state = hold;
    }
  }

  void _releaseAuthRedirectHold() => _setAuthRedirectHold(false);

  Future<void> _handleContinue() async {
    final state = ref.read(loginControllerProvider);
    if (state.isLoading) return;
    final inputVal = _inputController.text.trim();
    
    // Klavye kapansın
    FocusScope.of(context).unfocus();
    
    await ref.read(loginControllerProvider.notifier).sendOtp(inputVal);
    
    final newState = ref.read(loginControllerProvider);
    if (newState.step == LoginStep.otp) {
      for (final controller in _otpControllers) {
        controller.clear();
      }
      Future.delayed(_keyboardDismissDelay + _stepTransitionDuration, () {
        if (mounted && ref.read(loginControllerProvider).step == LoginStep.otp) {
          _otpFocusNodes[0].requestFocus();
        }
      });
    }
  }

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty) {
      ref.read(loginControllerProvider.notifier).clearError();
      if (index < _otpLength - 1) {
        _otpFocusNodes[index + 1].requestFocus();
      } else {
        _otpFocusNodes[index].unfocus();
        _verifyOtp();
      }
    } else if (index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    final state = ref.read(loginControllerProvider);
    if (otp.length < _otpLength || state.isLoading || state.isSuccess) return;

    _setAuthRedirectHold(true);
    
    final isRegistered = await ref
        .read(loginControllerProvider.notifier)
        .verifyOtp(_inputController.text.trim(), otp);

    if (!mounted) return;

    final newState = ref.read(loginControllerProvider);
    if (newState.isSuccess) {
      _successNavTimer?.cancel();
      _successNavTimer = Timer(_successNavDelay, () {
        if (!mounted) return;
        final destination = isRegistered ? '/feed' : '/register';
        context.go(destination);
        _releaseAuthRedirectHold();
      });
    } else if (newState.errorText != null) {
      _releaseAuthRedirectHold();
    }
  }

  void _onOtpScatterComplete() {
    for (final controller in _otpControllers) {
      controller.clear();
    }
    if (!mounted) return;
    _otpFocusNodes[0].requestFocus();
  }

  Future<void> _handleResend() async {
    await ref.read(loginControllerProvider.notifier).resendOtp(_inputController.text.trim());
  }

  void _goBack() {
    _successNavTimer?.cancel();
    _releaseAuthRedirectHold();
    ref.read(loginControllerProvider.notifier).goBack();
    
    Future.delayed(_stepTransitionDuration, () {
      if (mounted && ref.read(loginControllerProvider).step == LoginStep.emailOrPhone) {
        _inputFocusNode.requestFocus();
      }
    });
  }

  double _shakeOffset(double t) {
    const amplitude = 10.0;
    final decay = 1.0 - t;
    return math.sin(t * math.pi * 6) * amplitude * decay;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF11211F)
        : AppColors.bgGradientStart;
        
    final state = ref.watch(loginControllerProvider);
    
    // Shake listener
    ref.listen<LoginState>(loginControllerProvider, (previous, next) {
      if (next.shouldShake && previous?.shouldShake != true) {
        _shakeController.forward(from: 0);
      }
    });

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          const RepaintBoundary(child: LoginBackground()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacing24,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: AppDimensions.maxContentWidth,
                          ),
                          child: _buildContent(state),
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

  Widget _buildContent(LoginState state) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        final offset = _shakeOffset(_shakeAnimation.value);
        return Transform.translate(offset: Offset(offset, 0), child: child);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppDimensions.spacing32),
          LoginLogoHeader(
            currentStep: state.step,
            inputText: _inputController.text.trim(),
            transitionDuration: _stepTransitionDuration,
          ),
          const SizedBox(height: AppDimensions.spacing40),
          AnimatedSize(
            duration: _stepTransitionDuration,
            curve: _stepTransitionCurve,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: _stepTransitionDuration,
              switchInCurve: _stepTransitionCurve,
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
                return FadeTransition(opacity: animation, child: child);
              },
              child: _buildStep(state),
            ),
          ),
          const SizedBox(height: AppDimensions.spacing32),
        ],
      ),
    );
  }

  Widget _buildStep(LoginState state) {
    if (state.step == LoginStep.emailOrPhone) {
      return LoginEmailPhoneInput(
        key: const ValueKey('email_phone_step'),
        controller: _inputController,
        focusNode: _inputFocusNode,
        isLoading: state.isLoading,
        showContinueButton: _showContinueButton,
        errorText: state.errorText,
        onContinue: _handleContinue,
        onSubmitted: (_) {
          if (_showContinueButton) _handleContinue();
        },
      );
    }
    return LoginOtpInput(
      key: const ValueKey('otp_step'),
      otpControllers: _otpControllers,
      otpFocusNodes: _otpFocusNodes,
      isLoading: state.isLoading,
      isSuccess: state.isSuccess,
      successMessage: state.successMessage ?? 'Başarılı',
      canResend: state.canResend,
      resendCountdown: state.resendCountdown,
      errorText: state.errorText,
      onOtpChanged: _onOtpChanged,
      onResend: _handleResend,
      onGoBack: _goBack,
      onScatterComplete: _onOtpScatterComplete,
    );
  }
}
