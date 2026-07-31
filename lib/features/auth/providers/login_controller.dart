import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/otp_cooldown_exception.dart';
import '../../../providers/auth_provider.dart';
import '../models/login_step.dart';

class LoginState {
  final LoginStep step;
  final bool isLoading;
  final bool isSuccess;
  final String? successMessage;
  final String? errorText;
  final int resendCountdown;
  final bool canResend;
  final bool shouldShake;

  const LoginState({
    this.step = LoginStep.emailOrPhone,
    this.isLoading = false,
    this.isSuccess = false,
    this.successMessage,
    this.errorText,
    this.resendCountdown = 59,
    this.canResend = false,
    this.shouldShake = false,
  });

  LoginState copyWith({
    LoginStep? step,
    bool? isLoading,
    bool? isSuccess,
    String? Function()? successMessage,
    String? Function()? errorText,
    int? resendCountdown,
    bool? canResend,
    bool? shouldShake,
  }) {
    return LoginState(
      step: step ?? this.step,
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      successMessage: successMessage != null
          ? successMessage()
          : this.successMessage,
      errorText: errorText != null ? errorText() : this.errorText,
      resendCountdown: resendCountdown ?? this.resendCountdown,
      canResend: canResend ?? this.canResend,
      shouldShake: shouldShake ?? this.shouldShake,
    );
  }
}

class LoginController extends AutoDisposeNotifier<LoginState> {
  Timer? _resendTimer;
  static const _otpCooldownSeconds = 59;

  @override
  LoginState build() {
    ref.onDispose(() {
      _resendTimer?.cancel();
    });
    return const LoginState();
  }

  void clearError() {
    if (state.errorText != null) {
      state = state.copyWith(errorText: () => null, shouldShake: false);
    }
  }

  Future<void> sendOtp(String inputVal) async {
    if (state.isLoading) return;
    clearError();
    state = state.copyWith(isLoading: true);

    try {
      await ref.read(authProvider.notifier).sendOtp(inputVal);
      _enterOtpStep(countdownSeconds: _otpCooldownSeconds);
    } on OtpCooldownException catch (e) {
      if (e.sameDestination) {
        _enterOtpStep(countdownSeconds: e.remainingSeconds);
      } else {
        state = state.copyWith(
          isLoading: false,
          errorText: () =>
              'Çok sık deneme yaptınız. ${e.remainingSeconds} saniye sonra tekrar deneyin.',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorText: () => e.toString());
    }
  }

  void _enterOtpStep({required int countdownSeconds}) {
    _startResendTimer(fromSeconds: countdownSeconds);
    state = state.copyWith(
      step: LoginStep.otp,
      isLoading: false,
      isSuccess: false,
      successMessage: () => null,
      errorText: () => null,
    );
  }

  Future<bool> verifyOtp(String inputVal, String otp) async {
    if (state.isLoading || state.isSuccess) return false;

    // authRedirectHoldProvider is handled by the UI layer to block routing if needed
    state = state.copyWith(
      isLoading: true,
      errorText: () => null,
      shouldShake: false,
    );

    try {
      final user = await ref
          .read(authProvider.notifier)
          .verifyOtp(inputVal, otp);
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        successMessage: () => user != null ? 'Giriş Yapıldı!' : 'Başarılı',
      );
      return user != null; // returns true if registered user, false if new
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorText: () => 'Kod hatalı veya süresi dolmuş',
        shouldShake: true,
      );
      // Reset shouldShake so it can shake again on next error
      Future.delayed(const Duration(milliseconds: 500), () {
        if (state.errorText != null) {
          state = state.copyWith(shouldShake: false);
        }
      });
      return false;
    }
  }

  Future<void> resendOtp(String inputVal) async {
    if (!state.canResend || state.isLoading || state.isSuccess) return;
    clearError();
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(authProvider.notifier).sendOtp(inputVal);
      state = state.copyWith(isLoading: false);
      _startResendTimer(fromSeconds: _otpCooldownSeconds);
    } on OtpCooldownException catch (e) {
      state = state.copyWith(isLoading: false);
      _startResendTimer(fromSeconds: e.remainingSeconds);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorText: () => 'Kod gönderilemedi. Lütfen tekrar deneyin.',
      );
    }
  }

  void _startResendTimer({int fromSeconds = _otpCooldownSeconds}) {
    final start = fromSeconds.clamp(0, _otpCooldownSeconds);
    _resendTimer?.cancel();

    state = state.copyWith(resendCountdown: start, canResend: start == 0);

    if (start == 0) return;

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.resendCountdown <= 1) {
        timer.cancel();
        state = state.copyWith(resendCountdown: 0, canResend: true);
      } else {
        state = state.copyWith(resendCountdown: state.resendCountdown - 1);
      }
    });
  }

  void goBack() {
    _resendTimer?.cancel();
    state = state.copyWith(
      step: LoginStep.emailOrPhone,
      errorText: () => null,
      isSuccess: false,
      successMessage: () => null,
      isLoading: false,
    );
  }
}

final loginControllerProvider =
    AutoDisposeNotifierProvider<LoginController, LoginState>(() {
      return LoginController();
    });
