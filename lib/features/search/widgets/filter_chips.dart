import 'package:dentigo/core/constants/app_dimensions.dart';
import 'package:dentigo/core/l10n/generated/app_localizations.dart';
import 'package:dentigo/core/utils/string_utils.dart';
import 'package:dentigo/shared/extensions/dental_branch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/enums.dart';
import '../../../providers/search_provider.dart';

/// Yatay branş seçimi: başta "Tümü", ardından kısa adlarla alfabetik branşlar
/// (tam ad tooltip'te). Seçilen çip görünür alana kayar; devamı olan kenar solar.
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
    final selected = ref.watch(searchProvider.select((s) => s.branch));
    // Popüler etiket seçimi branşı Tümü'ye çektiğinde de görünür olsun.
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
                child: Row(
                  children: [chip(null), for (final b in branches) chip(b)],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
