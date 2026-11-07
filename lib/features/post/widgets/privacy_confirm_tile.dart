import 'package:flutter/material.dart';
import 'package:dentigo/core/constants/app_dimensions.dart';
import 'package:dentigo/core/l10n/generated/app_localizations.dart';

/// Hasta mahremiyeti onayı (Faz 4): yüz ve kimlik bilgisi paylaşılmaz.
class PrivacyConfirmTile extends StatelessWidget {
  const PrivacyConfirmTile({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = value ? colorScheme.primary : colorScheme.tertiary;
    return CheckboxListTile(
      tileColor: color.withValues(alpha: 0.08),
      value: value,
      onChanged: (v) => onChanged(v ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      secondary: Icon(Icons.shield_outlined, color: color),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      title: Text(
        AppLocalizations.of(context)!.casePrivacyConfirm,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
