import 'package:dentigo/core/l10n/generated/app_localizations.dart';
import 'package:dentigo/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/user_provider.dart';
import '../../../shared/widgets/user_avatar.dart';
import 'package:dentigo/core/constants/app_dimensions.dart';

/// Instagram tarzı tek satır: üst üste küçük avatarlar + "A, B ve N kişi
/// takip ediyor". Ortak takipçi yoksa (ya da kendi profilinde) hiç yer kaplamaz.
class MutualFollowersWidget extends ConsumerWidget {
  final String userId;

  const MutualFollowersWidget({super.key, required this.userId});

  static const _avatar = 24.0;
  static const _overlap = 16.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mutual = ref.watch(mutualFollowersProvider(userId)).valueOrNull;
    if (mutual == null || mutual.users.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final users = mutual.users.take(3).toList();
    final text = AppLocalizations.of(context)!.mutualFollowedBy(
      mutual.total,
      users.first.fullName,
      users.length > 1 ? users[1].fullName : '',
      mutual.total - 2,
    );

    return InkWell(
      onTap: () => context.pushDetail('/network/$userId?tab=0'),
      borderRadius: BorderRadius.circular(AppDimensions.spacing8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacing8),
        child: Row(
          children: [
            SizedBox(
              width: _avatar + (users.length - 1) * _overlap,
              height: _avatar,
              child: Stack(
                children: [
                  for (final (i, u) in users.indexed.toList().reversed)
                    Positioned(
                      left: i * _overlap,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.scaffoldBackgroundColor,
                            width: 1.5,
                          ),
                        ),
                        child: UserAvatar(
                          name: u.fullName,
                          imageUrl: u.avatarUrl,
                          size: AvatarSize.xSmall,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.spacing8),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
