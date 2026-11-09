import '../../core/l10n/generated/app_localizations.dart';
import '../../data/models/support_model.dart';

extension SupportStatusL10n on SupportStatus {
  String label(AppLocalizations l10n) => switch (this) {
    SupportStatus.open => l10n.supportStatusOpen,
    SupportStatus.answered => l10n.supportStatusAnswered,
    SupportStatus.resolved => l10n.supportStatusResolved,
  };
}

extension SupportCategoryL10n on SupportCategory {
  String label(AppLocalizations l10n) => switch (this) {
    SupportCategory.bug => l10n.supportCategoryBug,
    SupportCategory.account => l10n.supportCategoryAccount,
    SupportCategory.suggestion => l10n.supportCategorySuggestion,
    SupportCategory.complaint => l10n.supportCategoryComplaint,
    SupportCategory.other => l10n.supportCategoryOther,
  };
}
