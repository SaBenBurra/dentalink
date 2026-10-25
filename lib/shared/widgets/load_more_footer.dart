import 'package:flutter/material.dart';

import '../../core/constants/app_dimensions.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../utils/error_messages.dart';
import 'loading_indicator.dart';

/// Sayfalı listenin son öğesi; yalnızca daha fazla sayfa varken eklenir.
///
/// [auto] (varsayılan) footer göründüğü sürece [onLoadMore]'u çağırır: sayfa
/// geldikten sonra hâlâ ekrandaysa (liste kısa ya da filtreli sekmede yeni öğe
/// yok) bir sonrakini ister. Tüm öğeleri bir kerede kuran (`shrinkWrap`)
/// listelerde [auto] false verilir; o zaman "Daha fazla göster" butonu çıkar.
/// Yüklenirken spinner, hata olursa mesaj ve "Tekrar Dene" gösterir.
class LoadMoreFooter extends StatefulWidget {
  const LoadMoreFooter({super.key, required this.onLoadMore, this.auto = true});

  final Future<void> Function() onLoadMore;
  final bool auto;

  @override
  State<LoadMoreFooter> createState() => _LoadMoreFooterState();
}

class _LoadMoreFooterState extends State<LoadMoreFooter> {
  late bool _loading = widget.auto;
  Object? _error;

  @override
  void initState() {
    super.initState();
    if (widget.auto) _load();
  }

  void _start() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _load();
  }

  Future<void> _load() async {
    try {
      await widget.onLoadMore();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e;
        });
      }
      return;
    }
    if (!mounted) return;
    if (!widget.auto) return setState(() => _loading = false);
    // Yeni sayfa çizildikten sonra footer hâlâ ağaçtaysa sıradakini iste.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final error = _error;
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacing16),
      child: error != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(getErrorMessage(l10n, error), textAlign: TextAlign.center),
                TextButton(onPressed: _start, child: Text(l10n.retry)),
              ],
            )
          : _loading || widget.auto
              ? const DentLinkLoadingSpinner(size: 24, strokeWidth: 2)
              : Center(
                  child: TextButton(onPressed: _start, child: Text(l10n.showMore)),
                ),
    );
  }
}
