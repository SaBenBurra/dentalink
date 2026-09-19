import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/following_provider.dart';
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

class _UserListTab extends ConsumerStatefulWidget {
  final AutoDisposeFutureProvider<List<UserModel>> provider;
  final String emptyMessage;

  const _UserListTab({required this.provider, required this.emptyMessage});

  @override
  ConsumerState<_UserListTab> createState() => _UserListTabState();
}

class _UserListTabState extends ConsumerState<_UserListTab> {
  bool _statusesLoaded = false;

  /// Takip durumlarını toplu olarak yükler.
  ///
  /// [_statusesLoaded] guard'ı sayesinde sadece ilk veri
  /// yüklemesinde çalışır, sonraki rebuild'lerde atlanır.
  void _loadFollowStatuses(List<UserModel> users) {
    if (_statusesLoaded || users.isEmpty) return;
    _statusesLoaded = true;

    final userIds = users.map((u) => u.id).toList();
    ref
        .read(followRepositoryProvider)
        .getFollowedUserIds(userIds)
        .then((followedIds) {
      if (!mounted) return;
      ref.read(followingStateProvider.notifier).setFollowStatuses({
        for (final id in userIds) id: followedIds.contains(id),
      });
    }).catchError((Object e) {
      debugPrint('Takip durumları yüklenemedi: $e');
      if (mounted) _statusesLoaded = false; // Yeniden deneme imkanı
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(widget.provider);

    return asyncData.when(
      data: (users) {
        if (users.isEmpty) {
          return DentLinkEmptyState(
            icon: Icons.people_outline,
            title: 'Kullanıcı Bulunamadı',
            subtitle: widget.emptyMessage,
          );
        }

        // Guard: sadece ilk veri yüklemesinde çalışır.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadFollowStatuses(users);
        });

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
                userId: user.id,
              ),
            );
          },
        );
      },
      loading: () => const Center(child: DentLinkLoadingSpinner()),
      error: (error, stack) => DentLinkErrorWidget(
        message: 'Kullanıcılar yüklenirken bir hata oluştu.',
        onRetry: () => ref.invalidate(widget.provider),
      ),
    );
  }
}

class _FollowButton extends ConsumerStatefulWidget {
  final String userId;

  const _FollowButton({super.key, required this.userId});

  @override
  ConsumerState<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends ConsumerState<_FollowButton> {
  bool _isLoading = false;

  Future<void> _toggleFollow() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await ref
          .read(followingStateProvider.notifier)
          .toggleFollow(widget.userId);

      if (mounted) {
        // İlgili profil provider'ını yenile (takipçi sayısı güncellenmesi için).
        ref.invalidate(userProfileProvider(widget.userId));

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
    final isFollowing = ref.watch(isFollowingProvider(widget.userId));

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
          : Text(isFollowing ? 'Takibi Bırak' : 'Takip Et'),
    );
  }
}

