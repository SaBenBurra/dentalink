import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import 'animated_action_button.dart';

/// Gönderi kaydetme (yer imi) için animasyonlu buton.
///
/// Dokunulduğunda hafif dokunsal geri bildirim verir ve ikon 1.3x
/// ölçeğe büyüyüp geri döner (150 ms). [LikeButton] ile aynı
/// [AnimatedActionButton] altyapısını kullanır.
///
/// Örnek kullanım:
/// ```dart
/// BookmarkButton(
///   isBookmarked: false,
///   onToggle: () => ref.read(postProvider.notifier).toggleBookmark(postId),
/// )
/// ```
class BookmarkButton extends StatelessWidget {
  /// Yeni bir [BookmarkButton] oluşturur.
  const BookmarkButton({
    super.key,
    required this.isBookmarked,
    this.onToggle,
    this.size = AppDimensions.iconDefault,
    this.showCount = false,
    this.bookmarkCount = 0,
  });

  /// Kaydedilmiş durumda olup olmadığı.
  final bool isBookmarked;

  /// Yer imi durumu değiştirildiğinde çağrılır.
  final VoidCallback? onToggle;

  /// İkon boyutu (varsayılan: 24).
  final double size;

  /// Sayacın gösterilip gösterilmeyeceği (varsayılan: false).
  final bool showCount;

  /// Toplam kaydetme sayısı.
  final int bookmarkCount;

  @override
  Widget build(BuildContext context) {
    return AnimatedActionButton(
      isActive: isBookmarked,
      activeIcon: Icons.bookmark_rounded,
      inactiveIcon: Icons.bookmark_border_rounded,
      activeColor: AppColors.bookmark,
      onToggle: onToggle,
      size: size,
      showCount: showCount,
      count: bookmarkCount,
    );
  }
}
