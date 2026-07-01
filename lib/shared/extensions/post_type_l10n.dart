import 'package:flutter/material.dart';
import 'package:dentlink/core/l10n/generated/app_localizations.dart'; // Kendi yolunuza göre düzeltin
import '../../../data/models/enums.dart';

extension PostTypeL10n on PostType {
  String getLabelInProfile(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return switch (this) {
      PostType.casePost => l10n.casesTabLabelInProfile,
      PostType.question => l10n.questionsTabLabelInProfile,
    };
  }
}
