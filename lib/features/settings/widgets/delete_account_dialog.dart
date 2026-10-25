import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/utils/error_messages.dart';

/// Geri alınamaz işlem: kullanıcı onay kelimesini yazmadan buton açılmaz.
/// Başarıda router oturum kapandığı için login'e yönlendirir.
class DeleteAccountDialog extends ConsumerStatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  ConsumerState<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<DeleteAccountDialog> {
  final _controller = TextEditingController();
  bool _deleting = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).deleteAccount();
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _deleting = false;
        _error = getErrorMessage(l10n, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final error = Theme.of(context).colorScheme.error;
    final word = l10n.deleteAccountConfirmWord;
    final matches = _controller.text.trim() == word;

    return PopScope(
      canPop: !_deleting,
      child: AlertDialog(
        title: Text(l10n.deleteAccountTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.deleteAccountBody),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                enabled: !_deleting,
                maxLength: 10,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: l10n.deleteAccountTypeToConfirm(word),
                  errorText: _error,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _deleting ? null : () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: matches && !_deleting ? _delete : null,
            style: TextButton.styleFrom(foregroundColor: error),
            child: _deleting
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.settingsDeleteAccount),
          ),
        ],
      ),
    );
  }
}
