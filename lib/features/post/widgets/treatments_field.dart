import 'package:flutter/material.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../data/models/case_treatment.dart';
import '../../../shared/extensions/dental_branch_ui.dart';
import '../../../shared/extensions/treatment_type_ui.dart';
import 'form_section_label.dart';
import 'treatment_picker.dart';

/// Vaka formunda "Tedaviler": 1–5 tedavi, seçim sırasıyla. Branş ayrıca
/// sorulmaz; tedavilerden çıkar.
class TreatmentsField extends StatelessWidget {
  const TreatmentsField({
    super.key,
    required this.treatments,
    required this.onChanged,
    required this.search,
  });

  final List<CaseTreatment> treatments;
  final ValueChanged<List<CaseTreatment>> onChanged;
  final Future<List<CaseTreatment>> Function(String query) search;

  /// DB: resolve_case_treatments (040).
  static const maxTreatments = 5;

  Future<void> _add(BuildContext context) async {
    final picked = await showTreatmentPicker(
      context,
      taken: {for (final t in treatments) t.slug},
      search: search,
    );
    if (picked != null && !treatments.any((t) => t.slug == picked.slug)) {
      onChanged([...treatments, picked]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormSectionLabel(
          icon: Icons.healing_outlined,
          label: l10n.postTreatment,
          trailing: Text(
            '${treatments.length}/$maxTreatments',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spacing12),
        Wrap(
          spacing: AppDimensions.spacing8,
          runSpacing: AppDimensions.spacing8,
          children: [
            for (final t in treatments)
              InputChip(
                avatar: Icon(
                  Icons.circle,
                  size: 10,
                  color: t.branch.colorOf(context),
                ),
                label: Text(t.displayName(context)),
                tooltip: t.branch.displayName(context),
                onDeleted: () => onChanged([...treatments]..remove(t)),
              ),
            if (treatments.length < maxTreatments)
              ActionChip(
                avatar: const Icon(Icons.add_rounded),
                label: Text(l10n.treatmentAdd),
                onPressed: () => _add(context),
              ),
          ],
        ),
      ],
    );
  }
}
