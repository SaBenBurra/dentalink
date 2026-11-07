import 'package:dentigo/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_dimensions.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../data/models/case_treatment.dart';
import '../../data/models/enums.dart';
import '../extensions/dental_branch_ui.dart';
import '../extensions/treatment_type_ui.dart';

/// Tedavinin arşiv sayfasını açar. [heroTag] verilirse çip başlığa uçar.
void openTreatment(
  BuildContext context,
  CaseTreatment treatment, {
  Object? heroTag,
}) => context.pushDetail(
  '/treatment/${treatment.slug}',
  extra: (treatment: treatment, heroTag: heroTag),
);

/// Keşfet'i bu branş seçili açar (arama temizlenir).
void openBranch(BuildContext context, DentalBranch branch) => context.go(
  Uri(path: '/search', queryParameters: {'branch': branch.dbValue}).toString(),
);

/// Tedavinin her yerde aynı görünümü: branş renginde nokta ve zemin tonu.
/// Bu görünüm yalnızca tedavi için kullanılır ve hep tedavi arşivine gider.
/// Görünen yükseklik 32, dokunma alanı 48dp. Arşive giden çip kendine özgü
/// bir Hero etiketi taşır: aynı vaka ekranda iki kez olsa da çakışmaz.
class TreatmentChip extends StatefulWidget {
  const TreatmentChip({
    super.key,
    required this.treatment,
    this.onTap,
    this.heroTag,
    this.showCount = false,
    this.interactive = true,
  });

  final CaseTreatment treatment;

  /// Null ise arşivi açar.
  final VoidCallback? onTap;

  /// Arşiv başlığında: karttaki çipin Hero etiketi (çip başlığa uçar).
  final Object? heroTag;

  /// Vaka sayısını adın yanında gösterir (Keşfet branş satırı).
  final bool showCount;

  /// false: yalnızca gösterim (arşiv başlığı); dokunulmaz, görünüm aynı.
  final bool interactive;

  @override
  State<TreatmentChip> createState() => _TreatmentChipState();
}

class _TreatmentChipState extends State<TreatmentChip> {
  final _heroTag = Object();

  @override
  Widget build(BuildContext context) {
    final TreatmentChip(:treatment, :onTap, :showCount, :interactive) = widget;
    final opensArchive = interactive && onTap == null;
    final heroTag = widget.heroTag ?? (opensArchive ? _heroTag : null);
    final color = treatment.branch.colorOf(context);
    final colorScheme = Theme.of(context).colorScheme;
    final chip = TextButton(
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacing12,
        ),
        tapTargetSize: MaterialTapTargetSize.padded,
        backgroundColor: color.withValues(alpha: 0.12),
        foregroundColor: colorScheme.onSurface,
        disabledBackgroundColor: color.withValues(alpha: 0.12),
        disabledForegroundColor: colorScheme.onSurface,
        textStyle: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        shape: const StadiumBorder(),
      ),
      onPressed: !interactive
          ? null
          : onTap ?? () => openTreatment(context, treatment, heroTag: heroTag),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppDimensions.spacing6),
          Flexible(
            child: Text(
              treatment.displayName(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (showCount) ...[
            const SizedBox(width: AppDimensions.spacing6),
            Text(
              '${treatment.caseCount}',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
    final tag = heroTag;
    if (tag == null) return chip;
    return Hero(
      tag: tag,
      child: Material(type: MaterialType.transparency, child: chip),
    );
  }
}

/// Post sayfasında bütün tedaviler, branşa göre gruplu. Branş adı Keşfet'i o
/// branşla açar; çipler arşive gider.
class CaseTreatmentsSection extends StatelessWidget {
  const CaseTreatmentsSection({super.key, required this.treatments});

  final List<CaseTreatment> treatments;

  @override
  Widget build(BuildContext context) {
    if (treatments.isEmpty) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;
    // Branşlar ilk geçtikleri sırayla.
    final byBranch = <DentalBranch, List<CaseTreatment>>{};
    for (final t in treatments) {
      (byBranch[t.branch] ??= []).add(t);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spacing16,
        0,
        AppDimensions.spacing16,
        AppDimensions.spacing8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.postTreatment,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          for (final MapEntry(key: branch, value: items) in byBranch.entries)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: branch.colorOf(context),
                  ),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.chevron_right_rounded, size: 18),
                  label: Text(
                    branch.shortName(context),
                    semanticsLabel: branch.displayName(context),
                  ),
                  onPressed: () => openBranch(context, branch),
                ),
                const SizedBox(width: AppDimensions.spacing8),
                Expanded(
                  child: Wrap(
                    spacing: AppDimensions.spacing6,
                    children: [
                      for (final t in items) TreatmentChip(treatment: t),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
