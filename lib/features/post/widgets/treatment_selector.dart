import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:dentlink/core/constants/app_dimensions.dart';
import '../../../data/models/enums.dart';
import '../../../shared/extensions/treatment_type_ui.dart';
import 'form_section_label.dart';
import 'tag_input.dart';

/// Branş seçildikten sonra o branşın tedavi türlerinden birini ya da "Diğer"i
/// seçtirir. "Diğer"de tedavi adı yazılır; ad etiket olarak posta sabitlenir.
class TreatmentSelector extends StatelessWidget {
  final DentalBranch branch;
  final TreatmentType? selected;

  /// "Diğer" seçiliyse yazılan ad (boş olabilir); değilse null.
  final String? other;
  final ValueChanged<TreatmentType> onSelected;
  final ValueChanged<String> onOtherChanged;

  /// Etiket önerileri; listede olan tedavi yazılırsa o tür önerilir.
  final Future<List<String>> Function(String query)? suggest;

  const TreatmentSelector({
    super.key,
    required this.branch,
    this.selected,
    this.other,
    required this.onSelected,
    required this.onOtherChanged,
    this.suggest,
  });

  /// "Diğer" adının etiket biçimi (TagInput gibi; boşluk tireye).
  static String otherTag(String value) =>
      TagInput.normalize(value).replaceAll(RegExp(r'\s+'), '-');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormSectionLabel(
          icon: Icons.healing_outlined,
          label: l10n.postTreatment,
        ),
        const SizedBox(height: AppDimensions.spacing12),
        Wrap(
          spacing: AppDimensions.spacing8,
          runSpacing: AppDimensions.spacing8,
          children: [
            for (final t in TreatmentType.forBranch(branch))
              ChoiceChip(
                label: Text(t.displayName(context)),
                selected: other == null && t == selected,
                onSelected: (_) => onSelected(t),
              ),
            ChoiceChip(
              label: Text(l10n.treatmentOther),
              selected: other != null,
              onSelected: (_) => onOtherChanged(other ?? ''),
            ),
          ],
        ),
        if (other != null) ...[
          const SizedBox(height: AppDimensions.spacing12),
          _OtherTreatmentField(
            initial: other!,
            branch: branch,
            suggest: suggest,
            onChanged: onOtherChanged,
            onTreatment: onSelected,
          ),
        ],
      ],
    );
  }
}

class _OtherTreatmentField extends StatefulWidget {
  final String initial;
  final DentalBranch branch;
  final Future<List<String>> Function(String query)? suggest;
  final ValueChanged<String> onChanged;
  final ValueChanged<TreatmentType> onTreatment;

  const _OtherTreatmentField({
    required this.initial,
    required this.branch,
    required this.suggest,
    required this.onChanged,
    required this.onTreatment,
  });

  @override
  State<_OtherTreatmentField> createState() => _OtherTreatmentFieldState();
}

class _OtherTreatmentFieldState extends State<_OtherTreatmentField> {
  late final _controller = TextEditingController(text: widget.initial);
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  TreatmentType? _listed(String tag) {
    for (final t in TreatmentType.forBranch(widget.branch)) {
      if (t.tag == tag) return t;
    }
    return null;
  }

  /// TagInput._suggestions ile aynı: debounce, eski sorgu atılır, hata sessiz.
  Future<Iterable<String>> _suggestions(TextEditingValue value) async {
    final suggest = widget.suggest;
    final query = TagInput.normalize(value.text);
    if (suggest == null || query.length < TagInput.minSuggestLength) {
      return const [];
    }
    await Future<void>.delayed(TagInput.suggestDebounce);
    if (!mounted || TagInput.normalize(_controller.text) != query) {
      return const [];
    }
    try {
      return await suggest(query);
    } catch (_) {
      return const [];
    }
  }

  void _onSelected(String tag) {
    // Listede olan tedavi seçilirse "Diğer" yerine o tür seçilir.
    final listed = _listed(tag);
    if (listed != null) return widget.onTreatment(listed);
    widget.onChanged(tag);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return RawAutocomplete<String>(
      textEditingController: _controller,
      focusNode: _focusNode,
      optionsBuilder: _suggestions,
      onSelected: _onSelected,
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: AlignmentDirectional.topStart,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240, maxWidth: 320),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: [
                for (final tag in options)
                  if (_listed(tag) case final t?)
                    ListTile(
                      leading: const Icon(Icons.check_circle_outline),
                      title: Text(t.displayName(context)),
                      subtitle: Text(l10n.treatmentInList),
                      onTap: () => onSelected(tag),
                    )
                  else
                    ListTile(
                      title: Text('#$tag'),
                      onTap: () => onSelected(tag),
                    ),
              ],
            ),
          ),
        ),
      ),
      fieldViewBuilder: (context, controller, focusNode, _) => TextField(
        controller: controller,
        focusNode: focusNode,
        maxLength: TagInput.maxTagLength, // DB: tags_name_length (017)
        decoration: InputDecoration(
          labelText: l10n.otherTreatmentLabel,
          hintText: l10n.otherTreatmentHint,
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}
