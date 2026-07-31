import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import 'animated_action_button.dart';

/// Gönderi ve yorumlar için animasyonlu beğeni (kalp) butonu.
///
/// Dokunulduğunda hafif dokunsal geri bildirim verir ve ikon 1.3x
/// ölçeğe büyüyüp geri döner (150 ms). Sayaç 1000+ değerler için
/// "1.2K" biçiminde kısaltılır.
///
/// Örnek kullanım:
/// ```dart
/// LikeButton(
///   isLiked: true,
///   likeCount: 42,
///   onToggle: () => ref.read(postProvider.notifier).toggleLike(postId),
/// )
/// ```
class LikeButton extends StatelessWidget {
  /// Yeni bir [LikeButton] oluşturur.
  const LikeButton({
    super.key,
    required this.isLiked,
    required this.likeCount,
    this.onToggle,
    this.size = AppDimensions.iconDefault,
    this.showCount = true,
  });

  /// Beğenilmiş durumda olup olmadığı.
  final bool isLiked;

  /// Toplam beğeni sayısı.
  final int likeCount;

  /// Beğeni durumu değiştirildiğinde çağrılır.
  final VoidCallback? onToggle;

  /// İkon boyutu (varsayılan: 24).
  final double size;

  /// Sayacın gösterilip gösterilmeyeceği.
  final bool showCount;

  @override
  Widget build(BuildContext context) {
    return AnimatedActionButton(
      isActive: isLiked,
      activeIcon: Icons.favorite_rounded,
      inactiveIcon: Icons.favorite_border_rounded,
      activeColor: AppColors.like,
      onToggle: onToggle,
      size: size,
      showCount: showCount,
      count: likeCount,
    );
  }
}
