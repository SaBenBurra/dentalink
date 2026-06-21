import 'dart:ui';
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
import '../../../shared/widgets/relative_time_text.dart';

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
  bool _isFollowing = false; // Mock local state

  static const String _placeholderXrayUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuAPl3lEc-lZWgnv5TAsSlfAgOpm0oO_QaSi9ubmfjaK_3B-D30x7l21Xssng_I_zQ_gCGuJDjVDckGgtEW7m4EdRjYww2ecYghimvtA4_qB6Sohj-0sqV_Vq125CIFwzuuCTYTRRoauzQsqYiBG_sDmnR5ypGD8oCVZgwKegW6csc-3MsdPRoUAYXVt08y6kP--KFFHeq4J-behHpP0EUo8jlEwgnS-wq98zyjHymKYzdBHbN1Gcym86xRFLJt477f6_b7Lgqmkn6H8';

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
          SnackBar(content: Text('Yorum eklenirken hata oluştu: $e')),
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
          final imageUrls = post.imageUrls.isNotEmpty
              ? post.imageUrls
              : [_placeholderXrayUrl];

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

              // Scrollable Content
              Positioned.fill(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 80,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Image Slider with Carousel
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
                              itemCount: imageUrls.length,
                              itemBuilder: (context, index) {
                                return Image.network(
                                  imageUrls[index],
                                  fit: BoxFit.cover,
                                );
                              },
                            ),
                          ),
                          // Carousel indicators
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

                      // 2. Overlapping Card
                      Transform.translate(
                        offset: const Offset(0, -24),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.85),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(AppDimensions.radiusLarge),
                            ),
                            border: Border.all(color: glassBorderColor, width: 1),
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
                              // Author info and follow button
                              Row(
                                children: [
                                  UserAvatar(
                                    name: post.author.fullName,
                                    imageUrl: post.author.avatarUrl,
                                    size: AvatarSize.medium,
                                  ),
                                  const SizedBox(width: AppDimensions.spacing12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          post.author.fullName,
                                          style: textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Text(
                                              post.branch?.displayName ?? post.author.title.displayName,
                                              style: textTheme.bodySmall?.copyWith(
                                                color: colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            const Text('•'),
                                            const SizedBox(width: 6),
                                            RelativeTimeText(dateTime: post.createdAt),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Follow Button (only show if not current user)
                                  if (currentUser?.id != post.userId)
                                    OutlinedButton(
                                      onPressed: () {
                                        setState(() {
                                          _isFollowing = !_isFollowing;
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(_isFollowing
                                                ? 'Dr. ${post.author.fullName.split(' ').last} takip ediliyor.'
                                                : 'Takip bırakıldı.'),
                                            duration: const Duration(seconds: 1),
                                          ),
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: colorScheme.primary,
                                        side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.5)),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                      ),
                                      child: Text(
                                        _isFollowing ? 'Takip Ediliyor' : 'Takip Et',
                                        style: textTheme.labelMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: AppDimensions.spacing20),

                              // Title
                              Text(
                                post.title,
                                style: textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: AppDimensions.spacing12),

                              // Branch Tag and other tags
                              Wrap(
                                spacing: AppDimensions.spacing6,
                                runSpacing: AppDimensions.spacing6,
                                children: [
                                  if (post.branch != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primaryContainer.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                                        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        post.branch!.displayName,
                                        style: textTheme.labelSmall?.copyWith(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ...post.tags.map((tag) => TagChip(
                                        label: '#${tag.name}',
                                      )),
                                ],
                              ),
                              const SizedBox(height: AppDimensions.spacing20),

                              // Description Content
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

                              // Interaction Bar
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacing12),
                                decoration: BoxDecoration(
                                  border: Border.symmetric(
                                    horizontal: BorderSide(
                                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    LikeButton(
                                      isLiked: post.isLiked,
                                      likeCount: post.likeCount,
                                      onToggle: () => ref.read(postDetailProvider(widget.postId).notifier).toggleLike(),
                                    ),
                                    const SizedBox(width: AppDimensions.spacing24),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.chat_bubble_outline_rounded,
                                          color: colorScheme.onSurfaceVariant,
                                          size: AppDimensions.iconDefault,
                                        ),
                                        const SizedBox(width: AppDimensions.spacing6),
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
                                    IconButton(
                                      icon: const Icon(Icons.share_outlined),
                                      color: colorScheme.onSurfaceVariant,
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Bağlantı kopyalandı!')),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppDimensions.spacing24),

                              // Peer Discussion / Comments Section
                              Text(
                                'Mesleki Tartışma',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: AppDimensions.spacing16),

                              commentsAsync.when(
                                data: (comments) {
                                  if (comments.isEmpty) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(vertical: 24),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Henüz yorum yapılmamış. İlk yorumu siz ekleyin!',
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
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: AppDimensions.spacing16),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            UserAvatar(
                                              name: comment.author.fullName,
                                              imageUrl: comment.author.avatarUrl,
                                              size: AvatarSize.small,
                                            ),
                                            const SizedBox(width: AppDimensions.spacing12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      color: isDark
                                                          ? Colors.white.withValues(alpha: 0.04)
                                                          : Colors.black.withValues(alpha: 0.03),
                                                      borderRadius: const BorderRadius.only(
                                                        topRight: Radius.circular(AppDimensions.radiusMedium),
                                                        bottomLeft: Radius.circular(AppDimensions.radiusMedium),
                                                        bottomRight: Radius.circular(AppDimensions.radiusMedium),
                                                      ),
                                                      border: Border.all(color: glassBorderColor.withValues(alpha: 0.3)),
                                                    ),
                                                    padding: const EdgeInsets.all(AppDimensions.spacing12),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                          children: [
                                                            Text(
                                                              comment.author.fullName,
                                                              style: textTheme.labelMedium?.copyWith(
                                                                fontWeight: FontWeight.bold,
                                                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                                              ),
                                                            ),
                                                            RelativeTimeText(
                                                              dateTime: comment.createdAt,
                                                              style: textTheme.bodySmall?.copyWith(fontSize: 10),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(height: 6),
                                                        Text(
                                                          comment.content,
                                                          style: textTheme.bodyMedium?.copyWith(
                                                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  // Comment actions (like comment)
                                                  Padding(
                                                    padding: const EdgeInsets.only(left: 4, top: 4),
                                                    child: Row(
                                                      children: [
                                                        GestureDetector(
                                                          onTap: () => ref
                                                              .read(commentsProvider(widget.postId).notifier)
                                                              .toggleLike(comment.id),
                                                          child: Padding(
                                                            padding: const EdgeInsets.all(4),
                                                            child: Row(
                                                              children: [
                                                                Icon(
                                                                  comment.isLiked
                                                                      ? Icons.favorite_rounded
                                                                      : Icons.favorite_border_rounded,
                                                                  size: 14,
                                                                  color: comment.isLiked
                                                                      ? AppColors.like
                                                                      : colorScheme.onSurfaceVariant,
                                                                ),
                                                                const SizedBox(width: 4),
                                                                Text(
                                                                  comment.likeCount.toString(),
                                                                  style: textTheme.bodySmall?.copyWith(
                                                                    fontSize: 11,
                                                                    color: comment.isLiked
                                                                        ? AppColors.like
                                                                        : colorScheme.onSurfaceVariant,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                                loading: () => const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(24),
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                                error: (err, stack) => Text('Yorumlar yüklenemedi: $err'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Floating Custom Transparent Header (Arrow Back & Bookmark)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 8,
                        bottom: 8,
                        left: AppDimensions.spacing16,
                        right: AppDimensions.spacing16,
                      ),
                      color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.1),
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
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => ref.read(postDetailProvider(widget.postId).notifier).toggleBookmark(),
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
                                    : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 4. Sticky Bottom Comment Input
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: EdgeInsets.only(
                        left: AppDimensions.spacing16,
                        right: AppDimensions.spacing16,
                        top: 12,
                        bottom: MediaQuery.of(context).padding.bottom + 12,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.8),
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
                                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                                border: Border.all(
                                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _commentController,
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                      ),
                                      decoration: const InputDecoration(
                                        hintText: 'Mesleki tartışmaya katılın...',
                                        border: InputBorder.none,
                                        isDense: true,
                                        hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
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
                ),
              ),
            ],
          );
        },
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        error: (err, stack) => Scaffold(
          appBar: AppBar(title: const Text('Hata')),
          body: Center(
            child: Text('Vaka yüklenirken hata oluştu: $err'),
          ),
        ),
      ),
    );
  }
}
