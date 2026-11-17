import 'package:dentigo/core/constants/app_dimensions.dart';
import 'package:dentigo/core/l10n/generated/app_localizations.dart';
import 'package:dentigo/core/utils/string_utils.dart';
import 'package:dentigo/shared/extensions/dental_branch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/enums.dart';
import '../../../providers/search_provider.dart';

/// Keşfet sekmeleri: Tümü, Kişiler, Vakalar, Forum, Ticaret. Vakalar seçiliyken
/// altında branş satırı açılır.
class ExploreFilterChips extends ConsumerWidget {
  const ExploreFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selected = ref.watch(searchProvider.select((s) => s.tab));
    final notifier = ref.read(searchProvider.notifier);
    String label(ExploreTab tab) => switch (tab) {
      ExploreTab.all => l10n.feedFilterAll,
      ExploreTab.people => l10n.explorePeople,
      ExploreTab.cases => l10n.feedFilterCases,
      ExploreTab.forum => l10n.feedFilterQuestions,
      ExploreTab.listings => l10n.feedFilterListings,
    };

    return Column(
      children: [
        _FadingChipRow(
          children: [
            for (final tab in ExploreTab.values)
              Padding(
                padding: const EdgeInsets.only(right: AppDimensions.spacing8),
                child: ChoiceChip(
                  label: Text(label(tab)),
                  selected: selected == tab,
                  showCheckmark: false,
                  onSelected: (_) => notifier.setTab(tab),
                ),
              ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: selected == ExploreTab.cases
              ? const BranchFilterChips()
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// Yatay branş seçimi: başta "Tümü", ardından kısa adlarla alfabetik branşlar
/// (tam ad tooltip'te). Seçilen çip görünür alana kayar.
class BranchFilterChips extends ConsumerStatefulWidget {
  const BranchFilterChips({super.key});

  @override
  ConsumerState<BranchFilterChips> createState() => _BranchFilterChipsState();
}

class _BranchFilterChipsState extends ConsumerState<BranchFilterChips> {
  /// null anahtarı "Tümü".
  final _keys = {
    for (final b in [null, ...DentalBranch.values]) b: GlobalKey(),
  };

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(searchProvider.select((s) => s.branch));
    // Branş linkiyle seçildiğinde de görünür olsun.
    ref.listen(searchProvider.select((s) => s.branch), (_, next) {
      final chip = _keys[next]!.currentContext;
      if (chip != null) {
        Scrollable.ensureVisible(
          chip,
          alignment: 0.5,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
    final notifier = ref.read(searchProvider.notifier);
    final branches = [...DentalBranch.values]
      ..sort(
        (a, b) => compareTurkish(a.shortName(context), b.shortName(context)),
      );

    Widget chip(DentalBranch? branch) => Padding(
      key: _keys[branch],
      padding: const EdgeInsets.only(right: AppDimensions.spacing8),
      child: ChoiceChip(
        label: Text(
          branch?.shortName(context) ??
              AppLocalizations.of(context)!.feedFilterAll,
        ),
        tooltip: branch?.displayName(context),
        selected: selected == branch,
        showCheckmark: false,
        onSelected: (_) => notifier.setBranch(branch),
      ),
    );

    return _FadingChipRow(
      children: [chip(null), for (final b in branches) chip(b)],
    );
  }
}

/// Yana kayan çip satırı; devamı olan kenar solar.
class _FadingChipRow extends StatefulWidget {
  const _FadingChipRow({required this.children});

  final List<Widget> children;

  @override
  State<_FadingChipRow> createState() => _FadingChipRowState();
}

class _FadingChipRowState extends State<_FadingChipRow> {
  bool _fadeLeft = false;
  bool _fadeRight = false;

  bool _updateFades(ScrollMetrics m) {
    final left = m.pixels > 0;
    final right = m.pixels < m.maxScrollExtent;
    if (left != _fadeLeft || right != _fadeRight) {
      setState(() {
        _fadeLeft = left;
        _fadeRight = right;
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        Color edge(bool fade) => fade ? Colors.transparent : Colors.white;
        return ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) => LinearGradient(
            colors: [
              edge(_fadeLeft),
              Colors.white,
              Colors.white,
              edge(_fadeRight),
            ],
            stops: [0, 24 / w, 1 - 24 / w, 1],
          ).createShader(rect),
          child: NotificationListener<ScrollMetricsNotification>(
            onNotification: (n) => _updateFades(n.metrics),
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) => _updateFades(n.metrics),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacing16,
                  vertical: AppDimensions.spacing4,
                ),
                child: Row(children: widget.children),
              ),
            ),
          ),
        );
      },
    );
  }
}
