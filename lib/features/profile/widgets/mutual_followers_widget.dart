import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/user_provider.dart';
import '../../../shared/widgets/user_avatar.dart';
import 'package:dentlink/core/constants/app_dimensions.dart';

class MutualFollowersWidget extends ConsumerWidget {
  final String userId;

  const MutualFollowersWidget({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followersAsync = ref.watch(mutualFollowersProvider(userId));
    final theme = Theme.of(context);

    return followersAsync.when(
      data: (mutual) {
        if (mutual.users.isEmpty) return const SizedBox.shrink();

        final displayUsers = mutual.users.take(3).toList();

        return Padding(
          padding: const EdgeInsets.only(top: AppDimensions.spacing12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 36.0 + (displayUsers.length - 1) * 20.0,
                height: 36.0,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: List.generate(displayUsers.length, (index) {
                    return Positioned(
                      left: index * 20.0,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.scaffoldBackgroundColor,
                            width: 2,
                          ),
                        ),
                        child: UserAvatar(
                          name: displayUsers[index].fullName,
                          imageUrl: displayUsers[index].avatarUrl,
                          size: AvatarSize.small,
                        ),
                      ),
                    );
                  }).reversed.toList(),
                ),
              ),
              const SizedBox(width: AppDimensions.spacing12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.mutualFollowedBy(
                    displayUsers.first.fullName,
                    mutual.total - 1,
                  ),
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
