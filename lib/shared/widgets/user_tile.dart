import 'package:flutter/material.dart';

import '../../core/constants/app_dimensions.dart';
import '../../data/models/user_model.dart';
import 'user_avatar.dart';

/// Uygulama genelinde kullanılan yatay kullanıcı bilgi satırı.
///
/// Avatar, ad, alt başlık ve isteğe bağlı sağ taraf widget'ı içerir.
/// Feed kartları, takipçi listeleri, arama sonuçları gibi birçok
/// yerde yeniden kullanılabilir.
///
/// Örnek kullanım:
/// ```dart
/// UserTile(
///   user: currentUser,
///   onTap: () => context.push('/profile/${currentUser.id}'),
///   trailing: FollowButton(userId: currentUser.id),
/// )
/// ```
class UserTile extends StatelessWidget {
  /// Yeni bir [UserTile] oluşturur.
  const UserTile({
    super.key,
    required this.user,
    this.avatarSize = AvatarSize.medium,
    this.onTap,
    this.trailing,
    this.subtitle,
    this.showTitle = true,
    this.dense = false,
  });

  /// Gösterilecek kullanıcı modeli.
  final UserModel user;

  /// Avatar boyutu. Varsayılan [AvatarSize.medium].
  final AvatarSize avatarSize;

  /// Satıra dokunulduğunda çağrılır.
  final VoidCallback? onTap;

  /// Satırın sağ tarafına yerleştirilecek widget (ör. takip butonu).
  final Widget? trailing;

  /// İsmin altında gösterilecek metin. Verilmezse [showTitle] durumuna
  /// göre kullanıcının unvanı gösterilir.
  final String? subtitle;

  /// Kullanıcının mesleki unvanının gösterilip gösterilmeyeceği.
  /// Sadece [subtitle] `null` olduğunda etkilidir.
  final bool showTitle;

  /// Kompakt görünüm. `true` olduğunda avatar–metin arası boşluk
  /// ve dikey padding azaltılır.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final horizontalGap = dense
        ? AppDimensions.spacing8
        : AppDimensions.spacing12;
    final verticalPadding = dense
        ? AppDimensions.spacing4
        : AppDimensions.spacing8;

    // Alt başlık metnini belirle
    final subtitleText = subtitle ??
        (showTitle ? user.title.displayName : null);

    final content = Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: Row(
        children: [
          UserAvatar(
            name: user.fullName,
            imageUrl: user.avatarUrl,
            size: avatarSize,
          ),
          SizedBox(width: horizontalGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.fullName,
                  style: textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitleText != null) ...[
                  const SizedBox(height: AppDimensions.spacing2),
                  Text(
                    subtitleText,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppDimensions.spacing8),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: content,
      );
    }

    return content;
  }
}
