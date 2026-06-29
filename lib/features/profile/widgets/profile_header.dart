import 'package:flutter/material.dart';
import '../../../data/models/user_model.dart';
import '../../../shared/widgets/user_avatar.dart';
import 'mutual_followers_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:dentlink/core/constants/app_dimensions.dart';

class ProfileHeader extends StatelessWidget {
  final UserModel user;
  final bool isCurrentUser;

  const ProfileHeader({
    super.key,
    required this.user,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                name: user.fullName,
                imageUrl: user.avatarUrl,
                size: AvatarSize.profile,
              ),
              const SizedBox(width: AppDimensions.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacing4),
                    Text(
                      user.title.displayName,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing16),
          if (isCurrentUser) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.push('/edit-profile'),
                child: const Text('Profili Düzenle'),
              ),
            ),
            const SizedBox(height: AppDimensions.spacing16),
          ],
          if (user.bio != null && user.bio!.isNotEmpty) ...[
            Text(user.bio!, style: textTheme.bodyMedium),
            const SizedBox(height: AppDimensions.spacing12),
          ],
          if (user.workplace != null || user.city != null) ...[
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppDimensions.spacing4),
                Expanded(
                  child: Text(
                    [
                      user.workplace,
                      user.city,
                    ].where((e) => e != null && e.isNotEmpty).join(', '),
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
          MutualFollowersWidget(userId: user.id),
        ],
      ),
    );
  }
}
