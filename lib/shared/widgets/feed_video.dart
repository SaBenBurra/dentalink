import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'gallery_video.dart';

/// Ekranda en az bu kadarı görünen video oynar.
const _visibleToPlay = 0.5;

/// Listedeki (feed, profil, post sayfası) video: ekrandayken sessiz ya da
/// [videoMuted]'a göre sesli, döngüde oynar; kaydırılıp ekrandan çıkınca,
/// üstüne başka sayfa açılınca, sekme değişince ya da [active] false iken durur.
/// Oynatıcı hazır olana kadar (ya da açılamazsa) [cover] görünür. Sağ altta ses ikonu.
class FeedVideo extends StatefulWidget {
  const FeedVideo({
    super.key,
    required this.url,
    required this.cover,
    this.active = true,
  });

  final String url;
  final Widget cover;

  /// false: görünse de oynamaz (ör. üstünde tam ekran galeri açık).
  final bool active;

  @override
  State<FeedVideo> createState() => _FeedVideoState();
}

class _FeedVideoState extends State<FeedVideo> {
  VideoPlayerController? _controller;
  final _scrolls = <ScrollPosition>{};

  /// Üstte başka sayfa ya da başka sekme varken Overlay/go_router ticker'ı kapatır.
  bool _onStage = true;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    videoMuted.addListener(_applyVolume);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _onStage = TickerMode.valuesOf(context).enabled;
    // En yakın kaydırıcı (medya PageView'ı) ve dikey liste.
    final scrolls = {
      ?Scrollable.maybeOf(context)?.position,
      ?Scrollable.maybeOf(context, axis: Axis.vertical)?.position,
    };
    for (final s in _scrolls.difference(scrolls)) {
      s.removeListener(_checkAfterLayout);
    }
    for (final s in scrolls.difference(_scrolls)) {
      s.addListener(_checkAfterLayout);
    }
    _scrolls
      ..clear()
      ..addAll(scrolls);
    _checkAfterLayout();
  }

  @override
  void didUpdateWidget(FeedVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkAfterLayout();
  }

  @override
  void dispose() {
    videoMuted.removeListener(_applyVolume);
    for (final s in _scrolls) {
      s.removeListener(_checkAfterLayout);
    }
    _controller?.dispose();
    super.dispose();
  }

  bool _checkQueued = false;

  /// Kaydırma bildirimi yeni düzenden önce gelir; konum kare çizilince okunur.
  void _checkAfterLayout() {
    if (_checkQueued) return;
    _checkQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkQueued = false;
      if (mounted) _check();
    });
  }

  /// Görünen oran: videonun kutusu ile dikey listenin kutusunun kesişimi.
  double _visibleFraction() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize || box.size.isEmpty) {
      return 0;
    }
    final rect = box.localToGlobal(Offset.zero) & box.size;
    final listBox =
        Scrollable.maybeOf(
              context,
              axis: Axis.vertical,
            )?.context.findRenderObject()
            as RenderBox?;
    final view = listBox == null || !listBox.hasSize
        ? Rect.largest
        : listBox.localToGlobal(Offset.zero) & listBox.size;
    final shown = rect.intersect(view);
    if (shown.width <= 0 || shown.height <= 0) return 0;
    return shown.width * shown.height / (rect.width * rect.height);
  }

  void _check() {
    final play =
        widget.active && _onStage && _visibleFraction() >= _visibleToPlay;
    if (play == _playing) return;
    _playing = play;
    if (!play) {
      _controller?.pause();
      return;
    }
    final c = _controller;
    if (c == null) {
      _start();
    } else if (c.value.isInitialized) {
      c.play();
    }
  }

  void _start() {
    // mixWithOthers: sessiz otomatik oynatma çalan müziği kesmesin.
    final c = _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    c.initialize().then(
      (_) {
        if (!mounted) return;
        c.setLooping(true);
        _applyVolume();
        if (_playing) c.play();
        setState(() {});
      },
      // Kapak kalır; dokununca galeri hatayı gösterir.
      onError: (_) {},
    );
  }

  void _applyVolume() => _controller?.setVolume(videoMuted.value ? 0 : 1);

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final size = c?.value.size ?? Size.zero;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (c != null && c.value.isInitialized && !size.isEmpty)
          // Kapak gibi çerçeveyi doldurur, taşan kısım kırpılır.
          FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: VideoPlayer(c),
            ),
          )
        else
          widget.cover,
        const Positioned(
          right: 0,
          bottom: 0,
          child: VideoSoundButton(compact: true),
        ),
      ],
    );
  }
}
