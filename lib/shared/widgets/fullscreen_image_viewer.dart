import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../data/models/post_model.dart';
import 'fullscreen_video_player.dart';

/// Post medyasını tam ekranda, kaydırılabilir açar. Görseller yakınlaştırılır;
/// video kapak resmi ve oynat simgesiyle görünür, dokununca oynatıcı açılır.
void openFullscreenImages(
  BuildContext context,
  List<PostMediaItem> media, {
  int initialIndex = 0,
}) {
  // Kök navigator: alt menünün de üstünü kaplar.
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) =>
          FullscreenImageViewer(media: media, initialIndex: initialIndex),
    ),
  );
}

class FullscreenImageViewer extends StatefulWidget {
  const FullscreenImageViewer({
    super.key,
    required this.media,
    this.initialIndex = 0,
  });

  final List<PostMediaItem> media;
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
    final count = widget.media.length;
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
        itemBuilder: (context, i) {
          final m = widget.media[i];
          final image = Center(
            child: CachedNetworkImage(
              imageUrl: m.url,
              // İmzalı URL her çekişte değişir; önbellek dosya yoluna bağlı (SEC-9).
              cacheKey: Uri.parse(m.url).path,
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
          );
          return switch (m.videoUrl) {
            null => InteractiveViewer(maxScale: 4, child: image),
            final url => Semantics(
              button: true,
              label: AppLocalizations.of(context)!.playVideo,
              child: GestureDetector(
                onTap: () => openFullscreenVideo(context, url),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    image,
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.spacing12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: AppDimensions.spacing48,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          };
        },
      ),
    );
  }
}
