import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/utils/string_utils.dart';
import '../../../data/models/case_treatment.dart';
import '../../../data/models/enums.dart';
import '../../../shared/extensions/dental_branch_ui.dart';
import '../../../shared/extensions/treatment_type_ui.dart';
import 'tag_input.dart';

/// Tedavi seçme penceresi: arama (tüm branşlarda, eş anlamlılar sunucuda) ve
/// branşa göz atma. Hiçbir zaman tüm listeyi göstermez. Listede olmayan tedavi
/// "ekle" ile girilir; branşı bilinmiyorsa tek soru sorulur.
/// [taken] zaten seçili tedavilerin slug'ları (gri görünür).
Future<CaseTreatment?> showTreatmentPicker(
  BuildContext context, {
  required Set<String> taken,
  required Future<List<CaseTreatment>> Function(String query) search,
}) => showModalBottomSheet<CaseTreatment>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => FractionallySizedBox(
    heightFactor: 0.85,
    child: TreatmentPicker(taken: taken, search: search),
  ),
);

/// Karşılaştırma anahtarı: Türkçe harf, büyük/küçük, boşluk ve tire farkı yok.
String _key(String s) => slugify(s).replaceAll('-', '');

/// Yazılan adın etiket biçimi ("Zirkonya İnley" → "zirkonya-inley").
String customTreatmentName(String value) =>
    TagInput.normalize(value).replaceAll(RegExp(r'\s+'), '-');

class TreatmentPicker extends StatefulWidget {
  const TreatmentPicker({super.key, required this.taken, required this.search});

  final Set<String> taken;
  final Future<List<CaseTreatment>> Function(String query) search;

  @override
  State<TreatmentPicker> createState() => _TreatmentPickerState();
}

