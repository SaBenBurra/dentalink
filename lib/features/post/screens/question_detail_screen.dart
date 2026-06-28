import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../providers/post_provider.dart';
import '../../../providers/comment_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/widgets/tag_chip.dart';
import '../../../shared/widgets/like_button.dart';
import '../../../shared/widgets/bookmark_button.dart';
import '../../../shared/widgets/relative_time_text.dart';

class QuestionDetailScreen extends ConsumerStatefulWidget {
  const QuestionDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<QuestionDetailScreen> createState() =>
      _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends ConsumerState<QuestionDetailScreen> {
  late final TextEditingController _answerController;

  @override
  void initState() {
    super.initState();
    _answerController = TextEditingController();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _submitAnswer() async {
    final text = _answerController.text.trim();
    if (text.isEmpty) return;

    try {
      await ref.read(commentsProvider(widget.postId).notifier).addComment(text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cevap eklenirken hata oluştu: $e')),
        );
      }
      return;
    }

    if (mounted) {
      _answerController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _handleMarkBestAnswer(String commentId) async {
    bool success = false;
    dynamic errorMsg;
    try {
      await ref
          .read(commentsProvider(widget.postId).notifier)
          .markBestAnswer(commentId);
      success = true;
    } catch (e) {
      errorMsg = e;
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('En iyi cevap başarıyla seçildi! 🎉'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('En iyi cevap seçilirken hata: $errorMsg')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final postAsync = ref.watch(postDetailProvider(widget.postId));
    final commentsAsync = ref.watch(commentsProvider(widget.postId));
    final currentUser = ref.watch(currentUserProvider);

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
      body: postAsync.when(
        data: (post) {
          final isPostOwner = currentUser?.id == post.userId;

          return Stack(
            children: [
              // Background gradients (same as FeedScreen for consistency)
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
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        (isDark ? AppColors.primaryLight : AppColors.primary)
                            .withValues(alpha: isDark ? 0.10 : 0.15),
                        (isDark ? AppColors.primaryLight : AppColors.primary)
                            .withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),

              // Scrollable Content
              Positioned.fill(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 76,
                    bottom: MediaQuery.of(context).padding.bottom + 80,
                    left: AppDimensions.spacing16,
                    right: AppDimensions.spacing16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Question Card (Glass panel)
                      Container(
                        decoration: BoxDecoration(
                          color: glassBgColor,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMedium,
                          ),
                          border: Border.all(color: glassBorderColor, width: 1),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.glassShadow,
                              blurRadius: 30,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(AppDimensions.spacing16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Author Header
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                UserAvatar(
                                  name: post.author.fullName,
                                  imageUrl: post.author.avatarUrl,
                                  size: AvatarSize.medium,
                                ),
                                const SizedBox(width: AppDimensions.spacing12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        post.author.fullName,
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? AppColors.darkTextPrimary
                                              : AppColors.lightTextPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              post.author.title.displayName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Text('•'),
                                          const SizedBox(width: 6),
                                          RelativeTimeText(
                                            dateTime: post.createdAt,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Question Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.secondaryContainer
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusRound,
                                    ),
                                    border: Border.all(
                                      color: colorScheme.secondary.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Soru ❓',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: colorScheme.secondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppDimensions.spacing16),

                            // Question Title
                            Text(
                              post.title,
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: AppDimensions.spacing12),

                            // Tags
                            if (post.tags.isNotEmpty) ...[
                              Wrap(
                                spacing: AppDimensions.spacing6,
                                runSpacing: AppDimensions.spacing6,
                                children: post.tags.map((tag) {
                                  return TagChip(label: '#${tag.name}');
                                }).toList(),
                              ),
                              const SizedBox(height: AppDimensions.spacing16),
                            ],

                            // Content Description
                            Text(
                              post.content,
                              style: textTheme.bodyMedium?.copyWith(
                                color: isDark
                                    ? AppColors.darkTextPrimary.withValues(
                                        alpha: 0.9,
                                      )
                                    : AppColors.lightTextPrimary.withValues(
                                        alpha: 0.9,
                                      ),
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: AppDimensions.spacing16),

                            // Interaction Bar
                            Container(
                              padding: const EdgeInsets.only(
                                top: AppDimensions.spacing12,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.black.withValues(alpha: 0.05),
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  LikeButton(
                                    isLiked: post.isLiked,
                                    likeCount: post.likeCount,
                                    onToggle: () => ref
                                        .read(
                                          postDetailProvider(
                                            widget.postId,
                                          ).notifier,
                                        )
                                        .toggleLike(),
                                  ),
                                  const SizedBox(
                                    width: AppDimensions.spacing24,
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.chat_bubble_outline_rounded,
                                        color: colorScheme.onSurfaceVariant,
                                        size: AppDimensions.iconDefault,
                                      ),
                                      const SizedBox(
                                        width: AppDimensions.spacing6,
                                      ),
                                      Text(
                                        post.commentCount.toString(),
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  BookmarkButton(
                                    isBookmarked: post.isBookmarked,
                                    onToggle: () => ref
                                        .read(
                                          postDetailProvider(
                                            widget.postId,
                                          ).notifier,
                                        )
                                        .toggleBookmark(),
                                    bookmarkCount: post.bookmarkCount,
                                    showCount: false,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacing24),

                      // 2. Answers Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          commentsAsync.when(
                            data: (comments) => Text(
                              'Cevaplar (${comments.length})',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                            loading: () => Text(
                              'Cevaplar',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                            error: (err, stack) => const SizedBox.shrink(),
                          ),
                          Row(
                            children: [
                              Text(
                                'Sıralama: En İyi',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Icon(
                                Icons.expand_more_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spacing16),

                      // 3. Answers List
                      commentsAsync.when(
                        data: (comments) {
                          if (comments.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 36),
                              alignment: Alignment.center,
                              child: Text(
                                'Henüz cevap yazılmamış. İlk siz cevaplayın!',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              final comment = comments[index];
                              final isBest = comment.isBestAnswer;

                              return Container(
                                margin: const EdgeInsets.only(
                                  bottom: AppDimensions.spacing16,
                                ),
                                decoration: BoxDecoration(
                                  color: isBest
                                      ? (isDark
                                            ? AppColors.primary.withValues(
                                                alpha: 0.1,
                                              )
                                            : AppColors.successLight.withValues(
                                                alpha: 0.3,
                                              ))
                                      : glassBgColor,
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusMedium,
                                  ),
                                  border: isBest
                                      ? Border.all(
                                          color: AppColors.success,
                                          width: 1.5,
                                        )
                                      : Border.all(
                                          color: glassBorderColor,
                                          width: 1,
                                        ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: AppColors.glassShadow,
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(
                                  AppDimensions.spacing16,
                                ),
                                child: Stack(
                                  children: [
                                    // Best Answer Tag at top-right
                                    if (isBest)
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.success.withValues(
                                              alpha: 0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            border: Border.all(
                                              color: AppColors.success
                                                  .withValues(alpha: 0.4),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.verified_rounded,
                                                size: 12,
                                                color: AppColors.success,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'En İyi Cevap',
                                                style: textTheme.labelSmall
                                                    ?.copyWith(
                                                      color: AppColors.success,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 10,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Answerer Header
                                        Row(
                                          children: [
                                            UserAvatar(
                                              name: comment.author.fullName,
                                              imageUrl:
                                                  comment.author.avatarUrl,
                                              size: AvatarSize.small,
                                            ),
                                            const SizedBox(
                                              width: AppDimensions.spacing12,
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    comment.author.fullName,
                                                    style: textTheme.titleSmall
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: isDark
                                                              ? AppColors
                                                                    .darkTextPrimary
                                                              : AppColors
                                                                    .lightTextPrimary,
                                                        ),
                                                  ),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        comment
                                                            .author
                                                            .title
                                                            .displayName,
                                                        style: textTheme
                                                            .bodySmall
                                                            ?.copyWith(
                                                              color: colorScheme
                                                                  .onSurfaceVariant,
                                                              fontSize: 11,
                                                            ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      const Text(
                                                        '•',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      RelativeTimeText(
                                                        dateTime:
                                                            comment.createdAt,
                                                        style: textTheme
                                                            .bodySmall
                                                            ?.copyWith(
                                                              fontSize: 11,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                          height: AppDimensions.spacing12,
                                        ),

                                        // Content
                                        Text(
                                          comment.content,
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: isDark
                                                ? AppColors.darkTextPrimary
                                                : AppColors.lightTextPrimary,
                                            height: 1.5,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: AppDimensions.spacing16,
                                        ),

                                        // Actions
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                GestureDetector(
                                                  onTap: () => ref
                                                      .read(
                                                        commentsProvider(
                                                          widget.postId,
                                                        ).notifier,
                                                      )
                                                      .toggleLike(comment.id),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 6,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: comment.isLiked
                                                          ? colorScheme.primary
                                                                .withValues(
                                                                  alpha: 0.1,
                                                                )
                                                          : Colors.transparent,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            AppDimensions
                                                                .radiusRound,
                                                          ),
                                                      border: Border.all(
                                                        color: comment.isLiked
                                                            ? colorScheme
                                                                  .primary
                                                                  .withValues(
                                                                    alpha: 0.3,
                                                                  )
                                                            : Colors
                                                                  .transparent,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          comment.isLiked
                                                              ? Icons
                                                                    .favorite_rounded
                                                              : Icons
                                                                    .favorite_border_rounded,
                                                          size: 14,
                                                          color: comment.isLiked
                                                              ? AppColors.like
                                                              : colorScheme
                                                                    .onSurfaceVariant,
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          comment.likeCount
                                                              .toString(),
                                                          style: textTheme
                                                              .bodySmall
                                                              ?.copyWith(
                                                                fontSize: 11,
                                                                color:
                                                                    comment
                                                                        .isLiked
                                                                    ? AppColors
                                                                          .like
                                                                    : colorScheme
                                                                          .onSurfaceVariant,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),

                                            // "Mark as Best Answer" button for the question owner
                                            if (isPostOwner && !isBest)
                                              TextButton.icon(
                                                onPressed: () =>
                                                    _handleMarkBestAnswer(
                                                      comment.id,
                                                    ),
                                                icon: const Icon(
                                                  Icons.verified_rounded,
                                                  size: 14,
                                                ),
                                                label: const Text(
                                                  'En İyi Cevap Seç',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                  ),
                                                ),
                                                style: TextButton.styleFrom(
                                                  foregroundColor:
                                                      AppColors.success,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                      ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(36),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        error: (err, stack) =>
                            Text('Cevaplar yüklenemedi: $err'),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Floating Header (Arrow Back & Bookmark)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 8,
                    bottom: 8,
                    left: AppDimensions.spacing16,
                    right: AppDimensions.spacing16,
                  ),
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: glassBgColor,
                            border: Border.all(color: glassBorderColor),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                      Text(
                        'Soru Detayı',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => ref
                            .read(postDetailProvider(widget.postId).notifier)
                            .toggleBookmark(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: glassBgColor,
                            border: Border.all(color: glassBorderColor),
                          ),
                          child: Icon(
                            post.isBookmarked
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            size: 20,
                            color: post.isBookmarked
                                ? AppColors.bookmark
                                : (isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 5. Sticky Bottom Answer Input
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    left: AppDimensions.spacing16,
                    right: AppDimensions.spacing16,
                    top: 12,
                    bottom: MediaQuery.of(context).padding.bottom + 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.85)
                        : Colors.white.withValues(alpha: 0.92),
                    border: Border(
                      top: BorderSide(color: glassBorderColor, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      UserAvatar(
                        name: currentUser?.fullName ?? 'Hekim',
                        imageUrl: currentUser?.avatarUrl,
                        size: AvatarSize.small,
                      ),
                      const SizedBox(width: AppDimensions.spacing12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusRound,
                            ),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.08),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 2,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _answerController,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Cevabınızı buraya yazın...',
                                    border: InputBorder.none,
                                    isDense: true,
                                    hintStyle: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                  textInputAction: TextInputAction.send,
                                  onSubmitted: (_) => _submitAnswer(),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.send_rounded),
                                color: colorScheme.primary,
                                iconSize: 20,
                                onPressed: _submitAnswer,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text('Soru yüklenirken hata oluştu: $err'),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Geri Dön'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
