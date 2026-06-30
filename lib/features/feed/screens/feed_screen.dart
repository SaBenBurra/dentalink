import 'package:dentlink/features/feed/widgets/feed_screen_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../data/models/enums.dart';
import '../../../providers/feed_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_widget.dart';
import '../widgets/case_card.dart';
import '../widgets/question_card.dart';
import '../widgets/feed_skeleton.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _selectedFilterIndex = 0; // 0: All, 1: Cases, 2: Questions

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final feedState = ref.watch(feedProvider);

    final backgroundColor = isDark
        ? const Color(0xFF11211F)
        : AppColors.bgGradientStart;

    final glassBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.8);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            FeedScreenAppBar(
              isDark: isDark,
              glassBorderColor: glassBorderColor,
              textTheme: textTheme,
              colorScheme: colorScheme,
              tabController: _tabController,
              l10n: l10n,
            ),
          ];
        },
        body: Column(
          children: [
            _buildSegmentedFilter(context),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.read(feedProvider.notifier).refresh(),
                color: colorScheme.primary,
                child: feedState.when(
                  data: (posts) {
                    final filteredPosts = posts.where((post) {
                      if (_selectedFilterIndex == 1) {
                        return post.type == PostType.casePost;
                      } else if (_selectedFilterIndex == 2) {
                        return post.type == PostType.question;
                      }
                      return true;
                    }).toList();

                    if (filteredPosts.isEmpty) {
                      return CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverFillRemaining(
                            child: Center(
                              child: DentLinkEmptyState(
                                icon: Icons.dynamic_feed_outlined,
                                title: l10n.emptyFeed,
                                subtitle: _selectedFilterIndex != 0
                                    // <-- Aşağıdaki sabit metinler l10n'e taşınmalıdır
                                    ? 'Seçili filtreye uygun gönderi bulunamadı.'
                                    : 'Akışta henüz hiç paylaşım yapılmamış.',
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    // <-- ListView.builder yerine ListView.separated kullanıldı
                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacing16,
                        vertical: AppDimensions.spacing12,
                      ),
                      itemCount: filteredPosts.length,
                      separatorBuilder: (context, index) => const SizedBox(
                        height: AppDimensions.spacing16,
                      ), // <-- Liste öğeleri arası boşluk
                      itemBuilder: (context, index) {
                        final post = filteredPosts[index];
                        if (post.type == PostType.casePost) {
                          return CaseCard(
                            post: post,
                            onLikeToggle: () => ref
                                .read(feedProvider.notifier)
                                .toggleLike(post.id),
                            onBookmarkToggle: () => ref
                                .read(feedProvider.notifier)
                                .toggleBookmark(post.id),
                            onCommentTap: () {
                              context.push('/feed/case/${post.id}');
                            },
                            onTap: () {
                              context.push('/feed/case/${post.id}');
                            },
                          );
                        } else {
                          // <-- Padding sarmalayıcısı kaldırıldı
                          return QuestionCard(
                            post: post,
                            onLikeToggle: () => ref
                                .read(feedProvider.notifier)
                                .toggleLike(post.id),
                            onBookmarkToggle: () => ref
                                .read(feedProvider.notifier)
                                .toggleBookmark(post.id),
                            onCommentTap: () {
                              context.push('/feed/question/${post.id}');
                            },
                            onTap: () {
                              context.push('/feed/question/${post.id}');
                            },
                          );
                        }
                      },
                    );
                  },
                  loading: () => ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [FeedSkeleton()],
                  ),
                  error: (err, stack) => CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverFillRemaining(
                        child: DentLinkErrorWidget(
                          // <-- Aşağıdaki sabit metin l10n'e taşınmalıdır
                          message: 'Akış yüklenirken bir hata oluştu.',
                          onRetry: () =>
                              ref.read(feedProvider.notifier).refresh(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedFilter(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    final filterOptions = [
      l10n.feedFilterAll,
      l10n.feedFilterCases,
      l10n.feedFilterQuestions,
    ];

    final controlBgColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.4);
    final controlBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.6);

    return Padding(
      padding: const EdgeInsets.only(
        left: AppDimensions.spacing16,
        right: AppDimensions.spacing16,
        top: AppDimensions.spacing16,
        bottom: AppDimensions.spacing8,
      ),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: controlBgColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
          border: Border.all(color: controlBorderColor, width: 1),
        ),
        padding: const EdgeInsets.all(AppDimensions.spacing4),
        child: Row(
          children: List.generate(filterOptions.length, (index) {
            final isSelected = _selectedFilterIndex == index;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFilterIndex = index;
                  });
                },
                child: AnimatedContainer(
                  duration: AppDimensions.animFast,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusRound,
                    ),
                    color: isSelected
                        ? colorScheme.primary
                        : Colors.transparent,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: colorScheme.primary.withValues(
                                alpha: 0.25,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    filterOptions[index],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
