import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/search_provider.dart';
import '../widgets/search_bar.dart';
import '../widgets/filter_chips.dart';
import '../widgets/search_results.dart';
import '../../../shared/widgets/empty_state.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(searchProvider.notifier).search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.exploreTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(164),
          child: Column(
            children: [
              CustomSearchBar(
                controller: _searchController,
                onChanged: _onSearchChanged,
                hintText: AppLocalizations.of(context)!.searchHint,
              ),
              const SearchFilterChips(),
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: AppLocalizations.of(context)!.searchPostsTab),
                  Tab(text: AppLocalizations.of(context)!.searchUsersTab),
                ],
              ),
            ],
          ),
        ),
      ),
      body: state.isEmpty
          ? Center(
              child: SingleChildScrollView(
                child: DentLinkEmptyState(
                  icon: Icons.travel_explore_rounded,
                  title: AppLocalizations.of(context)!.searchEmptyTitle,
                  subtitle:
                      AppLocalizations.of(context)!.searchEmptySubtitle,
                ),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: const [PostSearchResults(), UserSearchResults()],
            ),
    );
  }
}
