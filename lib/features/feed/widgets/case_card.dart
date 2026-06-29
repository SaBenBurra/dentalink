import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../data/models/post_model.dart';
import '../../../shared/widgets/like_button.dart';
import '../../../shared/widgets/bookmark_button.dart';
import '../../../shared/widgets/tag_chip.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/widgets/relative_time_text.dart';

/// Stitch "Clinical Glass" tasarımından esinlenen Vaka Kartı (Case Card) widget'ı.
class CaseCard extends StatefulWidget {
  const CaseCard({
    super.key,
    required this.post,
    required this.onLikeToggle,
    required this.onBookmarkToggle,
    this.onCommentTap,
    this.onTap,
  });

  final PostModel post;
  final VoidCallback onLikeToggle;
  final VoidCallback onBookmarkToggle;
  final VoidCallback? onCommentTap;
  final VoidCallback? onTap;

  @override
  State<CaseCard> createState() => _CaseCardState();
}

class _CaseCardState extends State<CaseCard> with TickerProviderStateMixin {
  late final PageController _pageController;
  int _currentPage = 0;
  bool _showHeartPop = false;

  // Double tap heart pop animation
  late AnimationController _heartAnimController;
  late Animation<double> _heartScaleAnimation;
  late Animation<double> _heartOpacityAnimation;

  // X-ray placeholder image from Stitch HTML design
  static const String _placeholderXrayUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuAPl3lEc-lZWgnv5TAsSlfAgOpm0oO_QaSi9ubmfjaK_3B-D30x7l21Xssng_I_zQ_gCGuJDjVDckGgtEW7m4EdRjYww2ecYghimvtA4_qB6Sohj-0sqV_Vq125CIFwzuuCTYTRRoauzQsqYiBG_sDmnR5ypGD8oCVZgwKegW6csc-3MsdPRoUAYXVt08y6kP--KFFHeq4J-behHpP0EUo8jlEwgnS-wq98zyjHymKYzdBHbN1Gcym86xRFLJt477f6_b7Lgqmkn6H8';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _heartAnimController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _heartScaleAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.2, end: 1.3), weight: 40),
          TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 30),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 30),
        ]).animate(
          CurvedAnimation(
            parent: _heartAnimController,
            curve: Curves.easeInOut,
          ),
        );

    _heartOpacityAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 30),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 40),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
        ]).animate(
          CurvedAnimation(
            parent: _heartAnimController,
            curve: Curves.easeInOut,
          ),
        );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _heartAnimController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (!widget.post.isLiked) {
      widget.onLikeToggle();
    }
    setState(() {
      _showHeartPop = true;
    });
    _heartAnimController.forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _showHeartPop = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    final glassBgColor = isDark
        ? Colors.black.withValues(alpha: 0.4)
        : Colors.white.withValues(alpha: 0.6);
    final glassBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.8);

    final imageUrls = widget.post.imageUrls.isNotEmpty
        ? widget.post.imageUrls
        : [_placeholderXrayUrl];

    return Container(
      decoration: BoxDecoration(
        color: glassBgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: glassBorderColor, width: 1),
        boxShadow: const [
          BoxShadow(
            color: AppColors.glassShadow,
            blurRadius: 40,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header (Avatar, Name, Subtitle, Menu button)
              Padding(
                padding: const EdgeInsets.all(AppDimensions.spacing16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UserAvatar(
                      name: widget.post.author.fullName,
                      imageUrl: widget.post.author.avatarUrl,
                      size: AvatarSize.medium,
                    ),
                    const SizedBox(width: AppDimensions.spacing12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.post.author.fullName,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.spacing2),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  widget.post.branch?.displayName ??
                                      widget.post.author.title.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppDimensions.spacing6),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.4),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: AppDimensions.spacing6),
                              RelativeTimeText(dateTime: widget.post.createdAt),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Vaka Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacing10,
                        vertical: AppDimensions.spacing4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? colorScheme.primaryContainer.withValues(
                                alpha: 0.2,
                              )
                            : AppColors.primaryContainer.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusRound,
                        ),
                        border: Border.all(
                          color: isDark
                              ? colorScheme.primary.withValues(alpha: 0.3)
                              : AppColors.primaryContainer,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${l10n.casePost} 📸',
                        style: textTheme.labelSmall?.copyWith(
                          color: isDark
                              ? colorScheme.primaryContainer
                              : AppColors.primaryDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Content text
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacing16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.post.title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacing8),
                    Text(
                      widget.post.content,
                      style: textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary.withValues(alpha: 0.85)
                            : AppColors.lightTextPrimary.withValues(
                                alpha: 0.85,
                              ),
                        height: 1.5,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppDimensions.spacing12),

                    // Tags list
                    if (widget.post.tags.isNotEmpty) ...[
                      Wrap(
                        spacing: AppDimensions.spacing6,
                        runSpacing: AppDimensions.spacing6,
                        children: widget.post.tags.map((tag) {
                          return TagChip(
                            label: '#${tag.name}',
                            onTap: () {
                              // Filter by tag
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppDimensions.spacing16),
                    ],
                  ],
                ),
              ),

              // 3. Image Slider with double tap to like
              Stack(
                alignment: Alignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: 1.0, // Square image as in design
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (idx) {
                        setState(() {
                          _currentPage = idx;
                        });
                      },
                      itemCount: imageUrls.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: widget.onTap,
                          onDoubleTap: _handleDoubleTap,
                          child: CachedNetworkImage(
                            imageUrl: imageUrls[index],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: isDark ? Colors.black26 : Colors.white24,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: isDark ? Colors.black26 : Colors.white24,
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Swiper Indicator dots (only show if multiple images)
                  if (imageUrls.length > 1)
                    Positioned(
                      bottom: AppDimensions.spacing12,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(imageUrls.length, (idx) {
                          final isActive = _currentPage == idx;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3.0),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.5),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),

                  // Heart Pop overlay
                  if (_showHeartPop)
                    AnimatedBuilder(
                      animation: _heartAnimController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _heartScaleAnimation.value,
                          child: Opacity(
                            opacity: _heartOpacityAnimation.value,
                            child: child,
                          ),
                        );
                      },
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 100,
                        shadows: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              // 4. Action Row (Likes, Comments, Bookmark)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacing16,
                  vertical: AppDimensions.spacing8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        LikeButton(
                          isLiked: widget.post.isLiked,
                          likeCount: widget.post.likeCount,
                          onToggle: widget.onLikeToggle,
                        ),
                        const SizedBox(width: AppDimensions.spacing16),
                        InkWell(
                          onTap: widget.onCommentTap,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusRound,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppDimensions.spacing8,
                              horizontal: AppDimensions.spacing4,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: colorScheme.onSurfaceVariant,
                                  size: AppDimensions.iconDefault,
                                ),
                                const SizedBox(width: AppDimensions.spacing4),
                                Text(
                                  widget.post.commentCount.toString(),
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    BookmarkButton(
                      isBookmarked: widget.post.isBookmarked,
                      onToggle: widget.onBookmarkToggle,
                      bookmarkCount: widget.post.bookmarkCount,
                      showCount: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
