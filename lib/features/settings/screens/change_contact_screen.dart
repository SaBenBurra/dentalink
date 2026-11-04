import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/utils/contact_utils.dart';
import '../../../data/repositories/otp_cooldown_exception.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/utils/error_messages.dart';

/// Hesaba e-posta ya da WhatsApp numarası ekler veya mevcut olanı değiştirir.
/// Değişiklik, yeni adrese gelen kod doğrulanınca geçerli olur.
class ChangeContactScreen extends ConsumerStatefulWidget {
  const ChangeContactScreen({super.key, required this.isEmail});

  final bool isEmail;

  @override
  ConsumerState<ChangeContactScreen> createState() =>
      _ChangeContactScreenState();
}

class _ChangeContactScreenState extends ConsumerState<ChangeContactScreen> {
  static const _otpLength = 6;
  static const _cooldownSeconds = 60;

  final _contactController = TextEditingController();
  final _codeController = TextEditingController();
  Timer? _timer;
  String? _destination; // Kod gönderilmiş adres; null iken ilk adımdayız.
  bool _loading = false;
  String? _error;
  int _countdown = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _contactController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  String? get _normalized => widget.isEmail
      ? normalizeEmail(_contactController.text)
      : normalizePhone(_contactController.text);

  String? get _current {
    final user = ref.read(currentUserProvider);
    final value = widget.isEmail ? user?.email : user?.phone;
    if (value == null || value.isEmpty) return null;
    return widget.isEmail ? value : '+$value';
  }

  void _startCountdown(int seconds) {
    _timer?.cancel();
    setState(() => _countdown = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown <= 1) timer.cancel();
      setState(() => _countdown--);
    });
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context)!;
    final destination = _destination ?? _normalized;
    if (destination == null || _loading) return;
    if (destination == _current) {
      setState(() => _error = l10n.contactSame);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).requestContactChange(destination);
      if (!mounted) return;
      _destination = destination;
      _startCountdown(_cooldownSeconds);
    } on OtpCooldownException catch (e) {
      if (!mounted) return;
      if (e.sameDestination) {
        _destination = destination;
        _startCountdown(e.remainingSeconds);
      } else {
        setState(() => _error = l10n.otpTooManyAttempts(e.remainingSeconds));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = getErrorMessage(l10n, e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verify() async {
    final l10n = AppLocalizations.of(context)!;
    if (_loading || _codeController.text.length != _otpLength) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authProvider.notifier)
          .confirmContactChange(_destination!, _codeController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.contactSaved)));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = getOtpErrorMessage(l10n, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasCurrent = _current != null;
    final title = widget.isEmail
        ? (hasCurrent ? l10n.contactChangeEmail : l10n.contactAddEmail)
        : (hasCurrent ? l10n.contactChangePhone : l10n.contactAddPhone);
    final destination = _destination;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.spacing16),
          children: destination == null
              ? _buildContactStep(l10n)
              : _buildCodeStep(l10n, destination),
        ),
      ),
    );
  }

  List<Widget> _buildContactStep(AppLocalizations l10n) => [
    Text(widget.isEmail ? l10n.contactEmailInfo : l10n.contactPhoneInfo),
    const SizedBox(height: AppDimensions.spacing16),
    TextField(
      controller: _contactController,
      autofocus: true,
      autocorrect: false,
      enableSuggestions: false,
      keyboardType: widget.isEmail
          ? TextInputType.emailAddress
          : TextInputType.phone,
      maxLength: 254,
      decoration: InputDecoration(
        labelText: widget.isEmail ? l10n.email : l10n.contactWhatsapp,
        hintText: widget.isEmail ? null : l10n.phoneHint,
        errorText: _error,
        counterText: '',
      ),
      onChanged: (_) => setState(() => _error = null),
      onSubmitted: (_) => _send(),
    ),
    const SizedBox(height: AppDimensions.spacing16),
    FilledButton(
      onPressed: _loading || _normalized == null ? null : _send,
      child: Text(l10n.contactSendCode),
    ),
  ];

  List<Widget> _buildCodeStep(AppLocalizations l10n, String destination) => [
    Text(
      widget.isEmail
          ? l10n.otpSentToEmail(destination)
          : l10n.otpSentToWhatsapp(destination),
    ),
    const SizedBox(height: AppDimensions.spacing16),
    TextField(
      controller: _codeController,
      autofocus: true,
      keyboardType: TextInputType.number,
      autofillHints: const [AutofillHints.oneTimeCode],
      maxLength: _otpLength,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: l10n.verificationCode,
        errorText: _error,
        counterText: '',
      ),
      onChanged: (_) => setState(() => _error = null),
      onSubmitted: (_) => _verify(),
    ),
    const SizedBox(height: AppDimensions.spacing16),
    FilledButton(
      onPressed: _loading || _codeController.text.length != _otpLength
          ? null
          : _verify,
      child: Text(l10n.contactVerify),
    ),
    const SizedBox(height: AppDimensions.spacing8),
    TextButton(
      onPressed: _loading || _countdown > 0 ? null : _send,
      child: Text(
        _countdown > 0 ? l10n.resendCodeIn(_countdown) : l10n.resendCode,
      ),
    ),
  ];
}
