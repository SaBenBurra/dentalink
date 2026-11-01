import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/providers/repository_providers.dart';
import '../../../providers/search_provider.dart';
import '../../post/widgets/tag_input.dart';
import '../widgets/search_bar.dart';
import '../widgets/filter_chips.dart';
import '../widgets/search_results.dart';

/// Keşfet: arama satırı (metin ve `#etiket`), branşlar, popüler konular ve gönderiler.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();

  /// `#` ile yazılan etiketin önerileri; doluyken gövdenin yerine gösterilir.
  List<String> _suggestions = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  SearchNotifier get _notifier => ref.read(searchProvider.notifier);

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    final tag = typingTag(query);
    // Etiket yazılırken arama beklenir; boşluk ya da öneri seçimi bitirir.
    if (tag != null) return _suggest(tag);
    if (_suggestions.isNotEmpty) setState(() => _suggestions = const []);
    _debounce = Timer(
      const Duration(milliseconds: 500),
      () => _notifier.search(query),
    );
  }

  void _suggest(String tag) {
    final query = TagInput.normalize(tag);
    if (query.length < TagInput.minSuggestLength) {
      setState(() => _suggestions = const []);
      return;
    }
    _debounce = Timer(TagInput.suggestDebounce, () async {
      List<String> result;
      try {
        result = await ref
            .read(createPostRepositoryProvider)
            .suggestTags(query);
      } catch (_) {
        result =
            const []; // Öneri yardımcı bir özellik; hata aramayı engellemesin.
      }
      if (!mounted || typingTag(_searchController.text) != tag) return;
      setState(() => _suggestions = result);
    });
  }

  void _submit(String query) {
    _debounce?.cancel();
    setState(() => _suggestions = const []);
    _notifier.search(query);
  }

  /// Yazılmakta olan etiketin yerine öneriyi koyar ve arar.
  void _pickSuggestion(String name) {
    final words = _searchController.text.split(' ')..removeLast();
    final text = '${[...words, hashtag(name)].join(' ')} ';
    _searchController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _submit(text);
  }

  /// Popüler etiket: sorgu iptal, branş Tümü (notifier'da). Seçili etikete
  /// tekrar dokunmak seçimi kaldırır ve genel popüler listeye döner.
  void _onTagTap(String name) {
    _debounce?.cancel();
    final deselect = ref.read(searchProvider).isOnlyTag(name);
    _searchController.text = deselect ? '' : hashtag(name);
    setState(() => _suggestions = const []);
    FocusScope.of(context).unfocus();
    deselect ? _notifier.search('') : _notifier.selectTag(name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CustomSearchBar(
              controller: _searchController,
              onChanged: _onSearchChanged,
              onSubmitted: _submit,
              hintText: AppLocalizations.of(context)!.searchHint,
            ),
            const BranchFilterChips(),
            Expanded(
              child: _suggestions.isEmpty
                  ? ExploreResults(onTagTap: _onTagTap)
                  : ListView(
                      children: [
                        for (final tag in _suggestions)
                          ListTile(
                            leading: const Icon(Icons.tag_rounded),
                            title: Text(tag),
                            onTap: () => _pickSuggestion(tag),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
