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
  const SearchScreen({super.key, this.autofocus = false, this.tag});

  /// Feed üst barındaki arama ikonundan gelindiyse arama satırı odaklanır.
  final bool autofocus;

  /// `?tag=`: post kartındaki etikete dokunuldu; arama o etiketle açılır.
  final String? tag;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with WidgetsBindingObserver {
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  /// `#` ile yazılan etiketin önerileri; doluyken gövdenin yerine gösterilir.
  List<String> _suggestions = const [];

  double _keyboardInset = 0;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
    WidgetsBinding.instance.addObserver(this);
    _applyTag();
  }

  @override
  void didUpdateWidget(SearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tag != oldWidget.tag) _applyTag();
  }

  void _applyTag() {
    final tag = widget.tag;
    if (tag == null || tag.isEmpty) return;
    _searchController.text = hashtag(tag);
    // Provider build sırasında değiştirilemez.
    Future.microtask(() {
      if (mounted) _notifier.selectTag(tag);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Klavye geri tuşuyla kapanınca odak da bırakılır, keşfet içeriği geri gelir.
  @override
  void didChangeMetrics() {
    final inset = View.of(context).viewInsets.bottom;
    if (inset == 0 && _keyboardInset > 0) _focusNode.unfocus();
    _keyboardInset = inset;
  }

  SearchNotifier get _notifier => ref.read(searchProvider.notifier);

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    final tag = typingTag(query);
    // Etiket yazılırken arama beklenir; boşluk ya da öneri seçimi bitirir.
    if (tag != null) return _suggest(tag);
    if (_suggestions.isNotEmpty) setState(() => _suggestions = const []);
    // Silinen sorgu beklemeden keşfete döner.
    if (query.isEmpty) return _submit(query);
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
    // Arama satırı odaktayken keşfet içeriği kaybolur; gövde yalnızca
    // arama sonuçları için (sorgu doluyken) görünür.
    final hideExplore =
        _focusNode.hasFocus &&
        ref.watch(searchProvider.select((s) => s.query.trim().isEmpty));
    final hideBody = hideExplore || _suggestions.isNotEmpty;
    const duration = Duration(milliseconds: 250);
    final Widget overlay;
    if (_suggestions.isNotEmpty) {
      overlay = ListView(
        key: const ValueKey('suggestions'),
        children: [
          for (final tag in _suggestions)
            ListTile(
              leading: const Icon(Icons.tag_rounded),
              title: Text(tag),
              onTap: () => _pickSuggestion(tag),
            ),
        ],
      );
    } else if (hideExplore) {
      // Boş alana dokunmak odağı bırakır ve keşfet içeriğine döner.
      overlay = GestureDetector(
        key: const ValueKey('empty'),
        behavior: HitTestBehavior.opaque,
        onTap: _focusNode.unfocus,
      );
    } else {
      overlay = const SizedBox.shrink();
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CustomSearchBar(
              controller: _searchController,
              onChanged: _onSearchChanged,
              onSubmitted: _submit,
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              hintText: AppLocalizations.of(context)!.searchHint,
            ),
            const BranchFilterChips(),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Keşfet ağaçta kalır (liste, görseller, etiketler yeniden
                  // kurulmaz); geri dönüş takılmadan solarak gelir.
                  IgnorePointer(
                    ignoring: hideBody,
                    child: AnimatedOpacity(
                      opacity: hideBody ? 0 : 1,
                      duration: duration,
                      child: ExploreResults(onTagTap: _onTagTap),
                    ),
                  ),
                  AnimatedSwitcher(duration: duration, child: overlay),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
