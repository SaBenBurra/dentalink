import 'package:dentlink/shared/extensions/user_title_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/user_model.dart';
import '../../../shared/widgets/follow_button.dart';
import '../../../shared/widgets/post_badge.dart';
import '../../../shared/widgets/user_avatar.dart';

/// Ortalı profil başlığı: avatar, ad, unvan rozeti, üniversite · şehir,
/// biyografi, sayaç şeridi, aksiyonlar.
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
    final place = [
      user.university?.trim() ?? '',
      user.city?.trim() ?? '',
    ].where((s) => s.isNotEmpty).join(' · ');
    final bio = user.bio?.trim() ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spacing16,
        AppDimensions.spacing24,
        AppDimensions.spacing16,
        AppDimensions.spacing8,
      ),
      child: Column(
        children: [
          _AvatarRing(user: user),
          const SizedBox(height: AppDimensions.spacing12),
          Text.rich(
            TextSpan(
              text: user.fullName,
              children: [
                if (user.isVerified)
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: AppDimensions.spacing4,
                      ),
                      child: Icon(
                        Icons.verified_rounded,
                        size: 20,
                        color: colorScheme.primary,
                        semanticLabel: l10n.verifiedAccount,
                      ),
                    ),
                  ),
              ],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppDimensions.spacing8),
          // Soru rozetinin yeşil-teal tonu.
          PostBadge(
            postType: PostType.question,
            label: user.title.displayName(context),
          ),
          if (place.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacing8),
            Text(
              place,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (bio.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacing8),
            Text(
              bio,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: AppDimensions.spacing16),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            child: ColoredBox(
              color: colorScheme.primary.withValues(alpha: 0.06),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppDimensions.spacing4,
                ),
                child: Row(
                  children: [
                    _Stat(count: user.postsCount, label: l10n.posts),
                    const _StatDivider(),
                    _Stat(
                      count: user.followersCount,
                      label: l10n.followers,
                      onTap: () => context.push('/network/${user.id}?tab=0'),
                    ),
                    const _StatDivider(),
                    _Stat(
                      count: user.followingCount,
                      label: l10n.statFollowing,
                      onTap: () => context.push('/network/${user.id}?tab=1'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spacing16),
          if (isCurrentUser)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
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

/// Primary → secondary gradyan halka içinde avatar.
class _AvatarRing extends StatelessWidget {
  const _AvatarRing({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.secondary],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacing2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.surface,
        ),
        child: UserAvatar(
          name: user.fullName,
          imageUrl: user.avatarUrl,
          size: AvatarSize.profile,
        ),
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: AppDimensions.spacing24,
    child: VerticalDivider(
      width: 1,
      color: Theme.of(context).colorScheme.outlineVariant,
    ),
  );
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
          constraints: const BoxConstraints(
            minHeight: kMinInteractiveDimension,
          ),
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
