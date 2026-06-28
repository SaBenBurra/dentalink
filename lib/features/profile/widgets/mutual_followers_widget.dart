import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/user_provider.dart';
import '../../../shared/widgets/user_avatar.dart';

class MutualFollowersWidget extends ConsumerWidget {
  final String userId;

  const MutualFollowersWidget({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ortak takipçileri simüle etmek için şimdilik followersProvider kullanıyoruz.
    final followersAsync = ref.watch(followersProvider(userId));
    final theme = Theme.of(context);

    return followersAsync.when(
      data: (followers) {
        if (followers.isEmpty) return const SizedBox.shrink();

        final displayUsers = followers.take(3).toList();
        
        return Padding(
          padding: const EdgeInsets.only(top: 12.0),
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
              const SizedBox(width: 12),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: displayUsers.first.fullName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (followers.length > 1) ...[
                        const TextSpan(text: ' ve '),
                        TextSpan(
                          text: '${followers.length - 1} diğer kişi',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                      const TextSpan(text: ' takip ediyor'),
                    ],
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
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
