import 'package:dentlink/core/constants/app_dimensions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Ray üzerinde segmentli filtre. 3 segmente kadar eşit genişlikte durur;
/// fazlasında ray kendi içinde kayar ve sonraki segmentin yarısı görünür,
/// böylece kullanıcı devamı olduğunu anlar.
class FeedFilterSegments extends StatefulWidget {
  const FeedFilterSegments({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.position,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Sayfa konumu (ör. 1.25): gösterge ve yazı renkleri kaydırmayla birlikte
  /// ilerler. Yoksa [selectedIndex]'te durur.
  final ValueListenable<double>? position;

  /// Ekrana sığan segment sayısı; .5, bir sonrakinin yarısını gösterir.
  static const double visibleWhenScrolling = 3.5;

  @override
  State<FeedFilterSegments> createState() => _FeedFilterSegmentsState();
}

class _FeedFilterSegmentsState extends State<FeedFilterSegments> {
  static const _duration = Duration(milliseconds: 180);
  static const double _inset = 2.5;

  final _scroll = ScrollController();
  double _segmentWidth = 0;
  double _viewportWidth = 0;
  bool _fadeLeft = false;
  bool _fadeRight = false;

  bool _updateFades(ScrollMetrics m) {
    final (left, right) = edgeFades(m);
    if (left != _fadeLeft || right != _fadeRight) {
      setState(() {
        _fadeLeft = left;
        _fadeRight = right;
      });
    }
    return false;
  }

  @override
  void didUpdateWidget(FeedFilterSegments oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) _revealSelected();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Seçili segmenti (örn. sayfa kaydırınca) ray içinde ortalar.
  void _revealSelected() {
    if (!_scroll.hasClients) return;
    final target =
        widget.selectedIndex * _segmentWidth -
        (_viewportWidth - _segmentWidth) / 2;
    _scroll.animateTo(
      target.clamp(0, _scroll.position.maxScrollExtent),
      duration: _duration,
      curve: Curves.easeOutCubic,
    );
  }

  /// [t] 1 = seçili (göstergenin üstünde), 0 = seçili değil.
  static TextStyle _labelStyle(ColorScheme colors, double t) => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.lerp(FontWeight.w500, FontWeight.w700, t),
    color: Color.lerp(colors.onSurfaceVariant, colors.onPrimary, t),
  );

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final count = widget.labels.length;
    final selected = widget.selectedIndex;

    // Görünen ray 32dp; segmentlerin dokunma alanı barın tüm 48dp'si.
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 32,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppDimensions.spacing16),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            _viewportWidth = constraints.maxWidth - _inset * 2;
            _segmentWidth = count <= 3
                ? _viewportWidth / count
                : _viewportWidth / FeedFilterSegments.visibleWhenScrolling;

            final w = constraints.maxWidth;
            // Devamı olan kenarda yazı sınırda kesilmesin: son 4dp tamamen
            // saydam, ondan önceki 20dp'de solar.
            Color edge(bool fade) => fade ? Colors.transparent : Colors.white;
            return ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (rect) => LinearGradient(
                colors: [
                  edge(_fadeLeft),
                  edge(_fadeLeft),
                  Colors.white,
                  Colors.white,
                  edge(_fadeRight),
                  edge(_fadeRight),
                ],
                stops: [0, 4 / w, 24 / w, 1 - 24 / w, 1 - 4 / w, 1],
              ).createShader(rect),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.spacing16),
                child: NotificationListener<ScrollMetricsNotification>(
                  onNotification: (n) => _updateFades(n.metrics),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (n) => _updateFades(n.metrics),
                    child: SingleChildScrollView(
                      controller: _scroll,
                      scrollDirection: Axis.horizontal,
                      physics: count <= 3
                          ? const NeverScrollableScrollPhysics()
                          : const ClampingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: _inset),
                      child: SizedBox(
                        width: _segmentWidth * count,
                        height: 48,
                        child: ValueListenableBuilder<double>(
                          valueListenable:
                              widget.position ??
                              AlwaysStoppedAnimation(selected.toDouble()),
                          builder: (context, position, _) => Stack(
                            children: [
                              // Seçim tek bir kayan göstergeyle çizilir; segment
                              // başına zemin/gölge yok (geçişte gri flaş olmasın).
                              Positioned(
                                left: position * _segmentWidth,
                                width: _segmentWidth,
                                top: (48 - 27) / 2,
                                height: 27,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  for (final (i, text) in widget.labels.indexed)
                                    Semantics(
                                      button: true,
                                      selected: i == selected,
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () => widget.onSelected(i),
                                        child: SizedBox(
                                          width: _segmentWidth,
                                          height: 48,
                                          child: Center(
                                            // Göstergenin altındaki pay kadar seçili görünüm.
                                            child: DefaultTextStyle(
                                              style: _labelStyle(
                                                colorScheme,
                                                (1 - (position - i).abs())
                                                    .clamp(0.0, 1.0),
                                              ),
                                              child: Text(
                                                text,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Hangi kenarda kaydırılacak içerik var (solma gösterilecek): (sol, sağ).
@visibleForTesting
(bool, bool) edgeFades(ScrollMetrics m) =>
    (m.pixels > m.minScrollExtent + 0.5, m.pixels < m.maxScrollExtent - 0.5);
