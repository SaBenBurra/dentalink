import 'package:dentlink/features/feed/widgets/feed_list.dart';
import 'package:dentlink/features/feed/widgets/feed_screen_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../data/models/enums.dart';
import '../../../providers/feed_provider.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final feedState = ref.watch(feedProvider);

    final backgroundColor = isDark
        ? const Color(0xFF11211F)
        : AppColors.bgGradientStart;

    final glassBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.8);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            FeedScreenAppBar(
              isDark: isDark,
              glassBorderColor: glassBorderColor,
              textTheme: textTheme,
              colorScheme: colorScheme,
              tabController: _tabController,
              l10n: l10n,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            FeedList(
              ref: ref,
              context: context,
              feedState: feedState,
              filterType: null,
              l10n: l10n,
              colorScheme: colorScheme,
            ),
            FeedList(
              ref: ref,
              context: context,
              feedState: feedState,
              filterType: PostType.casePost,
              l10n: l10n,
              colorScheme: colorScheme,
            ),
            FeedList(
              ref: ref,
              context: context,
              feedState: feedState,
              filterType: PostType.question,
              l10n: l10n,
              colorScheme: colorScheme,
            ),
          ],
        ),
      ),
    );
  }
}
