import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../data/models/user_model.dart';
import '../../../data/providers/repository_providers.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/user_tile.dart';

class FollowersScreen extends ConsumerStatefulWidget {
  final String userId;
  final int initialIndex;

  const FollowersScreen({
    super.key,
    required this.userId,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends ConsumerState<FollowersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ağ'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Takipçiler'),
            Tab(text: 'Takip Edilenler'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _UserListTab(
            provider: followersProvider(widget.userId),
            emptyMessage: 'Henüz takipçisi yok.',
          ),
          _UserListTab(
            provider: followingProvider(widget.userId),
            emptyMessage: 'Henüz kimseyi takip etmiyor.',
          ),
        ],
      ),
    );
  }
}

class _UserListTab extends ConsumerWidget {
  final AutoDisposeFutureProvider<List<UserModel>> provider;
  final String emptyMessage;

  const _UserListTab({required this.provider, required this.emptyMessage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(provider);

    return asyncData.when(
      data: (users) {
        if (users.isEmpty) {
          return DentLinkEmptyState(
            icon: Icons.people_outline,
            title: 'Kullanıcı Bulunamadı',
            subtitle: emptyMessage,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppDimensions.spacing16),
          itemCount: users.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppDimensions.spacing8),
          itemBuilder: (context, index) {
            final user = users[index];
            return UserTile(
              user: user,
              trailing: _FollowButton(
                key: ValueKey(user.id),
                user: user,
              ),
            );
          },
        );
      },
      loading: () => const Center(child: DentLinkLoadingSpinner()),
      error: (error, stack) => DentLinkErrorWidget(
        message: 'Kullanıcılar yüklenirken bir hata oluştu.',
        onRetry: () => ref.invalidate(provider),
      ),
    );
  }
}

class _FollowButton extends ConsumerStatefulWidget {
  final UserModel user;

  const _FollowButton({super.key, required this.user});

  @override
  ConsumerState<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends ConsumerState<_FollowButton> {
  bool _isLoading = false;
  late bool _isFollowing;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.user.isFollowing;
  }

  @override
  void didUpdateWidget(covariant _FollowButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.id != widget.user.id ||
        oldWidget.user.isFollowing != widget.user.isFollowing) {
      _isFollowing = widget.user.isFollowing;
    }
  }

  Future<void> _toggleFollow() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final repo = ref.read(userRepositoryProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      if (_isFollowing) {
        await repo.unfollowUser(widget.user.id);
      } else {
        await repo.followUser(widget.user.id);
      }

      if (mounted) {
        setState(() {
          _isFollowing = !_isFollowing;
        });
        ref.invalidate(userProfileProvider(widget.user.id));
        
        final currentUser = ref.read(currentUserProvider);
        if (currentUser != null) {
          ref.invalidate(userProfileProvider(currentUser.id));
        }
      }
    } catch (e) {
      debugPrint('Follow action error: $e');
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('İşlem başarısız oldu, tekrar deneyin.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _toggleFollow,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacing16,
        ),
        minimumSize: const Size(0, 36),
      ),
      child: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(_isFollowing ? 'Takibi Bırak' : 'Takip Et'),
    );
  }
}
