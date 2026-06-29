import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/image_picker_grid.dart';
import '../widgets/tag_input.dart';
import 'package:dentlink/core/constants/app_dimensions.dart';

class CreateQuestionScreen extends StatefulWidget {
  const CreateQuestionScreen({super.key});

  @override
  State<CreateQuestionScreen> createState() => _CreateQuestionScreenState();
}

class _CreateQuestionScreenState extends State<CreateQuestionScreen> {
  final _formKey = GlobalKey<FormState>();

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Soru için görsel veya branş zorunlu değil.

      // TODO: Faz 3'te backend'e gönderilecek
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sorunuz başarıyla paylaşıldı (Mock)')),
      );
      context.pop();
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
          padding: const EdgeInsets.all(AppDimensions.spacing16),
          children: [
            // Başlık
            TextFormField(
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
                setState(() {});
              },
            ),
            const SizedBox(height: AppDimensions.spacing24),

            // Görseller (Opsiyonel)
            ImagePickerGrid(
              maxImages: 4, // Soru için daha az görsel yeterli olabilir
              onImagesChanged: (images) {
                setState(() {});
              },
            ),
            const SizedBox(height: AppDimensions.spacing32),
          ],
        ),
      ),
    );
  }
}
