import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthApiException;
import '../../../data/repositories/otp_cooldown_exception.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../shared/utils/error_messages.dart';
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
    this.resendCountdown = 60,
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
  // OtpSendLimiter'ın cooldown'uyla (60 sn) aynı olmalı.
  static const _otpCooldownSeconds = 60;
  // shortcut: Riverpod 2'de ref.mounted yok; Riverpod 3'e geçişte (REL-7) onunla değiştir.
  bool _disposed = false;

  @override
  LoginState build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
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
      if (_disposed) return;
      _enterOtpStep(countdownSeconds: _otpCooldownSeconds);
    } on OtpCooldownException catch (e) {
      if (_disposed) return;
      if (e.sameDestination) {
        _enterOtpStep(countdownSeconds: e.remainingSeconds);
      } else {
        state = state.copyWith(
          isLoading: false,
          errorText: () =>
              ref.read(l10nProvider).otpTooManyAttempts(e.remainingSeconds),
        );
      }
    } catch (e) {
      if (_disposed) return;
      state = state.copyWith(
        isLoading: false,
        errorText: () => getErrorMessage(ref.read(l10nProvider), e),
      );
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
      if (_disposed) return false;
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        successMessage: () => user != null
            ? ref.read(l10nProvider).loginSuccess
            : ref.read(l10nProvider).success,
      );
      return user != null; // returns true if registered user, false if new
    } catch (e) {
      if (_disposed) return false;
      state = state.copyWith(
        isLoading: false,
        // Yalnızca sunucunun reddettiği kod "hatalı"; ağ ve profil hataları kendi mesajıyla.
        errorText: () => e is AuthApiException
            ? ref.read(l10nProvider).otpInvalid
            : getErrorMessage(ref.read(l10nProvider), e),
        shouldShake: true,
      );
      // Reset shouldShake so it can shake again on next error
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!_disposed && state.errorText != null) {
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
      if (_disposed) return;
      state = state.copyWith(isLoading: false);
      _startResendTimer(fromSeconds: _otpCooldownSeconds);
    } on OtpCooldownException catch (e) {
      if (_disposed) return;
      state = state.copyWith(isLoading: false);
      _startResendTimer(fromSeconds: e.remainingSeconds);
    } catch (_) {
      if (_disposed) return;
      state = state.copyWith(
        isLoading: false,
        errorText: () => ref.read(l10nProvider).otpSendFailed,
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
