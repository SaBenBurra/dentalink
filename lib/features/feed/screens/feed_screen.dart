import 'package:dentlink/features/feed/widgets/feed_list.dart';
import 'package:dentlink/features/feed/widgets/feed_screen_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../data/models/enums.dart';
import '../../../providers/feed_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../shell/main_shell.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _pageController = PageController();
  int _index = 0;
  // Segmente dokununca sayfa ara sayfalardan geçer; o sırada gelen
  // onPageChanged seçimi geri çekmesin.
  bool _animatingToTap = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _select(int index) async {
    if (index == _index) return;
    setState(() => _index = index);
    _animatingToTap = true;
    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
    _animatingToTap = false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final feedState = ref.watch(feedProvider);
    final l10n = AppLocalizations.of(context)!;

    Widget list(PostType? type) => FeedList(
      ref: ref,
      context: context,
      feedState: feedState,
      filterType: type,
      l10n: l10n,
      colorScheme: Theme.of(context).colorScheme,
    );

    // Sekme sırası: (segment etiketi, sayfa). Yeni sekme = yeni satır.
    final tabs = <(String, Widget)>[
      (l10n.feedFilterAll, list(null)),
      (l10n.feedFilterCases, list(PostType.casePost)),
      (l10n.feedFilterQuestions, list(PostType.question)),
      // İş ilanı türü henüz yok (yayın sonrası); sekme boş durum gösterir.
      (
        l10n.feedFilterJobs,
        Center(
          child: DentLinkEmptyState(
            icon: Icons.work_outline_rounded,
            title: l10n.feedJobsEmptyTitle,
            subtitle: l10n.feedJobsEmptySubtitle,
          ),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.bgGradientStart,
      // Üst bar gövdede: alt menüyle birlikte kayınca liste yukarı uzar.
      body: Column(
        children: [
          FeedScreenAppBar(
            labels: [for (final (label, _) in tabs) label],
            selectedIndex: _index,
            onSelected: _select,
            visibility: ref.watch(bottomBarAnimationProvider),
          ),
          Expanded(
            // Durum çubuğu payını üst bar aldı; listeler tekrar eklemesin.
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) {
                  if (!_animatingToTap) setState(() => _index = i);
                },
                children: [for (final (_, page) in tabs) page],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
