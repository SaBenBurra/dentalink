import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/l10n/generated/app_localizations.dart';

/// Tam ekran galerideki video sayfası. Başlamadan önce kapak resmi ve oynat
/// simgesi; [autoplay] ise hemen oynar. Dokununca durur/devam eder, altta
/// sarılabilir ilerleme çubuğu. Sayfadan çıkınca (PageView sayfayı atar) durur.
class GalleryVideo extends StatefulWidget {
  const GalleryVideo({
    super.key,
    required this.url,
    required this.thumbUrl,
    this.autoplay = false,
  });

  final String url;
  final String thumbUrl;
  final bool autoplay;

  @override
  State<GalleryVideo> createState() => _GalleryVideoState();
}

class _GalleryVideoState extends State<GalleryVideo> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoplay) _start();
  }

  void _start() {
    final c = _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
    )..addListener(_onChanged);
    c.initialize().then(
      (_) {
        if (mounted) c.play();
      },
      onError: (_) {
        if (mounted) setState(() => _failed = true);
      },
    );
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.removeListener(_onChanged);
    _controller?.dispose();
    super.dispose();
  }

  void _toggle() {
    final c = _controller;
    if (c == null) {
      setState(_start);
      return;
    }
    final v = c.value;
    if (!v.isInitialized) return;
    if (v.isPlaying) {
      c.pause();
    } else {
      // Sondaysa baştan.
      if (v.position >= v.duration) c.seekTo(Duration.zero);
      c.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = _controller;
    final v = c?.value;

    if (_failed || (v?.hasError ?? false)) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: AppDimensions.spacing48,
              color: Colors.white54,
            ),
            const SizedBox(height: AppDimensions.spacing8),
            Text(
              l10n.videoLoadFailed,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    final playing = v?.isPlaying ?? false;
    return SafeArea(
      // stretch: Stack (ve kapak) yalnızca oynat simgesi kadar daralmasın.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: playing ? l10n.pauseVideo : l10n.playVideo,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggle,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (c != null && v!.isInitialized)
                      AspectRatio(
                        aspectRatio: v.aspectRatio,
                        child: VideoPlayer(c),
                      )
                    else
                      // Konumsuz Stack çocuğu kendi piksel boyutunda kalır; video gibi
                      // alanı doldursun ki oynatınca büyüme olmasın.
                      Positioned.fill(
                        child: CachedNetworkImage(
                          imageUrl: widget.thumbUrl,
                          // İmzalı URL her çekişte değişir; önbellek dosya yoluna bağlı (SEC-9).
                          cacheKey: Uri.parse(widget.thumbUrl).path,
                          fit: BoxFit.contain,
                        ),
                      ),
                    if (c != null && !v!.isInitialized)
                      const CircularProgressIndicator(strokeWidth: 2)
                    else if (!playing)
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
          ),
          // Çubuğun yeri baştan ayrılır: oynatma başlayınca görüntü kaymaz.
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spacing16),
            child: SizedBox(
              height: AppDimensions.spacing12,
              child: c != null && v!.isInitialized
                  ? VideoProgressIndicator(c, allowScrubbing: true)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
