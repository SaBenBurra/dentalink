import 'package:flutter/material.dart';
import 'package:dentigo/core/constants/app_dimensions.dart';
import 'package:dentigo/core/l10n/generated/app_localizations.dart';

/// Gönderi medyası için yatay şerit: basılı tutup sürükleyerek sıralanır.
/// Ekran okuyucuda öğenin "sola/sağa taşı" eylemleri vardır (ReorderableListView).
/// [children] benzersiz key taşımalı; [header] (ör. ekle butonu) sıralanmaz.
class MediaReorderStrip extends StatelessWidget {
  const MediaReorderStrip({
    super.key,
    required this.children,
    required this.onReorder,
    this.header,
  });

  final List<Widget> children;
  final ReorderCallback onReorder;
  final Widget? header;

  static const tileSize = 100.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: tileSize + AppDimensions.spacing20,
          child: ReorderableListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            header: header,
            onReorderItem: onReorder,
            proxyDecorator: (child, _, _) =>
                Material(type: MaterialType.transparency, child: child),
            children: children,
          ),
        ),
        if (children.length > 1)
          Text(
            AppLocalizations.of(context)!.mediaReorderHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

/// Şeritteki medya kutusu; [onRemove] verilirse köşede sil düğmesi.
/// Görünen daire küçük, dokunma alanı 48dp (UX-14).
class MediaTile extends StatelessWidget {
  const MediaTile({super.key, required this.child, this.onRemove});

  final Widget child;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(
        top: AppDimensions.spacing12,
        right: AppDimensions.spacing12,
      ),
      child: SizedBox.square(
        dimension: MediaReorderStrip.tileSize,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox.expand(child: child),
            ),
            if (onRemove != null)
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  tooltip: AppLocalizations.of(context)!.delete,
                  onPressed: onRemove,
                  icon: Container(
                    padding: const EdgeInsets.all(AppDimensions.spacing4),
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.close,
                      color: colorScheme.onError,
                      size: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
