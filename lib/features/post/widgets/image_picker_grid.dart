import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dentlink/core/constants/app_dimensions.dart';

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
            'En fazla ${widget.maxImages} görsel ekleyebilirsiniz.',
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
                title: const Text('Galeriden Seç'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImages(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Kameradan Çek'),
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
    if (source == ImageSource.camera) {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (pickedFile != null) {
        setState(() {
          _images.add(File(pickedFile.path));
        });
        widget.onImagesChanged(List.unmodifiable(_images));
      }
    } else {
      final pickedFiles = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (pickedFiles.isEmpty) return;

      final remaining = widget.maxImages - _images.length;
      final toAdd =
          pickedFiles.take(remaining).map((xf) => File(xf.path)).toList();

      setState(() {
        _images.addAll(toAdd);
      });
      widget.onImagesChanged(List.unmodifiable(_images));
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
              'Görseller',
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
                            'Fotoğraf Ekle',
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
                      Positioned(
                        top: -8,
                        right: -8,
                        child: InkWell(
                          onTap: () => _removeImage(imageIndex),
                          child: Container(
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
