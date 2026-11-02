import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/utils/error_messages.dart';

/// Çıkış onayı; çıkış sürerken (push kaydı silinir, oturum kapanır) diyalog
/// açık kalır ve butonda yükleniyor gösterilir. Başarıda router login'e
/// yönlendirir ve diyaloğu da kaldırır.
class SignOutDialog extends ConsumerStatefulWidget {
  const SignOutDialog({super.key});

  @override
  ConsumerState<SignOutDialog> createState() => _SignOutDialogState();
}

class _SignOutDialogState extends ConsumerState<SignOutDialog> {
  bool _signingOut = false;
  String? _error;

  Future<void> _signOut() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _signingOut = true;
      _error = null;
    });
    try {
      // Kapatma yok: router login'e yönlendirirken diyaloğu da kaldırır; burada
      // pop yönlendirmeyle çakışıp navigator'ı kilitli bırakıyordu (!_debugLocked).
      await ref.read(authProvider.notifier).signOut();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _signingOut = false;
        _error = getErrorMessage(l10n, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final error = Theme.of(context).colorScheme.error;

    return PopScope(
      canPop: !_signingOut,
      child: AlertDialog(
        title: Text(l10n.logoutConfirmTitle),
        content: _error == null
            ? null
            : Text(_error!, style: TextStyle(color: error)),
        actions: [
          TextButton(
            onPressed: _signingOut ? null : () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: _signingOut ? null : _signOut,
            style: TextButton.styleFrom(foregroundColor: error),
            child: _signingOut
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.settingsLogout),
          ),
        ],
      ),
    );
  }
}
