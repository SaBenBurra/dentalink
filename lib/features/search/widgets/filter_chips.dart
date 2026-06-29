import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/enums.dart';
import '../../../providers/search_provider.dart';
import 'package:dentlink/core/constants/app_dimensions.dart';

class SearchFilterChips extends ConsumerWidget {
  const SearchFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchProvider);
    final notifier = ref.read(searchProvider.notifier);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacing16,
        vertical: AppDimensions.spacing8,
      ),
      child: Row(
        children: [
          if (state.branchFilter != null || state.typeFilter != null)
            Padding(
              padding: const EdgeInsets.only(right: AppDimensions.spacing8),
              child: ActionChip(
                label: const Text('Temizle'),
                avatar: const Icon(Icons.clear_rounded, size: 16),
                onPressed: () => notifier.clearFilters(),
              ),
            ),

          Padding(
            padding: const EdgeInsets.only(right: AppDimensions.spacing8),
            child: PopupMenuButton<PostType?>(
              initialValue: state.typeFilter,
              onSelected: (val) => notifier.setTypeFilter(val),
              itemBuilder: (context) => [
                const PopupMenuItem(value: null, child: Text('Tümü')),
                ...PostType.values.map(
                  (type) => PopupMenuItem(
                    value: type,
                    child: Text(
                      type == PostType.casePost ? 'Vakalar' : 'Sorular',
                    ),
                  ),
                ),
              ],
              child: Chip(
                label: Text(
                  state.typeFilter == null
                      ? 'İçerik Türü'
                      : (state.typeFilter == PostType.casePost
                            ? 'Vaka'
                            : 'Soru'),
                ),
                deleteIcon: state.typeFilter != null
                    ? const Icon(Icons.clear_rounded, size: 16)
                    : null,
                onDeleted: state.typeFilter != null
                    ? () => notifier.setTypeFilter(null)
                    : null,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(right: AppDimensions.spacing8),
            child: PopupMenuButton<DentalBranch?>(
              initialValue: state.branchFilter,
              onSelected: (val) => notifier.setBranchFilter(val),
              itemBuilder: (context) => [
                const PopupMenuItem(value: null, child: Text('Tüm Branşlar')),
                ...DentalBranch.values.map(
                  (branch) => PopupMenuItem(
                    value: branch,
                    child: Text(branch.displayName),
                  ),
                ),
              ],
              child: Chip(
                label: Text(state.branchFilter?.displayName ?? 'Branş'),
                deleteIcon: state.branchFilter != null
                    ? const Icon(Icons.clear_rounded, size: 16)
                    : null,
                onDeleted: state.branchFilter != null
                    ? () => notifier.setBranchFilter(null)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
