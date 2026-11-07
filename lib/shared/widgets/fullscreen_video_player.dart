import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/l10n/generated/app_localizations.dart';

/// Post videosunu tam ekranda açar ve hemen oynatır.
void openFullscreenVideo(BuildContext context, String url) {
  // Kök navigator: alt menünün de üstünü kaplar.
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => FullscreenVideoPlayer(url: url),
    ),
  );
}

/// Dokununca durur/devam eder; altta sarılabilir ilerleme çubuğu.
class FullscreenVideoPlayer extends StatefulWidget {
  const FullscreenVideoPlayer({super.key, required this.url});

  final String url;

  @override
  State<FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<FullscreenVideoPlayer> {
  late final _controller = VideoPlayerController.networkUrl(
    Uri.parse(widget.url),
  );
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _controller.initialize().then(
      (_) => _controller.play(),
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
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    final v = _controller.value;
    if (v.isPlaying) {
      _controller.pause();
    } else {
      // Sondaysa baştan.
      if (v.position >= v.duration) _controller.seekTo(Duration.zero);
      _controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = _controller.value;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        leading: const CloseButton(),
      ),
      extendBodyBehindAppBar: true,
      body: _failed || v.hasError
          ? Center(
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
            )
          : !v.isInitialized
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: v.isPlaying ? l10n.pauseVideo : l10n.playVideo,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _toggle,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AspectRatio(
                              aspectRatio: v.aspectRatio,
                              child: VideoPlayer(_controller),
                            ),
                            if (!v.isPlaying)
                              const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: AppDimensions.spacing64,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppDimensions.spacing16),
                    child: VideoProgressIndicator(
                      _controller,
                      allowScrubbing: true,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
