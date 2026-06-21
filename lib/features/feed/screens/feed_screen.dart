import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class _FeedScreenState extends ConsumerState<FeedScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _selectedFilterIndex = 0; // 0: All, 1: Cases, 2: Questions

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // TabController listener to update feed mode in provider
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final newMode = _tabController.index == 0
            ? FeedMode.chronological
            : FeedMode.algorithmic;
        ref.read(feedProvider.notifier).switchMode(newMode);
      }
    });
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

    final glassBgColor = isDark
        ? Colors.black.withValues(alpha: 0.4)
        : Colors.white.withValues(alpha: 0.6);
    final glassBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.8);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // 1. Background Gradients and Decorative Blurred Circles (Matching login style)
          if (!isDark)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.bgGradientStart,
                      AppColors.bgGradientEnd,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),

          Positioned(
            left: -100,
            top: -100,
            width: 300,
            height: 300,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? AppColors.primaryLight : AppColors.primary)
                    .withValues(alpha: isDark ? 0.08 : 0.12),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: const SizedBox.shrink(),
              ),
            ),
          ),

          Positioned(
            right: -100,
            bottom: 100,
            width: 350,
            height: 350,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? AppColors.secondaryLight : AppColors.secondary)
                    .withValues(alpha: isDark ? 0.06 : 0.10),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                child: const SizedBox.shrink(),
              ),
            ),
          ),

          // 2. Main Content
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  floating: true,
                  pinned: true,
                  snap: true,
                  expandedHeight: 120.0,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  surfaceTintColor: Colors.transparent,
                  flexibleSpace: ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: glassBgColor,
                          border: Border(
                            bottom: BorderSide(
                              color: glassBorderColor,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    'Feed',
                    style: textTheme.titleLarge?.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none_rounded),
                      onPressed: () {},
                      color: colorScheme.primary,
                      tooltip: 'Notifications',
                    ),
                    const SizedBox(width: AppDimensions.spacing8),
                  ],
                  bottom: TabBar(
                    controller: _tabController,
                    indicatorColor: colorScheme.primary,
                    labelColor: colorScheme.primary,
                    unselectedLabelColor: colorScheme.onSurfaceVariant,
                    labelStyle: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: textTheme.labelLarge,
                    tabs: [
                      Tab(text: l10n.feedChronological),
                      Tab(text: l10n.feedAlgorithmic),
                    ],
                  ),
                ),
              ];
            },
            body: Column(
              children: [
                // Horizontal Segmented Control Filter below AppBar
                _buildSegmentedFilter(context),

                // Feed List
                Expanded(
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
                        return Center(
                          child: DentLinkEmptyState(
                            icon: Icons.dynamic_feed_outlined,
                            title: l10n.emptyFeed,
                            subtitle: _selectedFilterIndex != 0
                                ? 'Seçili filtreye uygun gönderi bulunamadı.'
                                : 'Akışta henüz hiç paylaşım yapılmamış.',
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () => ref.read(feedProvider.notifier).refresh(),
                        color: colorScheme.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spacing16,
                            vertical: AppDimensions.spacing12,
                          ),
                          itemCount: filteredPosts.length,
                          itemBuilder: (context, index) {
                            final post = filteredPosts[index];
                            if (post.type == PostType.casePost) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: AppDimensions.spacing16),
                                child: CaseCard(
                                  post: post,
                                  onLikeToggle: () => ref
                                      .read(feedProvider.notifier)
                                      .toggleLike(post.id),
                                  onBookmarkToggle: () => ref
                                      .read(feedProvider.notifier)
                                      .toggleBookmark(post.id),
                                  onCommentTap: () {
                                    // Navigate to comments / details
                                  },
                                  onTap: () {
                                    // Navigate to details
                                  },
                                ),
                              );
                            } else {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: AppDimensions.spacing16),
                                child: QuestionCard(
                                  post: post,
                                  onLikeToggle: () => ref
                                      .read(feedProvider.notifier)
                                      .toggleLike(post.id),
                                  onBookmarkToggle: () => ref
                                      .read(feedProvider.notifier)
                                      .toggleBookmark(post.id),
                                  onCommentTap: () {
                                    // Navigate to comments / details
                                  },
                                  onTap: () {
                                    // Navigate to details
                                  },
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                    loading: () => const FeedSkeleton(),
                    error: (err, stack) => DentLinkErrorWidget(
                      message: 'Akış yüklenirken bir hata oluştu.',
                      onRetry: () => ref.read(feedProvider.notifier).refresh(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
        padding: const EdgeInsets.all(4),
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
                    borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                    color: isSelected
                        ? colorScheme.primary
                        : Colors.transparent,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.25),
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
