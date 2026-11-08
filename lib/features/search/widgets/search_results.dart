import 'package:dentigo/core/router/app_router.dart';
import 'package:dentigo/core/l10n/generated/app_localizations.dart';
import 'package:dentigo/shared/utils/post_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/search_provider.dart';
import '../../../providers/treatment_archive_provider.dart';
import '../../../data/models/case_treatment.dart';
import '../../../data/models/user_model.dart';
import '../../../shared/extensions/dental_branch_ui.dart';
import '../../../shared/extensions/treatment_type_ui.dart';
import '../../../shared/widgets/case_treatments.dart';
import '../../../shared/utils/error_messages.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/user_tile.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/load_more_footer.dart';
import 'package:dentigo/core/constants/app_dimensions.dart';
import 'package:dentigo/shared/widgets/post_card_factory.dart';

/// Keşfet gövdesi: popüler kişiler (Tümü, arama yokken), (metin aranıyorsa) kişiler,
/// popüler gönderiler.
class ExploreResults extends ConsumerWidget {
  const ExploreResults({super.key});

  /// Metin aramasında gösterilen en fazla kişi.
  static const maxPeople = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(searchProvider);
    final notifier = ref.read(searchProvider.notifier);
    final popularUsers = ref.watch(popularUsersProvider);
    final users = state.users.valueOrNull ?? const [];
    final branch = state.branch;
    final text = parseExploreQuery(state.query).text;
    // Yardımcı bölümler: hata postları engellemesin, yenilemede tekrar denenir.
    final branchTreatments = branch == null || state.query.trim().isNotEmpty
        ? const <CaseTreatment>[]
        : ref.watch(branchTreatmentsProvider(branch)).valueOrNull ?? const [];
    final treatments = text.isEmpty
        ? const <CaseTreatment>[]
        : ref.watch(treatmentSearchProvider(text)).valueOrNull ?? const [];

    return RefreshIndicator(
      onRefresh: () {
        ref.invalidate(popularUsersProvider);
        ref.invalidate(branchTreatmentsProvider);
        ref.invalidate(treatmentSearchProvider);
        return notifier.refresh();
      },
      child: CustomScrollView(
        slivers: [
          if (branch != null && branchTreatments.isNotEmpty) ...[
            _SectionHeader(l10n.branchTreatments(branch.displayName(context))),
            // Hepsi bir bakışta görünsün: yana kaydırma yok, satıra sığmayan alta iner.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacing16,
                ),
                child: Wrap(
                  spacing: AppDimensions.spacing6,
                  children: [
                    for (final t in branchTreatments)
                      TreatmentChip(treatment: t, showCount: true),
                  ],
                ),
              ),
            ),
          ],
          // Aranan metin bir tedaviyse arşivine kısa yol.
          if (treatments.isNotEmpty)
            SliverList.list(
              children: [
                for (final t in treatments)
                  ListTile(
                    leading: Icon(
                      Icons.folder_open_rounded,
                      color: t.branch.colorOf(context),
                    ),
                    title: Text(
                      t.displayName(context),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${t.branch.displayName(context)} · '
                      '${l10n.treatmentCaseCount(t.caseCount)}',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => openTreatment(context, t),
                  ),
              ],
            ),
          // Yalnızca Tümü'de ve arama yokken; sonuçları aşağı itmesin.
          if (branch == null && state.query.trim().isEmpty)
            ...popularUsers.when(
              data: (list) => [
                if (list.isNotEmpty) ...[
                  _SectionHeader(l10n.explorePopularPeople),
                  _PeopleList(list),
                ],
              ],
              loading: () => [const _SectionHeader(null)],
              // Yardımcı bölüm; hata postları engellemesin, yenilemede tekrar denenir.
              error: (_, _) => const [],
            ),
          if (users.isNotEmpty) ...[
            _SectionHeader(l10n.explorePeople),
            _PeopleList(users.take(maxPeople)),
          ],
          _SectionHeader(l10n.explorePopularPosts),
          ...state.posts.when(
            data: (posts) => [
              if (posts.isEmpty)
                SliverToBoxAdapter(
                  child: DentigoEmptyState(
                    icon: Icons.article_outlined,
                    title: l10n.searchNoResultsTitle,
                    subtitle: l10n.searchNoPosts,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(top: AppDimensions.spacing16),
                  sliver: SliverList.separated(
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
                ),
            ],
            loading: () => const [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppDimensions.spacing32),
                  child: DentigoLoadingSpinner(),
                ),
              ),
            ],
            error: (err, _) => [
              SliverToBoxAdapter(
                child: DentigoErrorWidget(
                  message: getErrorMessage(l10n, err),
                  onRetry: notifier.refresh,
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height:
                  AppDimensions.spacing8 + MediaQuery.paddingOf(context).bottom,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  /// Null ise yüklenirken ince ilerleme çubuğu.
  const _SectionHeader(this.title);

  final String? title;

  @override
  Widget build(BuildContext context) {
    final title = this.title;
    return SliverToBoxAdapter(
      child: title == null
          ? const LinearProgressIndicator()
          : Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spacing16,
                AppDimensions.spacing16,
                AppDimensions.spacing16,
                AppDimensions.spacing4,
              ),
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
    );
  }
}

/// Kişi satırları; [UserTile] yan boşluk vermez, bölüm başlığıyla hizalanır.
class _PeopleList extends StatelessWidget {
  const _PeopleList(this.users);

  final Iterable<UserModel> users;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing16),
      sliver: SliverList.list(
        children: [
          for (final user in users)
            UserTile(
              user: user,
              onTap: () => context.pushDetail('/profile/${user.id}'),
            ),
        ],
      ),
    );
  }
}
