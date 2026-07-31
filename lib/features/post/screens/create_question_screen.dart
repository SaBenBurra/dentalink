import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/image_picker_grid.dart';
import '../widgets/tag_input.dart';
import 'package:dentlink/core/constants/app_dimensions.dart';
import '../providers/create_question_controller.dart';

class CreateQuestionScreen extends ConsumerStatefulWidget {
  const CreateQuestionScreen({super.key});

  @override
  ConsumerState<CreateQuestionScreen> createState() => _CreateQuestionScreenState();
}

class _CreateQuestionScreenState extends ConsumerState<CreateQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  List<String> _images = [];
  List<String> _tags = [];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      await ref.read(createQuestionProvider.notifier).submit(
        title: _titleController.text,
        content: _contentController.text,
        imageUrls: _images,
        tags: _tags,
      );

      if (!mounted) return;

      final state = ref.read(createQuestionProvider);
      if (state.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${state.error}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sorunuz başarıyla paylaşıldı (Mock)')),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        actionsPadding: EdgeInsets.symmetric(
          horizontal: AppDimensions.spacing10,
        ),
        title: const Text('Soru Sor'),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final isLoading = ref.watch(createQuestionProvider).isLoading;
              return TextButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Paylaş',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
              );
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.spacing16),
          children: [
            // Başlık
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Soru Başlığı',
                hintText: 'Örn: Zirkonyum kaplama sonrası hassasiyet',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Başlık boş bırakılamaz';
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.spacing20),

            // İçerik
            TextFormField(
              controller: _contentController,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Sorunun Detayları',
                hintText:
                    'Karşılaştığınız problemi veya merak ettiğiniz konuyu detaylıca açıklayın...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'İçerik boş bırakılamaz';
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.spacing24),

            // Etiketler
            TagInput(
              onTagsChanged: (tags) {
                setState(() {
                  _tags = tags;
                });
              },
            ),
            const SizedBox(height: AppDimensions.spacing24),

            // Görseller (Opsiyonel)
            ImagePickerGrid(
              maxImages: 4, // Soru için daha az görsel yeterli olabilir
              onImagesChanged: (images) {
                setState(() {
                  _images = images;
                });
              },
            ),
            const SizedBox(height: AppDimensions.spacing32),
          ],
        ),
      ),
    );
  }
}