class _TreatmentPickerState extends State<TreatmentPicker> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;

  /// Göz atılan branş.
  DentalBranch? _branch;

  /// "Listede yok mu? Ekle" ile gelindiyse eklenecek tedavinin branşı belli.
  DentalBranch? _customBranch;

  /// Branşı sorulan yeni tedavinin adı.
  String? _askBranchFor;

  List<CaseTreatment> _remote = const [];

  String get _query => _controller.text.trim();

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    _debounce?.cancel();
    final query = _query;
    setState(() => _remote = const []);
    if (_key(query).length < TagInput.minSuggestLength) return;
    _debounce = Timer(TagInput.suggestDebounce, () async {
      List<CaseTreatment> result;
      try {
        result = await widget.search(query);
      } catch (_) {
        result =
            const []; // Liste yerelde de aranıyor; sunucu hatası seçimi engellemesin.
      }
      if (!mounted || _query != query) return;
      setState(() => _remote = result);
    });
  }

  /// Önce listedekiler (aktif dildeki adla), sonra sunucunun bulduğu eş
  /// anlamlı ve kullanıcı tedavileri; slug başına bir satır.
  List<CaseTreatment> _results(BuildContext context) {
    final key = _key(_query);
    final seen = <String>{};
    return [
      for (final t in TreatmentType.values)
        if (_key(t.displayName(context)).contains(key) && seen.add(t.dbValue))
          CaseTreatment.listed(t),
      for (final t in _remote)
        if (seen.add(t.slug)) t,
    ];
  }

  void _addCustom(String name) {
    final branch = _customBranch;
    if (branch == null) return setState(() => _askBranchFor = name);
    _pickCustom(name, branch);
  }

  void _pickCustom(String name, DentalBranch branch) => Navigator.pop(
    context,
    CaseTreatment(slug: slugify(name), name: name, branch: branch),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final ask = _askBranchFor;

    final Widget body;
    if (ask != null) {
      body = ListView(
        padding: const EdgeInsets.all(AppDimensions.spacing16),
        children: [
          Text(
            l10n.treatmentWhichBranch(humanizeTag(ask)),
            style: textTheme.titleSmall,
          ),
          const SizedBox(height: AppDimensions.spacing12),
          _BranchChips(onSelected: (b) => _pickCustom(ask, b)),
        ],
      );
    } else if (_query.isEmpty) {
      final branch = _branch;
      body = ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.treatmentBrowseByBranch, style: textTheme.titleSmall),
                const SizedBox(height: AppDimensions.spacing12),
                _BranchChips(
                  selected: branch,
                  onSelected: (b) =>
                      setState(() => _branch = b == _branch ? null : b),
                ),
              ],
            ),
          ),
          if (branch != null) ...[
            for (final t in TreatmentType.forBranch(branch))
              _TreatmentTile(
                treatment: CaseTreatment.listed(t),
                taken: widget.taken.contains(t.dbValue),
                showBranch: false,
              ),
            ListTile(
              leading: const Icon(Icons.add_rounded),
              title: Text(l10n.treatmentNotListed),
              onTap: () {
                setState(() => _customBranch = branch);
                _focusNode.requestFocus();
              },
            ),
          ],
        ],
      );
    } else {
      final results = _results(context);
      final name = customTreatmentName(_query);
      final exact = results.any((t) => _key(t.name) == _key(name));
      body = ListView(
        children: [
          for (final t in results)
            _TreatmentTile(
              treatment: t,
              taken: widget.taken.contains(t.slug),
              showBranch: true,
            ),
          if (!exact && slugify(name).isNotEmpty)
            ListTile(
              leading: const Icon(Icons.add_rounded),
              title: Text(l10n.treatmentAddCustom(humanizeTag(name))),
              subtitle: _customBranch == null
                  ? null
                  : Text(_customBranch!.displayName(context)),
              onTap: () => _addCustom(name),
            ),
        ],
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacing16,
          ),
          // Klavye kendiliğinden açılmaz: branş çipleri görünür kalsın.
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            maxLength: TagInput.maxTagLength, // DB: tags_name_length (017)
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l10n.treatmentSearchHint,
              prefixIcon: const Icon(Icons.search_rounded),
              counterText: '',
            ),
            onChanged: (v) {
              if (_askBranchFor != null) _askBranchFor = null;
              _onChanged(v);
            },
          ),
        ),
        Expanded(child: body),
      ],
    );
  }
}

class _TreatmentTile extends StatelessWidget {
  const _TreatmentTile({
    required this.treatment,
    required this.taken,
    required this.showBranch,
  });

  final CaseTreatment treatment;
  final bool taken;
  final bool showBranch;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: !taken,
      leading: Icon(
        Icons.circle,
        size: 12,
        color: treatment.branch.colorOf(context),
      ),
      title: Text(treatment.displayName(context)),
      subtitle: showBranch ? Text(treatment.branch.displayName(context)) : null,
      trailing: taken ? const Icon(Icons.check_rounded) : null,
      onTap: () => Navigator.pop(context, treatment),
    );
  }
}

/// Kısa adlarla alfabetik branşlar; tam ad tooltip'te (Keşfet'teki gibi).
class _BranchChips extends StatelessWidget {
  const _BranchChips({this.selected, required this.onSelected});

  final DentalBranch? selected;
  final ValueChanged<DentalBranch> onSelected;

  @override
  Widget build(BuildContext context) {
    final branches = [...DentalBranch.values]
      ..sort(
        (a, b) => compareTurkish(a.shortName(context), b.shortName(context)),
      );
    return Wrap(
      spacing: AppDimensions.spacing8,
      runSpacing: AppDimensions.spacing8,
      children: [
        for (final b in branches)
          ChoiceChip(
            avatar: Icon(Icons.circle, size: 10, color: b.colorOf(context)),
            label: Text(b.shortName(context)),
            tooltip: b.displayName(context),
            selected: b == selected,
            showCheckmark: false,
            onSelected: (_) => onSelected(b),
          ),
      ],
    );
  }
}
