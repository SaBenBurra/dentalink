import 'package:dentlink/shared/extensions/post_type_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_provider.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_stats.dart';
import '../widgets/badge_showcase.dart';
import '../widgets/profile_posts_tab.dart';
import '../../../domain/enums/enums.dart';
import '../../../data/models/user_model.dart';
import '../../../shared/widgets/error_widget.dart';

class ProfileScreen extends ConsumerWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  String _getLocalizedErrorMessage(Object error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('socket') || msg.contains('network') || msg.contains('connection')) {
      return 'İnternet bağlantınızı kontrol edip tekrar deneyin.';
    }
    if (msg.contains('postgrest') || msg.contains('supabase') || msg.contains('timeout')) {
      return 'Sunucuyla iletişim kurulurken bir sorun oluştu.';
    }
    return 'Beklenmeyen bir hata oluştu. Lütfen daha sonra tekrar deneyin.';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserState = ref.watch(authProvider);
    final currentUser = currentUserState.valueOrNull;
    
    final isCurrentUser = userId == null || (currentUser != null && userId == currentUser.id);
    final targetUserId = userId ?? currentUser?.id;

    final theme = Theme.of(context);

    if (targetUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil')),
        body: const Center(child: Text('Kullanıcı bulunamadı.')),
      );
    }

    final AsyncValue<UserModel?> userState;
    if (isCurrentUser) {
      userState = currentUserState;
    } else {
      final profileState = ref.watch(userProfileProvider(targetUserId));
      userState = profileState.whenData((value) => value);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: isCurrentUser
            ? [
                IconButton(
                  icon: const Icon(Icons.bookmark_border_rounded),
                  onPressed: () => context.push('/bookmarks'),
                  tooltip: 'Kaydedilenler',
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => context.push('/settings'),
                  tooltip: 'Ayarlar',
                ),
              ]
            : null,
      ),
      body: userState.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Kullanıcı bulunamadı.'));
          }

          return DefaultTabController(
            length: PostType.profileTabs.length,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: ProfileHeader(user: user, isCurrentUser: isCurrentUser),
                  ),
                  SliverToBoxAdapter(child: ProfileStats(user: user)),
                  const SliverToBoxAdapter(child: Divider(height: 32)),
                  SliverToBoxAdapter(child: BadgeShowcase(userId: user.id)),
                  const SliverToBoxAdapter(child: Divider(height: 32)),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverAppBarDelegate(
                      TabBar(
                        labelColor: theme.colorScheme.primary,
                        unselectedLabelColor:
                            theme.colorScheme.onSurfaceVariant,
                        indicatorColor: theme.colorScheme.primary,
                        tabs: [
                          for (final type in PostType.profileTabs)
                            Tab(text: type.getLabelInProfile(context)),
                        ],
                      ),
                      theme.scaffoldBackgroundColor,
                    ),
                  ),
                ];
              },
              body: TabBarView(
                children: [
                  for (final type in PostType.profileTabs)
                    ProfilePostsTab(userId: user.id, type: type),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => DentLinkErrorWidget(
          message: _getLocalizedErrorMessage(error),
          onRetry: () {
            if (isCurrentUser) {
              ref.invalidate(authProvider);
            } else {
              ref.invalidate(userProfileProvider(targetUserId));
            }
          },
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar, this._backgroundColor);

  final TabBar _tabBar;
  final Color _backgroundColor;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: _backgroundColor, child: _tabBar);
  }

  @override
  bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) {
    return _tabBar != oldDelegate._tabBar ||
        _backgroundColor != oldDelegate._backgroundColor;
  }
}
