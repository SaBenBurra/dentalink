import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/branch_selector.dart';
import '../widgets/image_picker_grid.dart';
import '../widgets/tag_input.dart';
import 'package:dentlink/core/constants/app_dimensions.dart';
import '../providers/create_case_controller.dart';

class CreateCaseScreen extends ConsumerStatefulWidget {
  const CreateCaseScreen({super.key});

  @override
  ConsumerState<CreateCaseScreen> createState() => _CreateCaseScreenState();
}

class _CreateCaseScreenState extends ConsumerState<CreateCaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String? _selectedBranch;
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
      if (_selectedBranch == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen bir branş seçin.')),
        );
        return;
      }

      if (_images.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vaka için en az bir görsel eklemelisiniz.'),
          ),
        );
        return;
      }

      await ref.read(createCaseProvider.notifier).submit(
        title: _titleController.text,
        content: _contentController.text,
        branch: _selectedBranch!,
        imageUrls: _images,
        tags: _tags,
      );

      if (!mounted) return;

      final state = ref.read(createCaseProvider);
      if (state.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${state.error}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vaka başarıyla paylaşıldı (Mock)')),
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
        title: const Text('Vaka Paylaş'),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final isLoading = ref.watch(createCaseProvider).isLoading;
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
                labelText: 'Vaka Başlığı',
                hintText: 'Örn: Mandibular 1. Molar Endodontik Tedavi',
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

            // Açıklama
            TextFormField(
              controller: _contentController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Açıklama',
                hintText:
                    'Vakanın hikayesi, teşhis, tedavi planı ve uygulanan işlemler...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Açıklama boş bırakılamaz';
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.spacing24),

            // Branş Seçimi
            BranchSelector(
              selectedBranch: _selectedBranch,
              onBranchSelected: (branch) {
                setState(() {
                  _selectedBranch = branch;
                });
              },
            ),
            const SizedBox(height: AppDimensions.spacing24),

            // Görseller
            ImagePickerGrid(
              maxImages: 10,
              onImagesChanged: (images) {
                setState(() {
                  _images = images;
                });
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
            const SizedBox(height: AppDimensions.spacing32),
          ],
        ),
      ),
    );
  }
}
