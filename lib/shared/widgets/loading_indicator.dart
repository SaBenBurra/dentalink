import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

/// Ortalanmış dairesel yükleme göstergesi.
///
/// Veri çekilirken veya bir işlem beklenirken kullanılır.
/// Boyut ve çizgi kalınlığı isteğe bağlı olarak ayarlanabilir.
///
/// ```dart
/// DentLinkLoadingSpinner(size: 32, strokeWidth: 3)
/// ```
class DentLinkLoadingSpinner extends StatelessWidget {
  const DentLinkLoadingSpinner({super.key, this.size, this.strokeWidth});

  /// Gösterge çapı (piksel). Null ise Flutter varsayılanı kullanılır.
  final double? size;

  /// Gösterge çizgi kalınlığı. Null ise Flutter varsayılanı kullanılır.
  final double? strokeWidth;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget indicator = CircularProgressIndicator(
      color: colorScheme.primary,
      strokeWidth: strokeWidth ?? 4.0,
    );

    if (size != null) {
      indicator = SizedBox(width: size, height: size, child: indicator);
    }

    return Center(child: indicator);
  }
}

/// Gönderi kartı biçiminde shimmer (parıltı) yer tutucu.
///
/// Feed yüklenirken içerik yerine gösterilen iskelet (skeleton) bileşenidir.
/// Aydınlık ve karanlık tema için [AppColors] shimmer renkleri kullanılır.
///
/// ```dart
/// ListView.builder(
///   itemCount: 3,
///   itemBuilder: (_, __) => const DentLinkShimmerCard(),
/// )
/// ```
class DentLinkShimmerCard extends StatelessWidget {
  const DentLinkShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final baseColor = brightness == Brightness.light
        ? AppColors.shimmerBaseLight
        : AppColors.shimmerBaseDark;
    final highlightColor = brightness == Brightness.light
        ? AppColors.shimmerHighlightLight
        : AppColors.shimmerHighlightDark;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.cardPadding,
          vertical: AppDimensions.spacing12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar + kullanıcı adı satırları ──
            Row(
              children: [
                // Avatar dairesi
                Container(
                  width: AppDimensions.avatarMedium,
                  height: AppDimensions.avatarMedium,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacing12),
                // Metin satırları
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 140,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusSmall,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacing8),
                      Container(
                        width: 90,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusSmall,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacing16),

            // ── Görsel alanı ──
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
            ),
            const SizedBox(height: AppDimensions.spacing12),

            // ── Aksiyon çubuğu ──
            Row(
              children: [
                Container(
                  width: 60,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusSmall,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacing16),
                Container(
                  width: 60,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusSmall,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacing16),
                Container(
                  width: 60,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusSmall,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Yarı saydam yükleme katmanı (overlay).
///
/// Bir işlem sürerken alt içeriği devre dışı bırakır ve
/// ortada bir [DentLinkLoadingSpinner] gösterir.
///
/// [isLoading] `true` olduğunda overlay görünür hale gelir ve
/// alt widget'a dokunma engellenir.
///
/// ```dart
/// DentLinkLoadingOverlay(
///   isLoading: state.isSubmitting,
///   child: MyFormWidget(),
/// )
/// ```
class DentLinkLoadingOverlay extends StatelessWidget {
  const DentLinkLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  /// Overlay'in görünür olup olmadığını kontrol eder.
  final bool isLoading;

  /// Overlay'in altında gösterilecek widget.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: false,
              child: Container(
                color: Colors.black45,
                child: const DentLinkLoadingSpinner(),
              ),
            ),
          ),
      ],
    );
  }
}
