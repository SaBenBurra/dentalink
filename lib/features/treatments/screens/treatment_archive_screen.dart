import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../data/models/case_treatment.dart';
import '../../../providers/treatment_archive_provider.dart';
import '../../../shared/extensions/dental_branch_ui.dart';
import '../../../shared/extensions/treatment_type_ui.dart';
import '../../../shared/utils/error_messages.dart';
import '../../../shared/utils/post_actions.dart';
import '../../../shared/widgets/case_treatments.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/load_more_footer.dart';
import '../../../shared/widgets/post_card_factory.dart';

/// Bir tedavinin arşivi (`/treatment/:slug`): yalnızca o tedavinin seçildiği
/// vakalar, en yeni ya da en popüler önce. Başlıktaki branş Keşfet'i açar.
class TreatmentArchiveScreen extends ConsumerWidget {
  const TreatmentArchiveScreen({
    super.key,
    required this.slug,
    this.initial,
    this.heroTag,
  });

  final String slug;

  /// Karttan gelindiyse elde olan tedavi: başlık beklemeden çizilir.
  final CaseTreatment? initial;

  /// Karttaki çipin Hero etiketi; başlıktaki çip aynı etiketle uçar.
  final Object? heroTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final provider = treatmentArchiveProvider(slug);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    final info = ref.watch(treatmentInfoProvider(slug)).valueOrNull;
    final treatment = info ?? initial;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 0,
        title: Text(treatment?.displayName(context) ?? ''),
      ),
      body: RefreshIndicator(
        onRefresh: () {
          ref.invalidate(treatmentInfoProvider(slug));
          return notifier.refresh();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.spacing16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (treatment != null) ...[
                      Row(
                        children: [
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              foregroundColor: treatment.branch.colorOf(
                                context,
                              ),
                            ),
                            iconAlignment: IconAlignment.end,
                            icon: const Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                            ),
                            label: Text(treatment.branch.displayName(context)),
                            onPressed: () =>
                                openBranch(context, treatment.branch),
                          ),
                        ],
                      ),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: AppDimensions.spacing12,
                        children: [
                          TreatmentChip(
                            treatment: treatment,
                            heroTag: heroTag,
                            interactive: false,
                          ),
                          if (info != null)
                            Text(
                              l10n.treatmentCaseCount(info.caseCount),
                              style: textTheme.bodyMedium,
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppDimensions.spacing12),
                    SegmentedButton<bool>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: true,
                          label: Text(l10n.archiveSortRecent),
                        ),
                        ButtonSegment(
                          value: false,
                          label: Text(l10n.archiveSortPopular),
                        ),
                      ],
                      selected: {state.recent},
                      onSelectionChanged: (s) => notifier.setRecent(s.first),
                    ),
                  ],
                ),
              ),
            ),
            ...state.posts.when(
              data: (posts) => [
                if (posts.isEmpty)
                  SliverToBoxAdapter(
                    child: DentLinkEmptyState(
                      icon: Icons.folder_open_outlined,
                      title: l10n.archiveEmpty,
                    ),
                  )
                else
                  SliverList.separated(
                    itemCount: posts.length + (state.hasMore ? 1 : 0),
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppDimensions.spacing8),
                    itemBuilder: (context, index) {
                      if (index == posts.length) {
                        return LoadMoreFooter(onLoadMore: notifier.loadMore);
                      }
                      final post = posts[index];
                      return PostCardFactory.build(
                        post,
                        onLikeToggle: () => runOrShowError(
                          context,
                          () => notifier.toggleLike(post.id),
                        ),
                        onBookmarkToggle: () => runOrShowError(
                          context,
                          () => notifier.toggleBookmark(post.id),
                        ),
                        onCommentTap: () =>
                            openPost(context, post, comments: true),
                        onTap: () => openPost(context, post),
                      );
                    },
                  ),
              ],
              loading: () => const [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(AppDimensions.spacing32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              ],
              error: (err, _) => [
                SliverToBoxAdapter(
                  child: DentLinkErrorWidget(
                    message: getErrorMessage(l10n, err),
                    onRetry: notifier.refresh,
                  ),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height:
                    AppDimensions.spacing16 +
                    MediaQuery.paddingOf(context).bottom,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
