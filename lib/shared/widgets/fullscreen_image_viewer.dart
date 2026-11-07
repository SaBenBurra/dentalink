import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_dimensions.dart';
import '../../data/models/post_model.dart';
import 'gallery_video.dart';

/// Post medyasını tam ekranda, kaydırılabilir açar. Görseller yakınlaştırılır;
/// video galerinin içinde oynar ([GalleryVideo]); [initialIndex] video ise hemen başlar.
/// Yukarı ya da aşağı sürükleyince kapanır (WhatsApp gibi).
void openFullscreenImages(
  BuildContext context,
  List<PostMediaItem> media, {
  int initialIndex = 0,
}) {
  // Kök navigator: alt menünün de üstünü kaplar. Saydam: sürüklerken arkadaki sayfa görünür.
  Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, _, _) =>
          FullscreenImageViewer(media: media, initialIndex: initialIndex),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

/// Bu kadar sürükleme ya da bu hızda bırakma galeriyi kapatır.
const _dismissDistance = 100.0;
const _dismissVelocity = 700.0;

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

class _FullscreenImageViewerState extends State<FullscreenImageViewer>
    with SingleTickerProviderStateMixin {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;

  /// İlk sayfadan ayrıldı mı: geri dönünce video kendiliğinden başlamaz.
  bool _moved = false;

  /// Sayfa başına yakınlaştırma; yakınken sürükleme görseli kaydırır, galeriyi kapatmaz.
  final _zooms = <int, TransformationController>{};
  bool _zoomed = false;

  /// Ekrandaki parmak sayısı: iki parmak yakınlaştırmadır, kapatma değil.
  int _pointers = 0;

  /// Kapatma sürüklemesinin dikey kayması; bırakılınca geri döner ya da kapanır.
  double _dy = 0;
  double _backFrom = 0;
  late final AnimationController _back =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
      )..addListener(
        () => setState(
          () => _dy = _backFrom * (1 - Curves.easeOut.transform(_back.value)),
        ),
      );

  @override
  void dispose() {
    _controller.dispose();
    _back.dispose();
    for (final z in _zooms.values) {
      z.dispose();
    }
    super.dispose();
  }

  bool get _canDismiss => !_zoomed && _pointers < 2;

  void _settleBack() {
    if (_dy == 0) return;
    _backFrom = _dy;
    _back.forward(from: 0);
  }

  void _onDragEnd(DragEndDetails d) {
    if (_dy.abs() > _dismissDistance ||
        d.velocity.pixelsPerSecond.dy.abs() > _dismissVelocity) {
      Navigator.of(context).pop();
    } else {
      _settleBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.media.length;
    // Yarım ekran sürüklenince arka plan tamamen saydam.
    final height = MediaQuery.sizeOf(context).height;
    final opacity = (1 - _dy.abs() / (height / 2)).clamp(0.0, 1.0);
    return Listener(
      onPointerDown: (_) {
        setState(() => _pointers++);
        // Sürüklerken ikinci parmak: sürükleme iptal olur, görsel yerine döner.
        if (_pointers > 1) _settleBack();
      },
      onPointerUp: (_) => setState(() => _pointers--),
      onPointerCancel: (_) => setState(() => _pointers--),
      child: Scaffold(
        backgroundColor: Colors.black.withValues(alpha: opacity),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white.withValues(alpha: opacity),
          leading: const CloseButton(),
          title: count > 1 ? Text('${_index + 1} / $count') : null,
          centerTitle: true,
        ),
        extendBodyBehindAppBar: true,
        body: GestureDetector(
          onVerticalDragStart: _canDismiss ? (_) => _back.stop() : null,
          onVerticalDragUpdate: _canDismiss
              ? (d) => setState(() => _dy += d.delta.dy)
              : null,
          onVerticalDragEnd: _canDismiss ? _onDragEnd : null,
          onVerticalDragCancel: _canDismiss ? _settleBack : null,
          child: Transform.translate(
            offset: Offset(0, _dy),
            child: PageView.builder(
              controller: _controller,
              itemCount: count,
              onPageChanged: (i) => setState(() {
                _zooms[_index]?.value = Matrix4.identity();
                _zoomed = false;
                _index = i;
                _moved = true;
              }),
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
                  null => InteractiveViewer(
                    maxScale: 4,
                    transformationController: _zooms.putIfAbsent(
                      i,
                      TransformationController.new,
                    ),
                    onInteractionEnd: (_) => setState(
                      () =>
                          _zoomed = _zooms[i]!.value.getMaxScaleOnAxis() > 1.01,
                    ),
                    child: image,
                  ),
                  // Dokunularak açılan video hemen oynar; kaydırarak gelinende oynat simgesi.
                  final url => GalleryVideo(
                    url: url,
                    thumbUrl: m.url,
                    autoplay: i == widget.initialIndex && !_moved,
                  ),
                };
              },
            ),
          ),
        ),
      ),
    );
  }
}
