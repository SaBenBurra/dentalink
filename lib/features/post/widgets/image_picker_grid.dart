import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:dentigo/core/l10n/generated/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dentigo/core/constants/app_dimensions.dart';
import 'package:dentigo/core/utils/media_prepare.dart';
import 'package:dentigo/core/utils/video_prepare.dart';
import 'package:dentigo/shared/utils/error_messages.dart';
import 'form_section_label.dart';
import 'media_reorder_strip.dart';

/// Kısa kenarı 320px altı ya da 1:4'ten dar görseller feed'de anlamsız görünür (4:5–1.91:1
/// çerçevede aşırı büyür/kırpılır). Panoramik röntgen (~2.5:1) sınırın içinde kalır.
bool isAcceptableImageSize(int width, int height) {
  final short = width < height ? width : height;
  final long = width < height ? height : width;
  return short >= 320 && long <= short * 4;
}

/// Vaka veya forum gönderisi oluştururken kullanılacak görsel ve video seçici.
///
/// `image_picker` paketi ile cihazın galerisine/kamerasına bağlanır. Görseller
/// ve en fazla 1 video (≤60 sn) tek listede durur, basılı tutup sürükleyerek
/// sıralanır; liste bu sırayla [onChanged] ile parent widget'a iletilir.
/// Video [maxImages] sınırına sayılır.
class ImagePickerGrid extends StatefulWidget {
  final int maxImages;
  final ValueChanged<List<PickedMedia>> onChanged;

  const ImagePickerGrid({
    super.key,
    this.maxImages = 10,
    required this.onChanged,
  });

  @override
  State<ImagePickerGrid> createState() => _ImagePickerGridState();
}

class _ImagePickerGridState extends State<ImagePickerGrid> {
  final List<_Item> _media = [];
  Duration? _videoLength;
  final ImagePicker _picker = ImagePicker();

  int get _count => _media.length;
  bool get _hasVideo => _media.any((m) => m.media.isVideo);

  void _notify() =>
      widget.onChanged(List.unmodifiable([for (final m in _media) m.media]));

  Future<void> _showPickerSourceModal() async {
    if (_count >= widget.maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.maxImagesReached(widget.maxImages),
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(AppLocalizations.of(context)!.pickFromGallery),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImages(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(AppLocalizations.of(context)!.pickFromCamera),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImages(ImageSource.camera);
                },
              ),
              if (!_hasVideo) ...[
                ListTile(
                  leading: const Icon(Icons.video_library_outlined),
                  title: Text(
                    AppLocalizations.of(context)!.pickVideoFromGallery,
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickVideo(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.videocam_outlined),
                  title: Text(AppLocalizations.of(context)!.recordVideo),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickVideo(ImageSource.camera);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImages(ImageSource source) async {
    final remaining = widget.maxImages - _count;
    if (remaining <= 0) return;
    // Kalite yüklemede WebP kodlamasında belirlenir (compressToWebp); burada yalnızca boyut.
    const maxSide = 2048.0;

    final List<XFile> picked;
    try {
      if (source == ImageSource.camera || remaining == 1) {
        // pickMultiImage limit'i en az 2 ister; tek yer kaldıysa tekli seçim.
        final file = await _picker.pickImage(
          source: source,
          maxWidth: maxSide,
          maxHeight: maxSide,
        );
        picked = [?file];
      } else {
        picked = await _picker.pickMultiImage(
          maxWidth: maxSide,
          maxHeight: maxSide,
          limit: remaining,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getErrorMessage(AppLocalizations.of(context)!, e)),
        ),
      );
      return;
    }
    if (!mounted || picked.isEmpty) return;

    final accepted = [
      for (final xf in picked)
        if (await _hasAcceptableSize(xf.path)) File(xf.path),
    ];
    if (!mounted) return;
    if (accepted.length < picked.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.imagesRejectedSize),
        ),
      );
    }
    if (accepted.isEmpty) return;

    // Bazı galeri uygulamaları limit'i yok sayar; fazlası atılır ama kullanıcıya söylenir.
    setState(() {
      _media.addAll([
        for (final f in accepted.take(remaining))
          _Item((file: f, isVideo: false)),
      ]);
    });
    _notify();
    if (accepted.length > remaining) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.maxImagesReached(widget.maxImages),
          ),
        ),
      );
    }
  }

  /// Boyut başlıktan okunur (tam decode yok); okunamazsa görsel kabul edilir.
  static Future<bool> _hasAcceptableSize(String path) async {
    try {
      final buffer = await ui.ImmutableBuffer.fromFilePath(path);
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      final ok = isAcceptableImageSize(descriptor.width, descriptor.height);
      descriptor.dispose();
      buffer.dispose();
      return ok;
    } catch (_) {
      return true;
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final XFile? picked;
    final Duration? length;
    try {
      // maxDuration yalnızca kamerada uygulanır; galeri videosu aşağıda ölçülür.
      picked = await _picker.pickVideo(
        source: source,
        maxDuration: maxVideoDuration,
      );
      if (picked == null) return;
      length = await videoDuration(picked.path);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(getErrorMessage(l10n, e))));
      return;
    }
    if (!mounted) return;
    // Süre okunamazsa kabul edilir; boyut sınırı sıkıştırmada ve bucket'ta.
    if (length != null && !isAcceptableVideoDuration(length)) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.videoTooLong)));
      return;
    }
    setState(() {
      _media.add(_Item((file: File(picked!.path), isVideo: true)));
      _videoLength = length;
    });
    _notify();
  }

  void _remove(int index) {
    setState(() {
      if (_media.removeAt(index).media.isVideo) _videoLength = null;
    });
    _notify();
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() => _media.insert(newIndex, _media.removeAt(oldIndex)));
    _notify();
  }

  static String _formatLength(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormSectionLabel(
          icon: Icons.photo_library_outlined,
          label: AppLocalizations.of(context)!.images,
          trailing: Text(
            '$_count/${widget.maxImages}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spacing12),
        MediaReorderStrip(
          onReorder: _reorder,
          header: Padding(
            padding: const EdgeInsets.only(
              top: AppDimensions.spacing12,
              right: AppDimensions.spacing12,
            ),
            child: InkWell(
              onTap: _showPickerSourceModal,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: MediaReorderStrip.tileSize,
                height: MediaReorderStrip.tileSize,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      color: colorScheme.primary,
                      size: 32,
                    ),
                    const SizedBox(height: AppDimensions.spacing8),
                    Text(
                      AppLocalizations.of(context)!.addPhoto,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          children: [
            for (final (i, item) in _media.indexed)
              MediaTile(
                key: item.key,
                onRemove: () => _remove(i),
                child: item.media.isVideo
                    ? ColoredBox(
                        color: colorScheme.surfaceContainerHighest,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.play_circle_outline,
                              color: colorScheme.onSurfaceVariant,
                              size: 32,
                            ),
                            if (_videoLength case final d?) ...[
                              const SizedBox(height: AppDimensions.spacing4),
                              Text(
                                _formatLength(d),
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : Image.file(item.media.file, fit: BoxFit.cover),
              ),
          ],
        ),
      ],
    );
  }
}

/// Sıralanan öğe; aynı dosya iki kez seçilse de sürükleme için ayrı key taşır.
class _Item {
  _Item(this.media);
  final PickedMedia media;
  final key = UniqueKey();
}
