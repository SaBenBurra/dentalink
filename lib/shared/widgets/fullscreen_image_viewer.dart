import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_dimensions.dart';

/// Post görsellerini tam ekranda, kaydırılabilir ve yakınlaştırılabilir açar.
void openFullscreenImages(
  BuildContext context,
  List<String> imageUrls, {
  int initialIndex = 0,
}) {
  // Kök navigator: alt menünün de üstünü kaplar.
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => FullscreenImageViewer(
        imageUrls: imageUrls,
        initialIndex: initialIndex,
      ),
    ),
  );
}

class FullscreenImageViewer extends StatefulWidget {
  const FullscreenImageViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  final List<String> imageUrls;
  final int initialIndex;

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.imageUrls.length;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        leading: const CloseButton(),
        title: count > 1 ? Text('${_index + 1} / $count') : null,
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: PageView.builder(
        controller: _controller,
        itemCount: count,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) => InteractiveViewer(
          maxScale: 4,
          child: Center(
            child: CachedNetworkImage(
              imageUrl: widget.imageUrls[i],
              // İmzalı URL her çekişte değişir; önbellek dosya yoluna bağlı (SEC-9).
              cacheKey: Uri.parse(widget.imageUrls[i]).path,
              fit: BoxFit.contain,
              placeholder: (_, _) => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              errorWidget: (_, _, _) => const Icon(
                Icons.broken_image_outlined,
                size: AppDimensions.spacing48,
                color: Colors.white54,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
