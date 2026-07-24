import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../providers/post_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/comment_provider.dart';
import '../../../shared/widgets/tag_chip.dart';
import '../../../shared/widgets/bookmark_button.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../data/models/post_model.dart';
import '../widgets/detail/question_detail_answers.dart';
import '../widgets/detail/post_detail_author_info.dart';
import '../widgets/detail/post_detail_interaction_bar.dart';

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final postAsync = ref.watch(postDetailProvider(widget.postId));
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
        data: (postModel) {
          final post = postModel as QuestionPostModel;
          final isPostOwner = currentUser?.id == post.userId;

          return Stack(
            children: [
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
                            PostDetailAuthorInfo(
                              post: post,
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppDimensions.spacing10,
                                  vertical: AppDimensions.spacing4,
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
                            ),
                            const SizedBox(height: AppDimensions.spacing16),
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
                            Text(
                              post.content,
                              style: textTheme.bodyMedium?.copyWith(
                                color: isDark
                                    ? AppColors.darkTextPrimary.withValues(alpha: 0.9)
                                    : AppColors.lightTextPrimary.withValues(alpha: 0.9),
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: AppDimensions.spacing16),
                            PostDetailInteractionBar(
                              post: post,
                              onLikeToggle: () => ref
                                  .read(postDetailProvider(widget.postId).notifier)
                                  .toggleLike(),
                              trailing: BookmarkButton(
                                isBookmarked: post.isBookmarked,
                                onToggle: () => ref
                                    .read(postDetailProvider(widget.postId).notifier)
                                    .toggleBookmark(),
                                bookmarkCount: post.bookmarkCount,
                                showCount: false,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacing24),
                      QuestionDetailAnswers(
                        postId: widget.postId,
                        isPostOwner: isPostOwner,
                      ),
                    ],
                  ),
                ),
              ),
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
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    left: AppDimensions.spacing16,
                    right: AppDimensions.spacing16,
                    top: AppDimensions.spacing12,
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
                            horizontal: AppDimensions.spacing16,
                            vertical: AppDimensions.spacing2,
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
                                    hintText: 'Cevabınızı yazın...',
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
              const SizedBox(height: AppDimensions.spacing16),
              Text('Soru yüklenirken hata oluştu: $err'),
              const SizedBox(height: AppDimensions.spacing16),
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
