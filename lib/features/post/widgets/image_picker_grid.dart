import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Eğer svg ihtiyacı olursa diye
import 'package:shimmer/shimmer.dart';

/// Vaka veya Soru oluştururken kullanılacak (Mock) Görsel Seçici Izgara
/// Faz 2'de olduğumuz için galeriye bağlanmaz, sadece mock veri ekler.
class ImagePickerGrid extends StatefulWidget {
  final int maxImages;
  final ValueChanged<List<String>> onImagesChanged;

  const ImagePickerGrid({
    super.key,
    this.maxImages = 10,
    required this.onImagesChanged,
  });

  @override
  State<ImagePickerGrid> createState() => _ImagePickerGridState();
}

class _ImagePickerGridState extends State<ImagePickerGrid> {
  // Mock image list (placeholder string list)
  final List<String> _images = [];

  void _pickMockImage() {
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

    setState(() {
      _images.add('mock_image_${DateTime.now().millisecondsSinceEpoch}.jpg');
    });
    widget.onImagesChanged(_images);
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
    widget.onImagesChanged(_images);
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
        const SizedBox(height: 12),
        SizedBox(
          height: 120, // Yüksekliği biraz daha artırdık
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: _images.length + 1, // +1 for the add button
            itemBuilder: (context, index) {
              if (index == 0) {
                // Add Image Button
                return Padding(
                  padding: const EdgeInsets.only(top: 12, right: 12.0),
                  child: InkWell(
                    onTap: _pickMockImage,
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
                          const SizedBox(height: 8),
                          Text(
                            'Fotoğraf Ekle',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              // Display mock image
              final imageIndex = index - 1;
              return Padding(
                padding: const EdgeInsets.only(top: 12, right: 12.0),
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.image_outlined,
                            color: colorScheme.onSurfaceVariant,
                            size: 40,
                          ),
                        ),
                      ),
                      Positioned(
                        top: -8,
                        right: -8,
                        child: InkWell(
                          onTap: () => _removeImage(imageIndex),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: colorScheme.error,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).scaffoldBackgroundColor,
                                width: 2, // Butonun etrafında beyaz/arka plan renginde bir boşluk güzel görünür
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
