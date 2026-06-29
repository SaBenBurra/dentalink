import 'package:flutter/material.dart';
import 'package:dentlink/core/constants/app_dimensions.dart';

/// Vaka oluştururken Diş Hekimliği Branşını seçmek için kullanılan bileşen.
class BranchSelector extends StatelessWidget {
  final String? selectedBranch;
  final ValueChanged<String> onBranchSelected;

  const BranchSelector({
    super.key,
    this.selectedBranch,
    required this.onBranchSelected,
  });

  static const List<Map<String, String>> _branches = [
    {'id': 'pedodonti', 'name': 'Pedodonti'},
    {'id': 'endodonti', 'name': 'Endodonti'},
    {'id': 'ortodonti', 'name': 'Ortodonti'},
    {'id': 'periodontoloji', 'name': 'Periodontoloji'},
    {'id': 'protetik_dis_tedavisi', 'name': 'Protetik Diş Tedavisi'},
    {'id': 'agiz_dis_cene_cerrahisi', 'name': 'Ağız Diş ve Çene Cerrahisi'},
    {'id': 'agiz_dis_cene_radyolojisi', 'name': 'Ağız Diş ve Çene Radyolojisi'},
    {'id': 'oral_diagnoz', 'name': 'Oral Diagnoz'},
    {'id': 'restoratif_dis_tedavisi', 'name': 'Restoratif Diş Tedavisi'},
  ];

  String? _getBranchName(String id) {
    try {
      return _branches.firstWhere((b) => b['id'] == id)['name'];
    } catch (_) {
      return null;
    }
  }

  void _showBranchBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            final colorScheme = Theme.of(context).colorScheme;
            return Column(
              children: [
                const SizedBox(height: AppDimensions.spacing12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacing16),
                Text(
                  'Branş Seç',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppDimensions.spacing8),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _branches.length,
                    itemBuilder: (context, index) {
                      final branch = _branches[index];
                      final isSelected = selectedBranch == branch['id'];

                      return ListTile(
                        leading: Icon(
                          Icons.category_outlined,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        title: Text(
                          branch['name']!,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? colorScheme.primary : null,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle,
                                color: colorScheme.primary,
                              )
                            : null,
                        onTap: () {
                          onBranchSelected(branch['id']!);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Branş',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppDimensions.spacing8),
        InkWell(
          onTap: () => _showBranchBottomSheet(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacing16,
              vertical: AppDimensions.spacing16,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outline),
              borderRadius: BorderRadius.circular(12),
              color: colorScheme.surface,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedBranch != null
                      ? _getBranchName(selectedBranch!) ?? 'Bilinmeyen Branş'
                      : 'Lütfen bir branş seçin',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: selectedBranch != null
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
