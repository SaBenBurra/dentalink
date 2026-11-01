import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// `assets/dental-icons/` altındaki tek renkli SVG ikonu [Icon] gibi çizer.
///
/// [color] verilmezse [IconTheme] rengi kullanılır.
class DentalIcon extends StatelessWidget {
  const DentalIcon(this.asset, {super.key, this.size = 24, this.color});

  final String asset;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(
        color ?? IconTheme.of(context).color!,
        BlendMode.srcIn,
      ),
    );
  }
}
