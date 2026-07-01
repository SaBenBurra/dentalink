import 'package:dentlink/shared/extensions/post_type_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_stats.dart';
import '../widgets/badge_showcase.dart';
import '../widgets/profile_posts_tab.dart';
import '../../../data/models/enums.dart';
import '../../../shared/widgets/error_widget.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserState = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
            tooltip: 'Ayarlar',
          ),
        ],
      ),
      body: currentUserState.when(
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
                    child: ProfileHeader(user: user, isCurrentUser: true),
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
                          // <-- Artık metinleri bağlam (context) ile alıyoruz
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
          message: error.toString(),
          onRetry: () => ref.refresh(authProvider),
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
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
