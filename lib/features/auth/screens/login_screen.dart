import 'package:dentigo/core/l10n/generated/app_localizations.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/providers/repository_providers.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/contact_utils.dart';
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

  final _inputController = TextEditingController();
  final _inputFocusNode = FocusNode();
  final _otpController = TextEditingController();
  final _otpFocusNode = FocusNode();

  bool _showContinueButton = false;
  String _lastInput = '';
  String? _inputError;

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
    _otpFocusNode.addListener(_onFocusChanged);

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
    _otpController.dispose();
    _otpFocusNode.removeListener(_onFocusChanged);
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  void _onInputChanged() {
    final text = _inputController.text.trim();
    if (text == _lastInput) return;
    _lastInput = text;
    ref.read(loginControllerProvider.notifier).clearError();
    setState(() {
      _inputError = null;
      _showContinueButton = text.isNotEmpty;
    });
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
    if (normalizeContact(inputVal) == null) {
      setState(
        () => _inputError = AppLocalizations.of(
          context,
        )!.validationContactInvalid,
      );
      return;
    }

    // Klavye kapansın
    FocusScope.of(context).unfocus();

    await ref.read(loginControllerProvider.notifier).sendOtp(inputVal);

    final newState = ref.read(loginControllerProvider);
    if (newState.step == LoginStep.otp) {
      _otpController.clear();
      Future.delayed(_keyboardDismissDelay + _stepTransitionDuration, () {
        if (mounted &&
            ref.read(loginControllerProvider).step == LoginStep.otp) {
          _otpFocusNode.requestFocus();
        }
      });
    }
  }

  void _onOtpChanged(String value) {
    ref.read(loginControllerProvider.notifier).clearError();
    if (value.length == _otpLength) {
      _otpFocusNode.unfocus();
      _verifyOtp();
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text;
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
    _otpController.clear();
    if (!mounted) return;
    _otpFocusNode.requestFocus();
  }

  Future<void> _handleResend() async {
    await ref
        .read(loginControllerProvider.notifier)
        .resendOtp(_inputController.text.trim());
  }

  void _goBack() {
    _successNavTimer?.cancel();
    _releaseAuthRedirectHold();
    ref.read(loginControllerProvider.notifier).goBack();

    Future.delayed(_stepTransitionDuration, () {
      if (mounted &&
          ref.read(loginControllerProvider).step == LoginStep.emailOrPhone) {
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
        ? AppColors.darkBackground
        : AppColors.bgGradientStart;

    final state = ref.watch(loginControllerProvider);

    // Shake listener
    ref.listen<LoginState>(loginControllerProvider, (previous, next) {
      if (next.shouldShake && previous?.shouldShake != true) {
        _shakeController.forward(from: 0);
      }
    });

    // Açık oturum geri yüklenirken giriş formu görünmesin. Kod doğrulanırken
    // de oturum vardır; o durumda hold aktiftir ve form kalır.
    final restoringSession =
        ref.watch(authProvider).isLoading &&
        !_holdsAuthRedirect &&
        ref.read(authRepositoryProvider).hasSession;
    if (restoringSession) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: const Stack(
          children: [
            RepaintBoundary(child: LoginBackground()),
            Center(child: CircularProgressIndicator()),
          ],
        ),
      );
    }

    return PopScope(
      canPop: state.step == LoginStep.emailOrPhone,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !state.isLoading && !state.isSuccess) _goBack();
      },
      child: Scaffold(
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
        errorText: _inputError ?? state.errorText,
        onContinue: _handleContinue,
        onSubmitted: (_) {
          if (_showContinueButton) _handleContinue();
        },
      );
    }
    return LoginOtpInput(
      key: const ValueKey('otp_step'),
      otpLength: _otpLength,
      otpController: _otpController,
      otpFocusNode: _otpFocusNode,
      isLoading: state.isLoading,
      isSuccess: state.isSuccess,
      successMessage:
          state.successMessage ?? AppLocalizations.of(context)!.success,
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
