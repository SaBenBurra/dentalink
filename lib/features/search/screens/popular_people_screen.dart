import 'package:dentigo/core/constants/app_dimensions.dart';
import 'package:dentigo/core/l10n/generated/app_localizations.dart';
import 'package:dentigo/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/search_provider.dart';
import '../../../shared/utils/error_messages.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/user_tile.dart';

/// Keşfet'teki "Popüler kişiler"in ilk 50'si, gerçek sıra numarasıyla (engellenenin
/// numarası atlanır) (`/popular-people`).
class PopularPeopleScreen extends ConsumerWidget {
  const PopularPeopleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.popularPeopleTitle)),
      body: ref
          .watch(topPeopleProvider)
          .when(
            data: (users) => users.isEmpty
                ? DentigoEmptyState(
                    icon: Icons.people_outline,
                    title: l10n.userNotFound,
                  )
                : RefreshIndicator(
                    onRefresh: () => ref.refresh(topPeopleProvider.future),
                    child: ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                        AppDimensions.spacing16,
                        AppDimensions.spacing8,
                        AppDimensions.spacing16,
                        AppDimensions.spacing8 +
                            MediaQuery.paddingOf(context).bottom,
                      ),
                      itemCount: users.length,
                      itemBuilder: (context, i) => Row(
                        children: [
                          SizedBox(
                            width: AppDimensions.spacing32,
                            child: Text(
                              '${users[i].rank}',
                              style: textTheme.titleSmall,
                            ),
                          ),
                          Expanded(
                            child: UserTile(
                              user: users[i].user,
                              onTap: () => context.pushDetail(
                                '/profile/${users[i].user.id}',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            loading: () => const DentigoLoadingSpinner(),
            error: (err, _) => DentigoErrorWidget(
              message: getErrorMessage(l10n, err),
              onRetry: () => ref.invalidate(topPeopleProvider),
            ),
          ),
    );
  }
}
