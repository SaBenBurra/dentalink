import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../../shared/utils/error_messages.dart';
import '../../../shared/utils/post_actions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/tag_input.dart';
import 'package:dentlink/core/constants/app_dimensions.dart';
import '../../../shared/widgets/unsaved_changes_scope.dart';
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
  List<String> _tags = [];
  bool _dirty = false; // UX-2

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final post = await ref.read(createQuestionProvider.notifier).submit(
        title: _titleController.text,
        content: _contentController.text,
        tags: _tags,
      );

      if (!mounted) return;

      final state = ref.read(createQuestionProvider);
      if (state.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(getErrorMessage(AppLocalizations.of(context)!, state.error!))),
        );
      } else {
        invalidateMyPosts(ref);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.questionShared)),
        );
        // Paylaşılan postu aç; form yığından çıkar (geri → önceki ekran).
        context.pushReplacement('/feed/question/${post!.id}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return UnsavedChangesScope(
      dirty: _dirty,
      busy: ref.watch(createQuestionProvider).isLoading,
      child: Scaffold(
        appBar: AppBar(
          actionsPadding: EdgeInsets.symmetric(
            horizontal: AppDimensions.spacing10,
          ),
          title: Text(AppLocalizations.of(context)!.createQuestion),
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
                  labelText: AppLocalizations.of(context)!.questionTitleLabel,
                  hintText: AppLocalizations.of(context)!.questionTitleHint,
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

              // İçerik
              TextFormField(
                controller: _contentController,
                maxLength: 5000, // DB: posts_content_length (017)
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.questionContentLabel,
                  hintText:
                      AppLocalizations.of(context)!.questionContentHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.of(context)!.validationContentEmpty;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppDimensions.spacing24),

              // Etiketler
              TagInput(
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
