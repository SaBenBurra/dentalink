import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/branch_selector.dart';
import '../widgets/image_picker_grid.dart';
import '../widgets/tag_input.dart';

class CreateCaseScreen extends StatefulWidget {
  const CreateCaseScreen({super.key});

  @override
  State<CreateCaseScreen> createState() => _CreateCaseScreenState();
}

class _CreateCaseScreenState extends State<CreateCaseScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedBranch;
  List<String> _images = [];
  List<String> _tags = [];

  void _submit() {
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

      // TODO: Faz 3'te backend'e gönderilecek
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vaka başarıyla paylaşıldı (Mock)')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        actionsPadding: EdgeInsets.symmetric(horizontal: 10),
        title: const Text('Vaka Paylaş'),
        actions: [
          TextButton(
            onPressed: _submit,
            child: Text(
              'Paylaş',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Başlık
            TextFormField(
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
            const SizedBox(height: 20),

            // Açıklama
            TextFormField(
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
            const SizedBox(height: 24),

            // Branş Seçimi
            BranchSelector(
              selectedBranch: _selectedBranch,
              onBranchSelected: (branch) {
                setState(() {
                  _selectedBranch = branch;
                });
              },
            ),
            const SizedBox(height: 24),

            // Görseller
            ImagePickerGrid(
              maxImages: 10,
              onImagesChanged: (images) {
                setState(() {
                  _images = images;
                });
              },
            ),
            const SizedBox(height: 24),

            // Etiketler
            TagInput(
              onTagsChanged: (tags) {
                setState(() {
                  _tags = tags;
                });
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
