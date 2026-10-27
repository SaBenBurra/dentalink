import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dentlink/core/constants/app_dimensions.dart';
import 'package:dentlink/shared/utils/error_messages.dart';

/// Kısa kenarı 320px altı ya da 1:4'ten dar görseller feed'de anlamsız görünür (4:5–1.91:1
/// çerçevede aşırı büyür/kırpılır). Panoramik röntgen (~2.5:1) sınırın içinde kalır.
bool isAcceptableImageSize(int width, int height) {
  final short = width < height ? width : height;
  final long = width < height ? height : width;
  return short >= 320 && long <= short * 4;
}

/// Vaka veya Soru oluştururken kullanılacak Görsel Seçici Izgara.
///
/// `image_picker` paketi ile cihazın galerisine/kamerasına bağlanır.
/// Seçilen görseller [File] listesi olarak parent widget'a iletilir.
class ImagePickerGrid extends StatefulWidget {
  final int maxImages;
  final ValueChanged<List<File>> onImagesChanged;

  const ImagePickerGrid({
    super.key,
    this.maxImages = 10,
    required this.onImagesChanged,
  });

  @override
  State<ImagePickerGrid> createState() => _ImagePickerGridState();
}

class _ImagePickerGridState extends State<ImagePickerGrid> {
  final List<File> _images = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _showPickerSourceModal() async {
    if (_images.length >= widget.maxImages) {
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
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImages(ImageSource source) async {
    final remaining = widget.maxImages - _images.length;
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
      _images.addAll(accepted.take(remaining));
    });
    widget.onImagesChanged(List.unmodifiable(_images));
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

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
    widget.onImagesChanged(List.unmodifiable(_images));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.images,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              '${_images.length}/${widget.maxImages}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacing12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: _images.length + 1, // +1 for the add button
            itemBuilder: (context, index) {
              if (index == 0) {
                // Add Image Button
                return Padding(
                  padding: const EdgeInsets.only(
                    top: AppDimensions.spacing12,
                    right: AppDimensions.spacing12,
                  ),
                  child: InkWell(
                    onTap: _showPickerSourceModal,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outlineVariant,
                          width: 1,
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
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: colorScheme.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              // Display selected image thumbnail
              final imageIndex = index - 1;
              final imageFile = _images[imageIndex];
              return Padding(
                padding: const EdgeInsets.only(
                  top: AppDimensions.spacing12,
                  right: AppDimensions.spacing12,
                ),
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          imageFile,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Görünen daire küçük, dokunma alanı 48dp (UX-14).
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          tooltip: AppLocalizations.of(context)!.delete,
                          onPressed: () => _removeImage(imageIndex),
                          icon: Container(
                            padding: const EdgeInsets.all(
                              AppDimensions.spacing4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.error,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).scaffoldBackgroundColor,
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
            },
          ),
        ),
      ],
    );
  }
}
