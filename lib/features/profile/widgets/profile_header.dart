import 'package:dentlink/shared/extensions/user_title_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../data/models/user_model.dart';
import '../../../shared/widgets/follow_button.dart';
import '../../../shared/widgets/user_avatar.dart';

/// Instagram düzeni: solda avatar, yanında ad / unvan / üniversite / şehir;
/// altında biyografi, sayaç satırı ve aksiyonlar.
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
    final details = [
      user.title.displayName(context),
      user.university?.trim() ?? '',
      user.city?.trim() ?? '',
    ].where((s) => s.isNotEmpty);
    final bio = user.bio?.trim() ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spacing20,
        AppDimensions.spacing16,
        AppDimensions.spacing20,
        AppDimensions.spacing8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _AvatarRing(user: user),
              const SizedBox(width: AppDimensions.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                                  size: 18,
                                  color: colorScheme.primary,
                                  semanticLabel: l10n.verifiedAccount,
                                ),
                              ),
                            ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    for (final (i, line) in details.indexed)
                      Text(
                        line,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          // İlk satır unvan.
                          fontWeight: i == 0 ? FontWeight.w600 : null,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (bio.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacing12),
            Text(bio, style: textTheme.bodyMedium),
          ],
          const SizedBox(height: AppDimensions.spacing4),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Stat(count: user.postsCount, label: l10n.posts),
              const _StatDot(),
              _Stat(
                count: user.followersCount,
                label: l10n.followers,
                onTap: () => context.push('/network/${user.id}?tab=0'),
              ),
              const _StatDot(),
              _Stat(
                count: user.followingCount,
                label: l10n.statFollowing,
                onTap: () => context.push('/network/${user.id}?tab=1'),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing4),
          if (isCurrentUser)
            OutlinedButton.icon(
              style: _smallButton(context),
              onPressed: () => context.push('/edit-profile'),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: Text(l10n.editProfile),
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
          size: AvatarSize.xLarge,
        ),
      ),
    );
  }
}

class _StatDot extends StatelessWidget {
  const _StatDot();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing10),
    child: Text(
      '•',
      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );
}

/// "8 Gönderi" gibi tek satır, sayı kalın; dokunulabiliyorsa 48dp alan.
class _Stat extends StatelessWidget {
  const _Stat({required this.count, required this.label, this.onTap});

  final int count;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kMinInteractiveDimension),
        child: Align(
          widthFactor: 1,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: formatCount(count),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: ' $label'),
                // Dokunulabilir sayaçlar okla ayrışır.
                if (onTap != null)
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            style: Theme.of(context).textTheme.bodyMedium,
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
        Expanded(
          child: FollowButton(userId: user.id, style: _smallButton(context)),
        ),
        const SizedBox(width: AppDimensions.spacing8),
        Expanded(
          child: FilledButton.tonalIcon(
            style: _smallButton(context),
            icon: const Icon(Icons.chat_bubble_outline, size: 16),
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

/// Profil aksiyonları için küçük buton; dokunma alanı yine 48dp.
ButtonStyle _smallButton(BuildContext context) => ButtonStyle(
  minimumSize: const WidgetStatePropertyAll(
    Size(0, AppDimensions.buttonHeightSmall),
  ),
  textStyle: WidgetStatePropertyAll(Theme.of(context).textTheme.labelMedium),
);
