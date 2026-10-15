import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../providers/post_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/comment_provider.dart';
import '../../../shared/widgets/tag_chip.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../data/models/post_model.dart';
import '../widgets/detail/case_detail_comments.dart';
import '../widgets/detail/post_detail_author_info.dart';
import '../widgets/detail/post_detail_interaction_bar.dart';
import '../widgets/detail/detail_states.dart';
import '../../../core/error/app_failures.dart';
import '../../../shared/utils/error_messages.dart';
import '../../../shared/widgets/follow_button.dart';

class CaseDetailScreen extends ConsumerStatefulWidget {
  const CaseDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends ConsumerState<CaseDetailScreen> {
  late final TextEditingController _commentController;
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    try {
      await ref.read(commentsProvider(widget.postId).notifier).addComment(text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(getErrorMessage(e))),
        );
      }
      return;
    }

    if (mounted) {
      _commentController.clear();
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
          if (postModel is! CasePostModel) {
            return PostDetailError(message: getErrorMessage(const NotFoundFailure()));
          }
          final post = postModel;
          // Görselsiz vakada başka bir görsel gösterilmez (yanıltıcı tıbbi içerik).
          final imageUrls = post.imageUrls;

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
                    bottom: MediaQuery.of(context).padding.bottom + 80,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          AspectRatio(
                            aspectRatio: 1.2,
                            child: PageView.builder(
                              controller: _pageController,
                              onPageChanged: (idx) {
                                setState(() {
                                  _currentPage = idx;
                                });
                              },
                              itemCount: imageUrls.isEmpty ? 1 : imageUrls.length,
                              itemBuilder: (context, index) {
                                if (imageUrls.isEmpty) {
                                  return Center(
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      size: 48,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  );
                                }
                                return CachedNetworkImage(
                                  imageUrl: imageUrls[index],
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: isDark
                                        ? Colors.black26
                                        : Colors.white24,
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              AppColors.primary,
                                            ),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        color: isDark
                                            ? Colors.black26
                                            : Colors.white24,
                                        child: const Center(
                                          child: Icon(
                                            Icons.broken_image_outlined,
                                            size: 48,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                );
                              },
                            ),
                          ),
                          if (imageUrls.length > 1)
                            Positioned(
                              bottom: 36,
                              child: Row(
                                children: List.generate(imageUrls.length, (idx) {
                                  final isActive = _currentPage == idx;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isActive
                                          ? Colors.white
                                          : Colors.white.withValues(alpha: 0.5),
                                    ),
                                  );
                                }),
                              ),
                            ),
                        ],
                      ),
                      Transform.translate(
                        offset: const Offset(0, -24),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.6)
                                : Colors.white.withValues(alpha: 0.85),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(AppDimensions.radiusLarge),
                            ),
                            border: Border.all(
                              color: glassBorderColor,
                              width: 1,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.glassShadow,
                                blurRadius: 30,
                                offset: Offset(0, -10),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(AppDimensions.spacing16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              PostDetailAuthorInfo(
                                post: post,
                                trailing: currentUser?.id != post.userId
                                    ? FollowButton(
                                        userId: post.userId,
                                        style: ButtonStyle(
                                          shape: WidgetStatePropertyAll(
                                            RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                                            ),
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(height: AppDimensions.spacing20),
                              Text(
                                post.title,
                                style: textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: AppDimensions.spacing12),
                              Wrap(
                                spacing: AppDimensions.spacing6,
                                runSpacing: AppDimensions.spacing6,
                                children: [
                                  if (post.branch != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppDimensions.spacing12,
                                        vertical: AppDimensions.spacing4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primaryContainer
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(
                                          AppDimensions.radiusRound,
                                        ),
                                        border: Border.all(
                                          color: colorScheme.primary.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        post.branch!.displayName,
                                        style: textTheme.labelSmall?.copyWith(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ...post.tags.map(
                                    (tag) => TagChip(label: '#${tag.name}'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppDimensions.spacing20),
                              Text(
                                post.content,
                                style: textTheme.bodyLarge?.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextPrimary.withValues(alpha: 0.9)
                                      : AppColors.lightTextPrimary.withValues(alpha: 0.9),
                                  height: 1.6,
                                ),
                              ),
                              const SizedBox(height: AppDimensions.spacing24),
                              PostDetailInteractionBar(
                                post: post,
                                onLikeToggle: () => ref
                                    .read(postDetailProvider(widget.postId).notifier)
                                    .toggleLike(),
                              ),
                              const SizedBox(height: AppDimensions.spacing24),
                              CaseDetailComments(postId: widget.postId),
                            ],
                          ),
                        ),
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
                        onTap: () => popOrGoFeed(context),
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
                                  controller: _commentController,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Mesleki tartışmaya katılın...',
                                    border: InputBorder.none,
                                    isDense: true,
                                    hintStyle: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                  textInputAction: TextInputAction.send,
                                  onSubmitted: (_) => _submitComment(),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.send_rounded),
                                color: colorScheme.primary,
                                iconSize: 20,
                                onPressed: _submitComment,
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
        loading: () => const PostDetailLoading(),
        error: (err, stack) => PostDetailError(message: getErrorMessage(err)),
      ),
    );
  }
}
