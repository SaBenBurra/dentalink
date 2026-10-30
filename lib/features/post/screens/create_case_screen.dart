import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../data/providers/repository_providers.dart';
import '../../../shared/utils/error_messages.dart';
import '../../../shared/utils/post_actions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/form_section_label.dart';
import '../widgets/share_submit.dart';
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
  String? _sharedPostId;
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
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.validationBranchRequired,
            ),
          ),
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
          SnackBar(
            content: Text(AppLocalizations.of(context)!.casePrivacyRequired),
          ),
        );
        return;
      }

      final post = await ref
          .read(createCaseProvider.notifier)
          .submit(
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
          SnackBar(
            content: Text(
              getErrorMessage(AppLocalizations.of(context)!, state.error!),
            ),
          ),
        );
      } else {
        invalidateMyPosts(ref);
        // Buton başarı animasyonunu oynatır; bitince _openShared.
        setState(() => _sharedPostId = post!.id);
      }
    }
  }

  void _openShared() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.caseShared)),
    );
    // Paylaşılan postu aç; form yığından çıkar (geri → önceki ekran).
    context.pushReplacement('/post/$_sharedPostId');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return UnsavedChangesScope(
      dirty: _dirty,
      busy: ref.watch(createCaseProvider).isLoading || _sharedPostId != null,
      child: Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.createCase)),
        bottomNavigationBar: ShareSubmitBar(
          isLoading: ref.watch(createCaseProvider).isLoading,
          onPressed: _submit,
          shared: _sharedPostId != null,
          onSharedAnimationEnd: _openShared,
        ),
        body: Form(
          key: _formKey,
          onChanged: () {
            if (!_dirty) setState(() => _dirty = true);
          },
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.spacing16),
            children: [
              FormSectionLabel(
                icon: Icons.edit_note,
                label: AppLocalizations.of(context)!.postSectionContent,
              ),
              const SizedBox(height: AppDimensions.spacing12),
              // Başlık
              TextFormField(
                controller: _titleController,
                maxLength: 150, // DB: posts_title_length (017)
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.caseTitleLabel,
                  hintText: AppLocalizations.of(context)!.caseTitleHint,
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
                  hintText: AppLocalizations.of(context)!.caseContentHint,
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.of(
                      context,
                    )!.validationDescriptionEmpty;
                  }
                  return null;
                },
              ),
              const FormSectionDivider(),

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
              const FormSectionDivider(),

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
              const SizedBox(height: AppDimensions.spacing16),
              // Hasta mahremiyeti (Faz 4): yüz ve kimlik bilgisi paylaşılmaz.
              CheckboxListTile(
                tileColor:
                    (_privacyConfirmed
                            ? colorScheme.primary
                            : colorScheme.tertiary)
                        .withValues(alpha: 0.08),
                value: _privacyConfirmed,
                onChanged: (v) => setState(() {
                  _dirty = true;
                  _privacyConfirmed = v ?? false;
                }),
                controlAffinity: ListTileControlAffinity.leading,
                secondary: Icon(
                  Icons.shield_outlined,
                  color: _privacyConfirmed
                      ? colorScheme.primary
                      : colorScheme.tertiary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusMedium,
                  ),
                ),
                title: Text(
                  AppLocalizations.of(context)!.casePrivacyConfirm,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const FormSectionDivider(),

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
