import 'package:dentigo/core/l10n/generated/app_localizations.dart';
import '../../../core/utils/media_prepare.dart';
import 'package:flutter/material.dart';
import '../../../data/providers/repository_providers.dart';
import '../../../shared/utils/error_messages.dart';
import '../../../shared/utils/post_actions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/form_section_label.dart';
import '../widgets/image_picker_grid.dart';
import '../widgets/privacy_confirm_tile.dart';
import '../widgets/share_submit.dart';
import '../widgets/tag_input.dart';
import 'package:dentigo/core/constants/app_dimensions.dart';
import '../../../shared/widgets/unsaved_changes_scope.dart';
import '../providers/create_question_controller.dart';

class CreateQuestionScreen extends ConsumerStatefulWidget {
  const CreateQuestionScreen({super.key});

  @override
  ConsumerState<CreateQuestionScreen> createState() =>
      _CreateQuestionScreenState();
}

class _CreateQuestionScreenState extends ConsumerState<CreateQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  List<PickedMedia> _media = [];
  List<String> _tags = [];
  bool _dirty = false; // UX-2
  String? _sharedPostId;
  bool _privacyConfirmed = false;

  bool get _hasMedia => _media.isNotEmpty;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      // Görsel hasta fotoğrafı olabilir: vakadaki onay burada da şart.
      if (_hasMedia && !_privacyConfirmed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.casePrivacyRequired),
          ),
        );
        return;
      }

      final post = await ref
          .read(createQuestionProvider.notifier)
          .submit(
            title: _titleController.text,
            content: _contentController.text,
            media: _media,
            tags: _tags,
          );

      if (!mounted) return;

      final state = ref.read(createQuestionProvider);
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
      SnackBar(content: Text(AppLocalizations.of(context)!.questionShared)),
    );
    // Paylaşılan postu aç; form yığından çıkar (geri → önceki ekran).
    context.go('/feed/post/$_sharedPostId');
  }

  @override
  Widget build(BuildContext context) {
    return UnsavedChangesScope(
      dirty: _dirty,
      busy:
          ref.watch(createQuestionProvider).isLoading || _sharedPostId != null,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.createQuestion),
        ),
        bottomNavigationBar: ShareSubmitBar(
          isLoading: ref.watch(createQuestionProvider).isLoading,
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
                  labelText: AppLocalizations.of(context)!.questionTitleLabel,
                  hintText: AppLocalizations.of(context)!.questionTitleHint,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.of(context)!.validationTitleEmpty;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppDimensions.spacing20),

              // İçerik
              TextFormField(
                controller: _contentController,
                maxLength: 5000, // DB: posts_content_length (017)
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.questionContentLabel,
                  hintText: AppLocalizations.of(context)!.questionContentHint,
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.of(context)!.validationContentEmpty;
                  }
                  return null;
                },
              ),
              const FormSectionDivider(),

              // Görsel ve video (isteğe bağlı, en fazla 4; 046)
              ImagePickerGrid(
                maxImages: 4,
                onChanged: (media) => setState(() {
                  _dirty = true;
                  _media = media;
                }),
              ),
              if (_hasMedia) ...[
                const SizedBox(height: AppDimensions.spacing16),
                PrivacyConfirmTile(
                  value: _privacyConfirmed,
                  onChanged: (v) => setState(() {
                    _dirty = true;
                    _privacyConfirmed = v;
                  }),
                ),
              ],
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
