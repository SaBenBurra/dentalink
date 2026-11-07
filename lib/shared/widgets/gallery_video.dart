import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:video_player/video_player.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/l10n/generated/app_localizations.dart';

/// Tüm videoların ortak ses ayarı (Instagram gibi sessiz başlar); bir videonun
/// ses ikonu hepsini değiştirir.
// shortcut: uygulama kapanınca sessize döner; kalıcı olsun istenirse SharedPreferences'a yaz.
final videoMuted = ValueNotifier<bool>(true);

/// [videoMuted]'u değiştiren ses ikonu. [compact]: listedeki videonun sağ alt
/// köşesindeki küçük yuvarlak; değilse galerideki düz ikon. Dokunma alanı 48dp.
class VideoSoundButton extends StatelessWidget {
  const VideoSoundButton({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ValueListenableBuilder<bool>(
      valueListenable: videoMuted,
      builder: (context, muted, _) {
        final icon = Icon(
          muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
          color: Colors.white,
          size: compact ? AppDimensions.iconSmall : null,
        );
        return IconButton(
          tooltip: muted ? l10n.unmuteVideo : l10n.muteVideo,
          onPressed: () => videoMuted.value = !muted,
          icon: compact
              ? Container(
                  padding: const EdgeInsets.all(AppDimensions.spacing4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: icon,
                )
              : icon,
        );
      },
    );
  }
}

/// Tam ekran galerideki video sayfası. Başlamadan önce kapak resmi ve oynat
/// simgesi; [autoplay] ise hemen oynar. Dokununca durur/devam eder, altta oynat/duraklat,
/// sarılabilir ilerleme çubuğu ve ses ikonu. Sayfadan çıkınca (PageView sayfayı atar) durur.
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
    videoMuted.addListener(_applyVolume);
    if (widget.autoplay) _start();
  }

  void _applyVolume() => _controller?.setVolume(videoMuted.value ? 0 : 1);

  void _start() {
    final c = _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
    )..addListener(_onChanged);
    c.initialize().then(
      (_) {
        if (!mounted) return;
        _applyVolume();
        c.play();
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
    videoMuted.removeListener(_applyVolume);
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
          // Oynat/duraklat, çubuk ve ses; satırın yeri baştan ayrılır: oynatma başlayınca görüntü kaymaz.
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spacing4),
            child: Row(
              children: [
                IconButton(
                  tooltip: playing ? l10n.pauseVideo : l10n.playVideo,
                  onPressed: _toggle,
                  color: Colors.white,
                  icon: Icon(
                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    height: AppDimensions.spacing12,
                    child: c != null && v!.isInitialized
                        ? _SmoothProgress(controller: c)
                        : null,
                  ),
                ),
                const VideoSoundButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Oynarken çubuğun oranı: oynatıcı konumu yaklaşık 500 ms'de bir bildirir,
/// aradaki süre geçen zamanla doldurulur ki çubuk adım adım değil akarak dolsun.
double videoProgress({
  required Duration reported,
  required Duration sinceReport,
  required Duration duration,
  required bool playing,
  double speed = 1,
}) {
  if (duration <= Duration.zero) return 0;
  final pos = playing ? reported + sinceReport * speed : reported;
  return (pos.inMicroseconds / duration.inMicroseconds).clamp(0.0, 1.0);
}

/// Paletteki renklerle, sarılabilir ve akıcı ilerleme çubuğu.
class _SmoothProgress extends StatefulWidget {
  const _SmoothProgress({required this.controller});

  final VideoPlayerController controller;

  @override
  State<_SmoothProgress> createState() => _SmoothProgressState();
}

class _SmoothProgressState extends State<_SmoothProgress>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker((_) => setState(() {}));
  final _sinceReport = Stopwatch();
  Duration _reported = Duration.zero;

  VideoPlayerController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _c.addListener(_onChanged);
    _onChanged();
  }

  void _onChanged() {
    final v = _c.value;
    if (v.position != _reported) {
      _reported = v.position;
      _sinceReport
        ..reset()
        ..start();
    }
    if (v.isPlaying && !_ticker.isActive) {
      _ticker.start();
    } else if (!v.isPlaying && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _c.removeListener(_onChanged);
    _ticker.dispose();
    super.dispose();
  }

  void _seek(Offset local) {
    final box = context.findRenderObject()! as RenderBox;
    final f = (local.dx / box.size.width).clamp(0.0, 1.0);
    _c.seekTo(_c.value.duration * f);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final v = _c.value;
    final buffered = v.buffered.isEmpty || v.duration <= Duration.zero
        ? 0.0
        : (v.buffered.last.end.inMicroseconds / v.duration.inMicroseconds)
              .clamp(0.0, 1.0);
    final played = videoProgress(
      reported: _reported,
      sinceReport: _sinceReport.elapsed,
      duration: v.duration,
      playing: v.isPlaying,
      speed: v.playbackSpeed,
    );
    Widget fill(double f, Color color) => FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: f,
      child: ColoredBox(color: color),
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (d) => _seek(d.localPosition),
      onHorizontalDragUpdate: (d) => _seek(d.localPosition),
      child: Center(
        child: SizedBox(
          height: AppDimensions.spacing4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Colors.white24),
                fill(buffered, scheme.primary.withValues(alpha: 0.35)),
                fill(played, scheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
