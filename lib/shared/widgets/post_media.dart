import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import 'fullscreen_image_viewer.dart';

class PostMedia extends StatefulWidget {
  const PostMedia({
    super.key,
    required this.imageUrls,
    required this.isLiked,
    required this.onLikeToggle,
  });

  final List<String> imageUrls;
  final bool isLiked;
  final VoidCallback onLikeToggle;

  @override
  State<PostMedia> createState() => _PostMediaState();
}

class _PostMediaState extends State<PostMedia> with TickerProviderStateMixin {
  late final PageController _pageController;
  int _currentPage = 0;
  bool _showHeartPop = false;

  late AnimationController _heartAnimController;
  late Animation<double> _heartScaleAnimation;
  late Animation<double> _heartOpacityAnimation;

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

  // Sayaç ve noktaların zemini: açık görselde koyu dolgu, koyu görselde ince açık kenar seçilir.
  static final _scrim = BoxDecoration(
    color: Colors.black.withValues(alpha: 0.55),
    border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 0.5),
    borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
  );

  @override
  void dispose() {
    _pageController.dispose();
    _heartAnimController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (!widget.isLiked) {
      widget.onLikeToggle();
    }
    setState(() => _showHeartPop = true);
    _heartAnimController.forward(from: 0).then((_) {
      if (mounted) setState(() => _showHeartPop = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return const SizedBox.shrink(); // <-- Güvenlik kontrolü
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: 1.0,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (idx) => setState(() => _currentPage = idx),
            itemCount: widget.imageUrls.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => openFullscreenImages(
                  context,
                  widget.imageUrls,
                  initialIndex: index,
                ),
                onDoubleTap: _handleDoubleTap,
                child: CachedNetworkImage(
                  imageUrl: widget.imageUrls[index],
                  // İmzalı URL her çekişte değişir; önbellek dosya yoluna bağlı (SEC-9).
                  cacheKey: Uri.parse(widget.imageUrls[index]).path,
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
        if (widget.imageUrls.length > 1) ...[
          // Kaydırılabilir olduğu belli olsun: köşede sayaç, aktif nokta uzar.
          Positioned(
            top: AppDimensions.spacing12,
            right: AppDimensions.spacing12,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacing8,
                vertical: 3,
              ),
              decoration: _scrim,
              child: Text(
                '${_currentPage + 1}/${widget.imageUrls.length}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: AppDimensions.spacing12,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacing4,
                vertical: AppDimensions.spacing4,
              ),
              decoration: _scrim,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(widget.imageUrls.length, (idx) {
                  final isActive = _currentPage == idx;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.symmetric(horizontal: 3.0),
                    width: isActive ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusRound,
                      ),
                      color: isActive
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
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
    );
  }
}
