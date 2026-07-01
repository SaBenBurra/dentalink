import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';

class PostMedia extends StatefulWidget {
  const PostMedia({
    super.key,
    required this.imageUrls,
    required this.isLiked,
    required this.onLikeToggle,
    this.onTap,
  });

  final List<String> imageUrls;
  final bool isLiked;
  final VoidCallback onLikeToggle;
  final VoidCallback? onTap;

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
    if (widget.imageUrls.isEmpty)
      return const SizedBox.shrink(); // <-- Güvenlik kontrolü

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
                onTap: widget.onTap,
                onDoubleTap: _handleDoubleTap,
                child: CachedNetworkImage(
                  imageUrl: widget.imageUrls[index],
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
        if (widget.imageUrls.length > 1)
          Positioned(
            bottom: AppDimensions.spacing12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.imageUrls.length, (idx) {
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
