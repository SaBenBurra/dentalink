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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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

    final backgroundColor =
        isDark ? const Color(0xFF11211F) : AppColors.bgGradientStart;

    final glassBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.8);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              floating: true,
              pinned: true,
              snap: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.85)
                      : Colors.white.withValues(alpha: 0.92),
                  border: Border(
                    bottom: BorderSide(color: glassBorderColor, width: 1),
                  ),
                ),
              ),
              title: Text(
                'Dentlink',
                style: textTheme.titleLarge?.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded),
                  onPressed: () => context.push('/notifications'),
                  color: colorScheme.primary,
                  tooltip: 'Notifications',
                ),
                const SizedBox(width: AppDimensions.spacing8),
              ],
              bottom: TabBar(
                controller: _tabController,
                labelColor: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
                unselectedLabelColor: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                indicatorColor: colorScheme.primary,
                indicatorWeight: 2.5,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: Colors.transparent,
                splashFactory: NoSplash.splashFactory,
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                tabAlignment: TabAlignment.start,
                isScrollable: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacing8,
                ),
                labelPadding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacing12,
                ),
                tabs: [
                  Tab(text: l10n.feedFilterAll),
                  Tab(text: l10n.feedFilterCases),
                  Tab(text: l10n.feedFilterQuestions),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildFeedList(context, feedState, null, l10n, colorScheme),
            _buildFeedList(
              context, feedState, PostType.casePost, l10n, colorScheme,
            ),
            _buildFeedList(
              context, feedState, PostType.question, l10n, colorScheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedList(
    BuildContext context,
    AsyncValue feedState,
    PostType? filterType,
    AppLocalizations l10n,
    ColorScheme colorScheme,
  ) {
    return RefreshIndicator(
      onRefresh: () => ref.read(feedProvider.notifier).refresh(),
      color: colorScheme.primary,
      child: feedState.when(
        data: (posts) {
          final filteredPosts = filterType == null
              ? posts
              : posts.where((post) => post.type == filterType).toList();

          if (filteredPosts.isEmpty) {
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  child: Center(
                    child: DentLinkEmptyState(
                      icon: Icons.dynamic_feed_outlined,
                      title: l10n.emptyFeed,
                      subtitle: filterType != null
                          ? 'Seçili filtreye uygun gönderi bulunamadı.'
                          : 'Akışta henüz hiç paylaşım yapılmamış.',
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacing16,
              vertical: AppDimensions.spacing12,
            ),
            itemCount: filteredPosts.length,
            separatorBuilder: (context, index) => const SizedBox(
              height: AppDimensions.spacing16,
            ),
            itemBuilder: (context, index) {
              final post = filteredPosts[index];
              if (post.type == PostType.casePost) {
                return CaseCard(
                  post: post,
                  onLikeToggle: () =>
                      ref.read(feedProvider.notifier).toggleLike(post.id),
                  onBookmarkToggle: () =>
                      ref.read(feedProvider.notifier).toggleBookmark(post.id),
                  onCommentTap: () => context.push('/feed/case/${post.id}'),
                  onTap: () => context.push('/feed/case/${post.id}'),
                );
              } else {
                return QuestionCard(
                  post: post,
                  onLikeToggle: () =>
                      ref.read(feedProvider.notifier).toggleLike(post.id),
                  onBookmarkToggle: () =>
                      ref.read(feedProvider.notifier).toggleBookmark(post.id),
                  onCommentTap: () =>
                      context.push('/feed/question/${post.id}'),
                  onTap: () => context.push('/feed/question/${post.id}'),
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
                message: 'Akış yüklenirken bir hata oluştu.',
                onRetry: () => ref.read(feedProvider.notifier).refresh(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
