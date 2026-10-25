import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../../core/constants/app_dimensions.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/loading_indicator.dart';

/// Uygulama içindeki hukuk metinleri (`assets/legal/<doc>_<dil>.txt`).
enum LegalDoc {
  terms,
  privacy,
  kvkk;

  static LegalDoc? tryParse(String? name) =>
      LegalDoc.values.where((d) => d.name == name).firstOrNull;

  String title(AppLocalizations l10n) => switch (this) {
    LegalDoc.terms => l10n.settingsTerms,
    LegalDoc.privacy => l10n.settingsPrivacyPolicy,
    LegalDoc.kvkk => l10n.legalKvkk,
  };

  /// Yalnızca TR ve EN metni var; diğer diller EN'e düşer.
  String assetPath(Locale locale) =>
      'assets/legal/${name}_${locale.languageCode == 'tr' ? 'tr' : 'en'}.txt';
}

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.doc});

  final LegalDoc doc;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(doc.title(l10n))),
      body: FutureBuilder<String>(
        future: rootBundle.loadString(doc.assetPath(Localizations.localeOf(context))),
        builder: (context, snapshot) {
          if (snapshot.hasError) return DentLinkErrorWidget(message: l10n.unknownError);
          if (!snapshot.hasData) return const DentLinkLoadingSpinner();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.spacing16),
            child: SafeArea(child: SelectableText(snapshot.data!)),
          );
        },
      ),
    );
  }
}
