import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../data/models/enums.dart';
import '../../../providers/feed_provider.dart';
import '../../../shared/extensions/listing_l10n.dart';
import 'feed_list.dart';

/// Ticaret sekmesi: kategori çipleri ve satılmamış ilanlar (052). İlanlar
/// "Tümü"ye karışmaz; liste ancak sekme açılınca çekilir.
class ListingsTab extends ConsumerWidget {
  const ListingsTab({super.key, this.controller});

  final ScrollController? controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selected = ref.watch(listingCategoryProvider);

    Widget chip(ListingCategory? category) => Padding(
      padding: const EdgeInsets.only(right: AppDimensions.spacing8),
      child: ChoiceChip(
        label: Text(category?.label(context) ?? l10n.feedFilterAll),
        selected: selected == category,
        onSelected: (_) =>
            ref.read(listingCategoryProvider.notifier).state = category,
      ),
    );

    return Column(
      children: [
        SizedBox(
          height: AppDimensions.spacing48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacing16,
            ),
            children: [
              chip(null),
              for (final c in ListingCategory.values) chip(c),
            ],
          ),
        ),
        Expanded(
          child: FeedList(
            ref: ref,
            context: context,
            feedState: ref.watch(listingFeedProvider),
            filterType: null,
            l10n: l10n,
            colorScheme: Theme.of(context).colorScheme,
            controller: controller,
            provider: listingFeedProvider,
            emptyTitle: l10n.feedListingsEmptyTitle,
            emptySubtitle: l10n.feedListingsEmptySubtitle,
          ),
        ),
      ],
    );
  }
}
