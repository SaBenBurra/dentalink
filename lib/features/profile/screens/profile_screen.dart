import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'package:dentlink/shared/extensions/post_type_l10n.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_provider.dart';
import '../../feed/widgets/feed_filter_segments.dart';
import '../../feed/widgets/feed_screen_app_bar.dart' show HeaderIconButton;
import '../widgets/profile_header.dart';
import '../widgets/badge_showcase.dart';
import '../widgets/profile_posts_tab.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/user_model.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/utils/error_messages.dart';
import '../../../shared/utils/moderation_actions.dart';

class ProfileScreen extends ConsumerWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentUserState = ref.watch(authProvider);
    final currentUser = currentUserState.valueOrNull;

    final isCurrentUser = userId == null || (currentUser != null && userId == currentUser.id);
    final targetUserId = userId ?? currentUser?.id;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Ana sayfayla aynı zemin.
    final background = isDark ? AppColors.darkBackground : AppColors.bgGradientStart;

    if (targetUserId == null) {
      return Scaffold(
        backgroundColor: background,
        body: Column(
          children: [
            const _ProfileTopBar(title: ''),
            Expanded(child: Center(child: Text(l10n.userNotFound))),
          ],
        ),
      );
    }

    final AsyncValue<UserModel?> userState = isCurrentUser
        ? currentUserState
        : ref.watch(userProfileProvider(targetUserId));

    final Widget body = userState.when(
      data: (user) {
        if (user == null) {
          return Center(child: Text(l10n.userNotFound));
        }
        // null = Tümü (anasayfadaki gibi).
        final types = <PostType?>[null, ...PostType.profileTabs];
        final labels = [
          for (final type in types)
            type?.getLabelInProfile(context) ?? l10n.feedFilterAll,
        ];
        return DefaultTabController(
          length: types.length,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: ProfileHeader(user: user, isCurrentUser: isCurrentUser),
              ),
              SliverToBoxAdapter(child: BadgeShowcase(userId: user.id)),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SegmentsHeaderDelegate(labels, background),
              ),
            ],
            body: TabBarView(
              children: [
                for (final type in types)
                  ProfilePostsTab(userId: user.id, type: type),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => DentLinkErrorWidget(
        message: getErrorMessage(l10n, error),
        onRetry: () {
          if (isCurrentUser) {
            ref.invalidate(authProvider);
          } else {
            ref.invalidate(userProfileProvider(targetUserId));
          }
        },
      ),
    );

    return Scaffold(
      backgroundColor: background,
      body: Column(
        children: [
          _ProfileTopBar(
            title: l10n.profileTitle,
            actions: isCurrentUser
                ? [
                    HeaderIconButton(
                      icon: Icons.bookmark_border_rounded,
                      tooltip: l10n.bookmarksTitle,
                      onTap: () => context.push('/bookmarks'),
                    ),
                    HeaderIconButton(
                      icon: Icons.settings_outlined,
                      tooltip: l10n.settingsTitle,
                      onTap: () => context.push('/settings'),
                    ),
                  ]
                : [
                    ModerationMenuButton(
                      target: ReportTarget.user,
                      targetId: targetUserId,
                      userId: targetUserId,
                      onBlocked: () => context.canPop() ? context.pop() : context.go('/feed'),
                    ),
                  ],
          ),
          Expanded(
            // Durum çubuğu payını üst bar aldı.
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: body,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ana sayfa üst barıyla aynı yüzey: geri (varsa), kullanıcı adı, ikonlar.
class _ProfileTopBar extends StatelessWidget {
  const _ProfileTopBar({required this.title, this.actions = const []});

  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canPop = context.canPop();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: theme.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Material(
        color: colorScheme.surface.withValues(alpha: 0.96),
        child: SafeArea(
          bottom: false,
          child: Container(
            height: kToolbarHeight,
            padding: EdgeInsets.only(
              left: canPop ? 0 : AppDimensions.spacing16,
              right: AppDimensions.spacing4,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colorScheme.surfaceContainerHigh),
              ),
            ),
            child: Row(
              children: [
                if (canPop)
                  HeaderIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                    onTap: () => context.pop(),
                  ),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ...actions,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sabitlenen sekme rayı; ana sayfadaki segmentlerin aynısı.
class _SegmentsHeaderDelegate extends SliverPersistentHeaderDelegate {
  _SegmentsHeaderDelegate(this.labels, this.background);

  final List<String> labels;
  final Color background;

  static const double _height = 56;

  @override
  double get minExtent => _height;
  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final tabs = DefaultTabController.of(context);
    return Container(
      color: background,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing16),
      alignment: Alignment.center,
      child: AnimatedBuilder(
        animation: tabs,
        builder: (context, _) => FeedFilterSegments(
          labels: labels,
          selectedIndex: tabs.index,
          onSelected: tabs.animateTo,
          position: tabs.animation,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SegmentsHeaderDelegate oldDelegate) =>
      !listEquals(labels, oldDelegate.labels) || background != oldDelegate.background;
}
