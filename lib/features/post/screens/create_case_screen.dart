import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../data/providers/repository_providers.dart';
import '../../../shared/utils/error_messages.dart';
import '../../../shared/utils/post_actions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/branch_selector.dart';
import '../widgets/image_picker_grid.dart';
import '../widgets/tag_input.dart';
import 'package:dentlink/core/constants/app_dimensions.dart';
import '../../../shared/widgets/unsaved_changes_scope.dart';
import '../../../data/models/enums.dart';
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
  DentalBranch? _selectedBranch;
  List<File> _images = [];
  List<String> _tags = [];
  bool _dirty = false; // UX-2
  bool _privacyConfirmed = false;

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
          SnackBar(content: Text(AppLocalizations.of(context)!.validationBranchRequired)),
        );
        return;
      }

      if (_images.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.caseImageRequired),
          ),
        );
        return;
      }

      if (!_privacyConfirmed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.casePrivacyRequired)),
        );
        return;
      }

      final post = await ref.read(createCaseProvider.notifier).submit(
        title: _titleController.text,
        content: _contentController.text,
        branch: _selectedBranch!,
        imageFiles: _images,
        tags: _tags,
      );

      if (!mounted) return;

      final state = ref.read(createCaseProvider);
      if (state.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(getErrorMessage(AppLocalizations.of(context)!, state.error!))),
        );
      } else {
        invalidateMyPosts(ref);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.caseShared)),
        );
        // Paylaşılan postu aç; form yığından çıkar (geri → önceki ekran).
        context.pushReplacement('/post/${post!.id}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return UnsavedChangesScope(
      dirty: _dirty,
      busy: ref.watch(createCaseProvider).isLoading,
      child: Scaffold(
        appBar: AppBar(
          actionsPadding: EdgeInsets.symmetric(
            horizontal: AppDimensions.spacing10,
          ),
          title: Text(AppLocalizations.of(context)!.createCase),
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
                          AppLocalizations.of(context)!.share,
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
          onChanged: () {
            if (!_dirty) setState(() => _dirty = true);
          },
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.spacing16),
            children: [
              // Başlık
              TextFormField(
                controller: _titleController,
                maxLength: 150, // DB: posts_title_length (017)
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.caseTitleLabel,
                  hintText: AppLocalizations.of(context)!.caseTitleHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.of(context)!.validationTitleEmpty;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppDimensions.spacing20),

              // Açıklama
              TextFormField(
                controller: _contentController,
                maxLength: 5000, // DB: posts_content_length (017)
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.postContent,
                  hintText:
                      AppLocalizations.of(context)!.caseContentHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.of(context)!.validationDescriptionEmpty;
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
                    _dirty = true;
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
                    _dirty = true;
                    _images = List.of(images);
                  });
                },
              ),
              // Hasta mahremiyeti (Faz 4): yüz ve kimlik bilgisi paylaşılmaz.
              CheckboxListTile(
                value: _privacyConfirmed,
                onChanged: (v) => setState(() {
                  _dirty = true;
                  _privacyConfirmed = v ?? false;
                }),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text(AppLocalizations.of(context)!.casePrivacyConfirm),
              ),
              const SizedBox(height: AppDimensions.spacing24),

              // Etiketler
              TagInput(
                suggest: ref.read(createPostRepositoryProvider).suggestTags,
                onTagsChanged: (tags) {
                  setState(() {
                    _dirty = true;
                    _tags = tags;
                  });
                },
              ),
              const SizedBox(height: AppDimensions.spacing32),
            ],
          ),
        ),
      ),
    );
  }
}
