import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:dentlink/core/constants/app_dimensions.dart';

/// Gönderiye (Vaka/Soru) etiket eklemek için kullanılan bileşen.
class TagInput extends StatefulWidget {
  final List<String> initialTags;
  final ValueChanged<List<String>> onTagsChanged;

  /// Tanımlı etiket önerileri (normalize edilmiş sorguyla çağrılır). Null ise öneri yok.
  final Future<List<String>> Function(String query)? suggest;

  static const maxTags = 5;
  static const maxTagLength = 30;
  static const minSuggestLength = 2;
  static const suggestDebounce = Duration(milliseconds: 300);

  /// `#` ve boşluk atılır; Türkçe I/İ doğru küçültülür.
  static String normalize(String value) => value
      .replaceAll('#', '')
      .trim()
      .replaceAll('I', 'ı')
      .replaceAll('İ', 'i')
      .toLowerCase();

  const TagInput({
    super.key,
    this.initialTags = const [],
    required this.onTagsChanged,
    this.suggest,
  });

  @override
  State<TagInput> createState() => _TagInputState();
}

class _TagInputState extends State<TagInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late List<String> _tags;

  @override
  void initState() {
    super.initState();
    _tags = List.from(widget.initialTags);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _isFull => _tags.length >= TagInput.maxTags;

  void _addTag(String value) {
    final tag = TagInput.normalize(value);
    if (tag.isNotEmpty && !_isFull && !_tags.contains(tag)) _tags.add(tag);
  }

  /// Yazılmakta olan etiket de dahil edilir: gönderimde kaybolmasın.
  void _emit() {
    final pending = TagInput.normalize(_controller.text);
    widget.onTagsChanged([
      ..._tags,
      if (pending.isNotEmpty && !_isFull && !_tags.contains(pending)) pending,
    ]);
  }

  void _onChanged(String value) {
    final parts = value.split(RegExp(r'[\s,]'));
    if (parts.length > 1) {
      // Boşluk/virgülle bitenler eklenir; son parça yazılmaya devam eder.
      setState(() => parts.take(parts.length - 1).forEach(_addTag));
      final rest = _isFull ? '' : parts.last;
      _controller.value = TextEditingValue(
        text: rest,
        selection: TextSelection.collapsed(offset: rest.length),
      );
    }
    _emit();
  }

  void _onSubmitted(String value) {
    setState(() => _addTag(value));
    _controller.clear();
    _emit();
  }

  /// RawAutocomplete eski isteklerin sonucunu kendisi atar; debounce yalnızca
  /// her harfte istek gitmesin diye.
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
      return (await suggest(query)).where((t) => !_tags.contains(t));
    } catch (_) {
      return const []; // Öneri yardımcı bir özellik; hata etiket yazmayı engellemesin.
    }
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.postTags,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppDimensions.spacing8),
        Container(
          padding: const EdgeInsets.all(AppDimensions.spacing12),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outline),
            borderRadius: BorderRadius.circular(12),
            color: colorScheme.surface,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_tags.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tags.map((tag) {
                    return InputChip(
                      label: Text('#$tag'),
                      labelStyle: TextStyle(color: colorScheme.primary),
                      backgroundColor: colorScheme.primaryContainer.withValues(
                        alpha: 0.3,
                      ),
                      deleteIconColor: colorScheme.primary,
                      onDeleted: () => _removeTag(tag),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppDimensions.spacing8),
              ],
              if (!_isFull)
                RawAutocomplete<String>(
                  textEditingController: _controller,
                  focusNode: _focusNode,
                  optionsBuilder: _suggestions,
                  onSelected: _onSubmitted,
                  optionsViewBuilder: (context, onSelected, options) => Align(
                    alignment: AlignmentDirectional.topStart,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: 240,
                          maxWidth: 320,
                        ),
                        child: ListView(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          children: [
                            for (final tag in options)
                              ListTile(
                                title: Text('#$tag'),
                                onTap: () => onSelected(tag),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  fieldViewBuilder: (context, controller, focusNode, _) =>
                      TextField(
                        controller: controller,
                        maxLength: TagInput.maxTagLength,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.addTagHint,
                          counterText: '',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintStyle: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: _onSubmitted,
                        onChanged: _onChanged,
                      ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
