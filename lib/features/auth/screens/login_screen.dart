import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../data/repositories/otp_cooldown_exception.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/login_background.dart';
import '../widgets/login_logo_header.dart';
import '../widgets/login_email_phone_input.dart';
import '../widgets/login_otp_input.dart';

enum LoginStep { emailOrPhone, otp }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  // ── Controllers ──────────────────────────────────────────────────────────
  final _inputController = TextEditingController();
  final _inputFocusNode = FocusNode();

  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  // ── State ────────────────────────────────────────────────────────────────
  LoginStep _currentStep = LoginStep.emailOrPhone;
  bool _showContinueButton = false;
  bool _isLoading = false;
  bool _isSuccess = false;
  bool _isRegisteredUser = false;
  String? _errorText;

  // ── Animations ───────────────────────────────────────────────────────────
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  // ── Timer ────────────────────────────────────────────────────────────────
  static const _otpCooldownSeconds = 59;
  Timer? _resendTimer;
  int _resendCountdown = _otpCooldownSeconds;
  bool _canResend = false;

  // ── Regex patterns (pre-compiled) ────────────────────────────────────────
  static final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  static final _phoneRegex = RegExp(r'^\+?[0-9]{8,15}$');

  // ── Geçiş süreleri (tek merkez) ──────────────────────────────────────────
  static const _stepTransitionDuration = Duration(milliseconds: 420);
  static const _stepTransitionCurve = Curves.easeOutCubic;

  // Klavyenin kapanma animasyonunun tamamlanması için beklenen süre. Bu süre
  // dolmadan step değiştirilmez; böylece klavye insets değişimi (layout kayması)
  // ile step geçiş animasyonu ASLA çakışmaz.
  static const _keyboardDismissDelay = Duration(milliseconds: 300);

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
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
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
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final node in _otpFocusNodes) {
      node.removeListener(_onFocusChanged);
      node.dispose();
    }
    super.dispose();
  }

  // ── Event handlers ───────────────────────────────────────────────────────

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

  void _handleContinue() async {
    if (_isLoading) return;
    _clearError();
    final inputVal = _inputController.text.trim();
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).sendOtp(inputVal);
      if (!mounted) return;
      _enterOtpStep(countdownSeconds: _otpCooldownSeconds);
    } on OtpCooldownException catch (e) {
      if (!mounted) return;
      if (e.sameDestination) {
        // Aynı numara/e-posta: yeni SMS atma, kalan süreyle OTP ekranına dön.
        _enterOtpStep(countdownSeconds: e.remainingSeconds);
      } else {
        setState(() {
          _isLoading = false;
          _errorText =
              'Çok sık deneme yaptınız. ${e.remainingSeconds} saniye sonra tekrar deneyin.';
        });
      }
    } catch (e) {
      debugPrint(e.toString());
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = 'Bir hata oluştu. Lütfen tekrar deneyin.';
      });
    }
  }

  void _enterOtpStep({required int countdownSeconds}) {
    for (final controller in _otpControllers) {
      controller.clear();
    }
    _startResendTimer(fromSeconds: countdownSeconds);
    _switchStep(
      LoginStep.otp,
      targetFocusNode: _otpFocusNodes[0],
      applyState: () {
        _isLoading = false;
        _isSuccess = false;
        _isRegisteredUser = false;
        _errorText = null;
      },
    );
  }

  /// İki adım arasında pürüzsüz geçiş yapar.
  ///
  /// Akış:
  /// 1. Klavye açıksa kapat ve kapanma animasyonu bitene kadar bekle. Böylece
  ///    step geçiş animasyonu, klavye insets değişiminden (layout kayması)
  ///    tamamen bağımsız, stabil bir layout üzerinde akar.
  /// 2. Step'i değiştir → AnimatedSize/AnimatedSwitcher geçişi çalışır.
  /// 3. Geçiş animasyonu bitince hedef alana odaklan → klavye açılır (email
  ///    için QWERTY, OTP için numerik). Geçiş bittiği için çakışma olmaz.
  ///
  /// Aynı mantık her iki yön için de (email→otp ve otp→email) kullanılır;
  /// böylece iki geçiş de simetrik ve smooth olur.
  void _switchStep(
    LoginStep target, {
    required FocusNode targetFocusNode,
    VoidCallback? applyState,
  }) {
    final keyboardWasOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    // 1. Odağı bırak (klavye kapanmaya başlar).
    FocusScope.of(context).unfocus();

    // Klavye açıktıysa kapanma animasyonunu bekle; değilse hemen geç.
    final wait = keyboardWasOpen ? _keyboardDismissDelay : Duration.zero;

    Future.delayed(wait, () {
      if (!mounted) return;
      // 2. Step'i değiştir.
      setState(() {
        applyState?.call();
        _currentStep = target;
      });
      // 3. Step geçişi bitince hedef alana odaklan (klavye tekrar açılır).
      Future.delayed(_stepTransitionDuration, () {
        if (mounted && _currentStep == target) {
          targetFocusNode.requestFocus();
        }
      });
    });
  }

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty) {
      _clearError();
      if (index < 5) {
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

  void _verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 6) return;
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      // verifyOtp artık hata durumunda fırlatıyor; başarılıysa kullanıcıyı
      // (veya yeni kullanıcı için null) döndürüyor. Böylece doğrulama
      // başarısız olduğunda catch bloğu çalışır ve kullanıcı oturumsuz
      // şekilde kayıt ekranına yönlendirilmez.
      final user = await ref
          .read(authProvider.notifier)
          .verifyOtp(_inputController.text.trim(), otp);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isSuccess = true;
        _isRegisteredUser = user != null;
      });
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) {
          if (user != null) {
            context.go('/feed');
          } else {
            context.go('/register');
          }
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = 'Kod hatalı veya süresi dolmuş';
      });
      _shakeController.forward(from: 0);
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
    if (!_canResend || _isLoading) return;
    _clearError();
    setState(() => _isLoading = true);
    try {
      await ref
          .read(authProvider.notifier)
          .sendOtp(_inputController.text.trim());
      if (!mounted) return;
      setState(() => _isLoading = false);
      _startResendTimer(fromSeconds: _otpCooldownSeconds);
    } on OtpCooldownException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _startResendTimer(fromSeconds: e.remainingSeconds);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = 'Kod gönderilemedi. Lütfen tekrar deneyin.';
      });
    }
  }

  void _startResendTimer({int fromSeconds = _otpCooldownSeconds}) {
    final start = fromSeconds.clamp(0, _otpCooldownSeconds);
    setState(() {
      _resendCountdown = start;
      _canResend = start == 0;
    });
    _resendTimer?.cancel();
    if (start == 0) return;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown <= 1) {
        setState(() {
          _resendCountdown = 0;
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
    _switchStep(
      LoginStep.emailOrPhone,
      targetFocusNode: _inputFocusNode,
      applyState: () {
        _errorText = null;
        _isSuccess = false;
        _isRegisteredUser = false;
        _isLoading = false;
      },
    );
  }

  // ── Shake animation helper ──────────────────────────────────────────────
  //
  // 0→1 ilerleme boyunca 3 kez sağa-sola sönümlenerek salınır.
  double _shakeOffset(double t) {
    // Sönümlenen sinüs: genlik başta yüksek, sona doğru sıfıra iner.
    const amplitude = 10.0;
    final decay = 1.0 - t;
    return math.sin(t * math.pi * 6) * amplitude * decay;
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF11211F)
        : AppColors.bgGradientStart;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // 1. Arka plan. Statik olduğu için RepaintBoundary ile izole
          //    ediyoruz; klavye insets değişiminde (layout kayması) gereksiz
          //    yere yeniden boyanmasını engeller.
          const RepaintBoundary(child: LoginBackground()),

          // 2. Ana içerik.
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
                          child: _buildContent(),
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

  Widget _buildContent() {
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

          // Logo + başlık (kendi içinde step'e göre yumuşak geçiş yapar).
          LoginLogoHeader(
            currentStep: _currentStep,
            inputText: _inputController.text.trim(),
            transitionDuration: _stepTransitionDuration,
          ),

          const SizedBox(height: AppDimensions.spacing40),

          // Form adımları.
          //
          // AnimatedSize iki adımın farklı yükseklikleri arasında yumuşak
          // geçiş yapar. AnimatedSwitcher içerikleri fade+slide ile
          // değiştirir. Her iki yön (email→otp ve otp→email) için aynı
          // süre/eğri kullanıldığından geçiş simetrik ve smooth olur.
          AnimatedSize(
            duration: _stepTransitionDuration,
            curve: _stepTransitionCurve,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: _stepTransitionDuration,
              switchInCurve: _stepTransitionCurve,
              switchOutCurve: Curves.easeInCubic,
              // Çıkan çocuk boyuta dahil edilmez; yalnızca yeni yükseklik
              // AnimatedSize tarafından animasyonlanır (aksi halde Stack
              // max(eski,yeni) alıp ani zıplama yapar).
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
                // Dikey kaydırma YOK: dikey boyut değişimini yalnızca
                // AnimatedSize yönetir. transitionBuilder sadece fade yapar;
                // böylece iki animasyon dikeyde çakışıp titreme oluşturmaz.
                return FadeTransition(opacity: animation, child: child);
              },
              child: _buildStep(),
            ),
          ),

          const SizedBox(height: AppDimensions.spacing32),
        ],
      ),
    );
  }

  Widget _buildStep() {
    if (_currentStep == LoginStep.emailOrPhone) {
      return LoginEmailPhoneInput(
        key: const ValueKey('email_phone_step'),
        controller: _inputController,
        focusNode: _inputFocusNode,
        isLoading: _isLoading,
        showContinueButton: _showContinueButton,
        errorText: _errorText,
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
      isLoading: _isLoading,
      isSuccess: _isSuccess,
      isRegisteredUser: _isRegisteredUser,
      canResend: _canResend,
      resendCountdown: _resendCountdown,
      errorText: _errorText,
      onOtpChanged: _onOtpChanged,
      onResend: _handleResend,
      onGoBack: _goBack,
      onScatterComplete: _onOtpScatterComplete,
    );
  }
}
