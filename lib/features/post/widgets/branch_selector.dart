import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:dentlink/core/constants/app_dimensions.dart';
import '../../../data/models/enums.dart';
import '../../../shared/widgets/branch_chip.dart';
import 'form_section_label.dart';

/// Vaka oluştururken Diş Hekimliği Branşını seçmek için kullanılan bileşen.
/// Branşlar renkli chip olarak tek dokunuşla seçilir.
class BranchSelector extends StatelessWidget {
  final DentalBranch? selectedBranch;
  final ValueChanged<DentalBranch> onBranchSelected;

  const BranchSelector({
    super.key,
    this.selectedBranch,
    required this.onBranchSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormSectionLabel(
          icon: Icons.medical_services_outlined,
          label: AppLocalizations.of(context)!.postBranch,
        ),
        const SizedBox(height: AppDimensions.spacing12),
        Wrap(
          spacing: AppDimensions.spacing8,
          runSpacing: AppDimensions.spacing8,
          children: [
            for (final branch in DentalBranch.values)
              Semantics(
                button: true,
                selected: branch == selectedBranch,
                child: BranchChip(
                  branch: branch,
                  showIcon: true,
                  isSelected: branch == selectedBranch,
                  onTap: () => onBranchSelected(branch),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
