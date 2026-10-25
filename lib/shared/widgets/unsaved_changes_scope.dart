import 'package:flutter/material.dart';

import '../../core/l10n/generated/app_localizations.dart';

/// Form ekranlarında geri tuşu: [busy] iken (gönderiliyor) hiç çıkılmaz,
/// [dirty] iken onay istenir (UX-2). Kaydedip `context.pop()` ile çıkmak
/// etkilenmez; PopScope yalnızca sistem geri ve AppBar geri tuşunu yakalar.
class UnsavedChangesScope extends StatelessWidget {
  const UnsavedChangesScope({
    super.key,
    required this.dirty,
    required this.busy,
    required this.child,
  });

  final bool dirty;
  final bool busy;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !dirty && !busy,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || busy) return;
        final navigator = Navigator.of(context);
        final l10n = AppLocalizations.of(context)!;
        final leave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.discardChangesTitle),
            content: Text(l10n.discardChangesMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.discardChangesConfirm),
              ),
            ],
          ),
        );
        if (leave == true) navigator.pop();
      },
      child: child,
    );
  }
}
