import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../data/models/post_model.dart';
import 'fullscreen_image_viewer.dart';

/// Çerçeve oranı ilk görselden, [minRatio] (dikey sınır) ile 1.91:1 (yatay) arasında.
/// Listelerde kare (1), post sayfasında Instagram gibi 4:5 (0.8).
double postMediaAspectRatio(int width, int height, {double minRatio = 1}) =>
    height == 0 ? 1.0 : (width / height).clamp(minRatio, 1.91);

class PostMedia extends StatefulWidget {
  const PostMedia({super.key, required this.media, this.minAspectRatio = 1});

  /// Sıralı görsel ve video; video kapak resmiyle görünür, dokununca tam ekran
  /// oynatılır (046).
  final List<PostMediaItem> media;

  /// Dikey görselin çerçevesi en fazla bu kadar uzar: listede kare (1), post
  /// sayfasında 4:5 (0.8). Fazlası ortadan kırpılır, galeride tamamı görünür.
  final double minAspectRatio;

  @override
  State<PostMedia> createState() => _PostMediaState();
}

class _PostMediaState extends State<PostMedia> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  // Sayaç ve noktaların zemini: açık görselde koyu dolgu, koyu görselde ince açık kenar seçilir.
  static final _scrim = BoxDecoration(
    color: Colors.black.withValues(alpha: 0.55),
    border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 0.5),
    borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
  );

  // shortcut: görsel boyutu DB'de yok, oran ilk görsel yüklenince okunur (ilk açılışta 1:1'den
  // geçiş olur); post_images'a width/height eklenince oran doğrudan oradan gelsin.
  static final _ratioCache = <String, double>{};
  ImageStream? _ratioStream;
  late final _ratioListener = ImageStreamListener(
    (info, _) {
      // Ham oran saklanır; liste ve post sayfası aynı görseli farklı sınırla gösterir.
      final ratio = postMediaAspectRatio(
        info.image.width,
        info.image.height,
        minRatio: 0,
      );
      info.dispose();
      _ratioCache[_firstPath] = ratio;
      if (mounted) setState(() {});
    },
    // Yüklenemezse 1:1 kalır; hata görselin kendi errorWidget'ında gösterilir.
    onError: (_, _) {},
  );

  /// Sayfa başına görsel ya da video kapağı.
  List<String> get _pages => [for (final m in widget.media) m.url];

  String get _firstPath => Uri.parse(_pages.first).path;

  double get _aspectRatio =>
      _ratioCache[_firstPath]?.clamp(widget.minAspectRatio, 1.91) ?? 1.0;

  void _resolveRatio() {
    _ratioStream?.removeListener(_ratioListener);
    _ratioStream = null;
    if (_pages.isEmpty || _ratioCache.containsKey(_firstPath)) return;
    _ratioStream =
        CachedNetworkImageProvider(_pages.first, cacheKey: _firstPath).resolve(
          createLocalImageConfiguration(context),
        )..addListener(_ratioListener);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ratioStream == null) _resolveRatio();
  }

  @override
  void didUpdateWidget(PostMedia oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = oldWidget.media;
    final oldFirst = old.isEmpty ? null : Uri.parse(old.first.url).path;
    if (_pages.isNotEmpty && oldFirst != _firstPath) _resolveRatio();
  }

  @override
  void dispose() {
    _ratioStream?.removeListener(_ratioListener);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages;
    if (pages.isEmpty) {
      return const SizedBox.shrink(); // <-- Güvenlik kontrolü
    }
    final media = widget.media;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      alignment: Alignment.center,
      children: [
        ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 150),
            child: AspectRatio(
              aspectRatio: _aspectRatio,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemCount: pages.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    // Video da galeride açılır ve orada hemen oynar. Çift dokunma yok: tek dokunuşu 300 ms geciktirirdi.
                    onTap: () => openFullscreenImages(
                      context,
                      media,
                      initialIndex: index,
                    ),
                    child: CachedNetworkImage(
                      imageUrl: pages[index],
                      // İmzalı URL her çekişte değişir; önbellek dosya yoluna bağlı (SEC-9).
                      cacheKey: Uri.parse(pages[index]).path,
                      // Çerçeve ilk görselin oranında; diğerleri ve sınır dışı oranlar ortadan kırpılır.
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
          ),
        ),
        if (_currentPage < media.length && media[_currentPage].videoUrl != null)
          // Dokunma kapağın GestureDetector'ına geçer.
          IgnorePointer(
            child: Semantics(
              label: AppLocalizations.of(context)!.playVideo,
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.spacing12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: AppDimensions.iconXLarge,
                ),
              ),
            ),
          ),
        if (pages.length > 1) ...[
          // Kaydırılabilir olduğu belli olsun: köşede sayaç, aktif nokta uzar.
          // Dokunmayı yutmazlar: yoksa dokunuş karta düşüp post sayfasını açardı.
          Positioned(
            top: AppDimensions.spacing12,
            right: AppDimensions.spacing12,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacing8,
                  vertical: 3,
                ),
                decoration: _scrim,
                child: Text(
                  '${_currentPage + 1}/${pages.length}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: AppDimensions.spacing12,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacing4,
                  vertical: AppDimensions.spacing4,
                ),
                decoration: _scrim,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(pages.length, (idx) {
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
          ),
        ],
      ],
    );
  }
}
