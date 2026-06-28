import 'package:flutter/material.dart';

/// Gönderiye (Vaka/Soru) etiket eklemek için kullanılan bileşen.
class TagInput extends StatefulWidget {
  final List<String> initialTags;
  final ValueChanged<List<String>> onTagsChanged;

  const TagInput({
    super.key,
    this.initialTags = const [],
    required this.onTagsChanged,
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

  void _addTag(String value) {
    final cleanValue = value.trim().toLowerCase();
    if (cleanValue.isNotEmpty && !_tags.contains(cleanValue)) {
      setState(() {
        _tags.add(cleanValue);
      });
      widget.onTagsChanged(_tags);
    }
    _controller.clear();
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
    widget.onTagsChanged(_tags);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Etiketler',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
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
                      backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
                      deleteIconColor: colorScheme.primary,
                      onDeleted: () => _removeTag(tag),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: 'Etiket ekle (Enter\'a bas)',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: _addTag,
                onChanged: (val) {
                  if (val.endsWith(' ') || val.endsWith(',')) {
                    _addTag(val.substring(0, val.length - 1));
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
