import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';

/// Avatar boyut seçenekleri.
///
/// Her değer [AppDimensions] içindeki avatar boyutlarına karşılık gelir.
enum AvatarSize {
  /// 32px — Yorum listesi, küçük kullanıcı referansları.
  small(AppDimensions.avatarSmall),

  /// 40px — Feed kartları, varsayılan boyut.
  medium(AppDimensions.avatarMedium),

  /// 56px — Detay sayfaları, mesaj balonları.
  large(AppDimensions.avatarLarge),

  /// 80px — Büyük kullanıcı kartları.
  xLarge(AppDimensions.avatarXLarge),

  /// 100px — Profil sayfası.
  profile(AppDimensions.avatarProfile);

  const AvatarSize(this.value);

  /// Piksel cinsinden avatar çapı.
  final double value;
}

/// Uygulama genelinde kullanılan dairesel avatar bileşeni.
///
/// [imageUrl] varsa [CachedNetworkImage] ile ağdan yüklenir.
/// Yoksa veya boşsa, [name] alanından baş harfler (initials) türetilir
/// ve ismin hash değerine göre bir arka plan rengi atanır.
///
/// Kullanım:
/// ```dart
/// UserAvatar(
///   imageUrl: user.photoUrl,
///   name: user.displayName,
///   size: AvatarSize.large,
///   showOnlineIndicator: true,
///   isOnline: true,
///   onTap: () => context.push('/profile/${user.id}'),
/// )
/// ```
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = AvatarSize.medium,
    this.onTap,
    this.showOnlineIndicator = false,
    this.isOnline = false,
    this.borderColor,
    this.borderWidth = 2,
  });

  /// Kullanıcının tam adı. Baş harfler buradan türetilir.
  final String name;

  /// Ağ üzerindeki profil fotoğrafı URL'si. Null veya boşsa initials gösterilir.
  final String? imageUrl;

  /// Avatar boyutu. Varsayılan [AvatarSize.medium].
  final AvatarSize size;

  /// Avatara tıklandığında çağrılacak callback.
  final VoidCallback? onTap;

  /// Çevrimiçi göstergesinin görünürlüğünü kontrol eder.
  final bool showOnlineIndicator;

  /// Kullanıcının çevrimiçi olup olmadığını belirtir.
  final bool isOnline;

  /// Avatarın çevresindeki kenarlık rengi. Null ise kenarlık gösterilmez.
  final Color? borderColor;

  /// Kenarlık kalınlığı (piksel). Sadece [borderColor] verilmişse uygulanır.
  final double borderWidth;

  /// İsimden baş harfleri çıkarır (ör. "Ahmet Yılmaz" → "AY").
  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  /// İsmin hash değerine göre tutarlı bir arka plan rengi üretir.
  Color _backgroundColorFromName(ColorScheme colorScheme) {
    final List<Color> palette = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      colorScheme.primaryContainer,
      colorScheme.secondaryContainer,
      colorScheme.tertiaryContainer,
    ];
    final index = name.hashCode.abs() % palette.length;
    return palette[index];
  }

  /// Avatar boyutuna göre uygun yazı tipini döndürür.
  TextStyle _initialsTextStyle(double diameter) {
    if (diameter >= AppDimensions.avatarProfile) {
      return AppTextStyles.headlineMedium;
    } else if (diameter >= AppDimensions.avatarXLarge) {
      return AppTextStyles.headlineSmall;
    } else if (diameter >= AppDimensions.avatarLarge) {
      return AppTextStyles.titleMedium;
    } else if (diameter >= AppDimensions.avatarMedium) {
      return AppTextStyles.labelLarge;
    } else {
      return AppTextStyles.labelSmall;
    }
  }

  /// Çevrimiçi gösterge noktasının çapını hesaplar.
  double get _indicatorSize => size.value * 0.25;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final diameter = size.value;
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    Widget avatar = Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: borderWidth)
            : null,
      ),
      child: ClipOval(
        child: hasImage
            ? _buildNetworkImage(colorScheme)
            : _buildInitials(colorScheme),
      ),
    );

    // Çevrimiçi göstergesi
    if (showOnlineIndicator) {
      final indicatorDiameter = _indicatorSize;
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: indicatorDiameter,
              height: indicatorDiameter,
              decoration: BoxDecoration(
                color: isOnline ? AppColors.success : colorScheme.outline,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.surface, width: 2),
              ),
            ),
          ),
        ],
      );
    }

    // Tıklama desteği
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: avatar,
      );
    }

    return avatar;
  }

  /// [CachedNetworkImage] ile ağdan yüklenen profil fotoğrafı.
  Widget _buildNetworkImage(ColorScheme colorScheme) {
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      fit: BoxFit.cover,
      placeholder: (_, _) => _buildInitials(colorScheme),
      errorWidget: (_, _, _) => _buildInitials(colorScheme),
    );
  }

  /// İsim baş harflerinden oluşan fallback avatar.
  Widget _buildInitials(ColorScheme colorScheme) {
    final bgColor = _backgroundColorFromName(colorScheme);
    // Arka plan rengine göre kontrast metin rengi seç
    final textColor =
        ThemeData.estimateBrightnessForColor(bgColor) == Brightness.dark
        ? Colors.white
        : Colors.black87;

    return Container(
      color: bgColor,
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: _initialsTextStyle(size.value).copyWith(color: textColor),
      ),
    );
  }
}
