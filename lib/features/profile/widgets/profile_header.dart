import 'package:dentlink/shared/extensions/user_title_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../data/models/user_model.dart';
import '../../../shared/widgets/follow_button.dart';
import '../../../shared/widgets/user_avatar.dart';
import 'mutual_followers_widget.dart';

/// Profil başlığı: avatar + sayaçlar, kimlik, künye, biyografi, aksiyonlar.
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
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bio = user.bio?.trim() ?? '';
    final years = user.experienceYears ?? 0;

    final facts = <(IconData, String)>[
      if (user.workplace?.isNotEmpty ?? false)
        (Icons.local_hospital_outlined, user.workplace!),
      if (user.city?.isNotEmpty ?? false)
        (Icons.location_on_outlined, user.city!),
      if (user.university?.isNotEmpty ?? false)
        (Icons.school_outlined, user.university!),
      if (years > 0) (Icons.schedule_rounded, l10n.profileExperience(years)),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spacing16,
        AppDimensions.spacing16,
        AppDimensions.spacing16,
        AppDimensions.spacing12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                name: user.fullName,
                imageUrl: user.avatarUrl,
                size: AvatarSize.xLarge,
              ),
              const SizedBox(width: AppDimensions.spacing8),
              Expanded(
                child: Row(
                  children: [
                    _Stat(count: user.postsCount, label: l10n.posts),
                    _Stat(
                      count: user.followersCount,
                      label: l10n.followers,
                      onTap: () => context.push('/network/${user.id}?tab=0'),
                    ),
                    _Stat(
                      count: user.followingCount,
                      label: l10n.statFollowing,
                      onTap: () => context.push('/network/${user.id}?tab=1'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing12),
          Row(
            children: [
              Flexible(
                child: Text(
                  user.fullName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (user.isVerified) ...[
                const SizedBox(width: AppDimensions.spacing4),
                Icon(
                  Icons.verified_rounded,
                  size: 18,
                  color: colorScheme.primary,
                  semanticLabel: l10n.verifiedAccount,
                ),
              ],
            ],
          ),
          Text(
            user.title.displayName(context),
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (facts.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacing8),
            Wrap(
              spacing: AppDimensions.spacing12,
              runSpacing: AppDimensions.spacing4,
              children: [
                for (final (icon, text) in facts)
                  _Fact(icon: icon, text: text),
              ],
            ),
          ],
          if (bio.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacing8),
            Text(bio, style: textTheme.bodyMedium?.copyWith(height: 1.4)),
          ],
          MutualFollowersWidget(userId: user.id),
          const SizedBox(height: AppDimensions.spacing16),
          if (isCurrentUser)
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () => context.push('/edit-profile'),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(l10n.editProfile),
              ),
            )
          else
            _FollowAndMessageButtons(user: user),
        ],
      ),
    );
  }
}

/// Sayı üstte, etiket altta; dokunulabiliyorsa 48dp alan.
class _Stat extends StatelessWidget {
  const _Stat({required this.count, required this.label, this.onTap});

  final int count;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: kMinInteractiveDimension),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                formatCount(count),
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: AppDimensions.spacing4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

/// Başka bir kullanıcının profilinde Takip Et / Mesaj butonları.
class _FollowAndMessageButtons extends StatelessWidget {
  final UserModel user;

  const _FollowAndMessageButtons({required this.user});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(child: FollowButton(userId: user.id)),
        const SizedBox(width: AppDimensions.spacing8),
        Expanded(
          child: FilledButton.tonalIcon(
            icon: const Icon(Icons.chat_bubble_outline, size: 18),
            label: Text(l10n.profileMessageButton),
            onPressed: () => context.push(
              Uri(
                path: '/chat/${user.id}',
                queryParameters: {
                  'name': user.fullName,
                  'avatar': user.avatarUrl ?? '',
                },
              ).toString(),
            ),
          ),
        ),
      ],
    );
  }
}
