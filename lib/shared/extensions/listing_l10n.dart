import 'package:flutter/widgets.dart';

import '../../core/l10n/generated/app_localizations.dart';
import '../../data/models/enums.dart';
import '../../data/models/post_model.dart';

extension ListingCategoryL10n on ListingCategory {
  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (this) {
      ListingCategory.handInstruments => l10n.listingCategoryHandInstruments,
      ListingCategory.rotary => l10n.listingCategoryRotary,
      ListingCategory.equipment => l10n.listingCategoryEquipment,
      ListingCategory.consumables => l10n.listingCategoryConsumables,
      ListingCategory.books => l10n.listingCategoryBooks,
      ListingCategory.models => l10n.listingCategoryModels,
      ListingCategory.other => l10n.listingCategoryOther,
    };
  }
}

extension ItemConditionL10n on ItemCondition {
  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (this) {
      ItemCondition.brandNew => l10n.itemConditionNew,
      ItemCondition.likeNew => l10n.itemConditionLikeNew,
      ItemCondition.used => l10n.itemConditionUsed,
    };
  }
}

extension ListingPriceL10n on ListingPostModel {
  /// "1.250 ₺" ya da fiyat yoksa "Fiyat sorunuz".
  String priceLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (price) {
      final p? => l10n.listingPrice(p),
      null => l10n.listingPriceOnRequest,
    };
  }
}
