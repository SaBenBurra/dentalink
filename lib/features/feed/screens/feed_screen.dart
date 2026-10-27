import 'package:dentlink/features/feed/widgets/feed_list.dart';
import 'package:dentlink/features/feed/widgets/feed_screen_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motor/motor.dart' show BoundedSingleMotionController;
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

class _FeedScreenState extends ConsumerState<FeedScreen>
    with SingleTickerProviderStateMixin {
  final _pageController = PageController();
  int _index = 0;
  // Segmente dokununca sayfa ara sayfalardan geçer; o sırada gelen
  // onPageChanged seçimi geri çekmesin.
  bool _animatingToTap = false;

  // Gizli üst bar sekme kaydırması başlayınca açılır (alt menü gizli kalır),
  // aşağı kaydırınca yeniden gizlenir.
  late final _reveal = BoundedSingleMotionController(
    motion: const BottomBarMotion.cupertino(
      preset: barMotionPreset,
      duration: barMotionDuration,
    ).resolveMotion(),
    vsync: this,
  );
  late final _headerVisibility = AnimationMax<double>(
    ref.read(bottomBarAnimationProvider),
    _reveal,
  );
  // Segment göstergesi sayfayı parmakla birlikte izler.
  final _pagePosition = ValueNotifier<double>(0);
  bool _headerPinned = false;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_onPageScroll);
  }

  @override
  void dispose() {
    _pagePosition.dispose();
    _reveal.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageScroll() {
    _pagePosition.value = _pageController.page ?? 0;
    if (!_headerPinned) {
      _headerPinned = true;
      _reveal.animateTo(1);
    }
  }

  bool _onVerticalScroll(ScrollUpdateNotification n) {
    if (_headerPinned &&
        n.metrics.axis == Axis.vertical &&
        (n.scrollDelta ?? 0) > 0) {
      _headerPinned = false;
      _reveal.animateTo(0, forward: false);
    }
    return false;
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
            visibility: _headerVisibility,
            position: _pagePosition,
          ),
          Expanded(
            // Durum çubuğu payını üst bar aldı; listeler tekrar eklemesin.
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: NotificationListener<ScrollUpdateNotification>(
                onNotification: _onVerticalScroll,
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (i) {
                    if (!_animatingToTap) setState(() => _index = i);
                  },
                  children: [
                    for (final (_, page) in tabs) _KeepAlive(child: page),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// PageView ekran dışındaki sayfayı atar; sekmeye dönünce kaydırma konumu ve
/// açılmış "devamını oku"lar kaybolmasın diye sayfa canlı tutulur.
class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
