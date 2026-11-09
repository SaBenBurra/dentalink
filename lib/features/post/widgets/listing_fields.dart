import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../data/models/enums.dart';
import '../../../shared/extensions/listing_l10n.dart';
import 'form_section_label.dart';

/// İlan oluşturma ve düzenlemede ortak alanlar: kategori, durum, fiyat, şehir.
class ListingFields extends StatelessWidget {
  const ListingFields({
    super.key,
    required this.category,
    required this.condition,
    required this.priceController,
    required this.cityController,
    required this.onCategoryChanged,
    required this.onConditionChanged,
  });

  final ListingCategory? category;
  final ItemCondition? condition;
  final TextEditingController priceController;
  final TextEditingController cityController;
  final ValueChanged<ListingCategory?> onCategoryChanged;
  final ValueChanged<ItemCondition?> onConditionChanged;

  /// Boş: fiyat yazılmaz (052; en fazla 8 hane, DB sınırının altında).
  static int? parsePrice(String text) => int.tryParse(text.trim());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String? required(Object? v) =>
        v == null || (v is String && v.trim().isEmpty)
        ? l10n.validationRequired
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormSectionLabel(
          icon: Icons.sell_outlined,
          label: l10n.listingSectionDetails,
        ),
        const SizedBox(height: AppDimensions.spacing12),
        DropdownButtonFormField<ListingCategory>(
          initialValue: category,
          decoration: InputDecoration(labelText: l10n.listingCategoryLabel),
          items: [
            for (final c in ListingCategory.values)
              DropdownMenuItem(value: c, child: Text(c.label(context))),
          ],
          onChanged: onCategoryChanged,
          validator: required,
        ),
        const SizedBox(height: AppDimensions.spacing16),
        DropdownButtonFormField<ItemCondition>(
          initialValue: condition,
          decoration: InputDecoration(labelText: l10n.listingConditionLabel),
          items: [
            for (final c in ItemCondition.values)
              DropdownMenuItem(value: c, child: Text(c.label(context))),
          ],
          onChanged: onConditionChanged,
          validator: required,
        ),
        const SizedBox(height: AppDimensions.spacing16),
        TextFormField(
          controller: priceController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 8,
          decoration: InputDecoration(
            labelText: l10n.listingPriceLabel,
            helperText: l10n.listingPriceHelper,
          ),
        ),
        const SizedBox(height: AppDimensions.spacing8),
        TextFormField(
          controller: cityController,
          maxLength: 60, // DB: posts.city (052)
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: l10n.listingCityLabel),
          validator: required,
        ),
      ],
    );
  }
}
