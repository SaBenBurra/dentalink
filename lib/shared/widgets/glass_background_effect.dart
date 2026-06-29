import 'dart:ui';

import 'package:dentlink/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class GlassBackgroundEffect extends StatelessWidget {
  const GlassBackgroundEffect({
    super.key,
    this.left,
    this.right,
    this.top,
    this.bottom,
    required this.width,
    required this.height,
  }) : assert(
         (left == null) != (right == null),
         'only one of left and right parameters should be given',
       ),
       assert(
         (top == null) != (bottom == null),
         'only one of top and bottom parameters should be given',
       );

  final double? left;
  final double? right;
  final double? top;
  final double? bottom;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final bool isdark = Theme.of(context).brightness == Brightness.dark;
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      width: width,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: (isdark ? AppColors.secondaryLight : AppColors.secondary)
              .withValues(alpha: isdark ? 0.06 : 0.10),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
          child: const SizedBox.shrink(),
        ),
      ),
    );
  }
}
