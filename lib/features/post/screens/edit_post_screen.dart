import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../data/models/post_model.dart';
import '../../../data/providers/repository_providers.dart';
import '../../../core/error/app_failures.dart';
import '../../../domain/enums/enums.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/feed_provider.dart';
import '../../../providers/post_provider.dart';
import '../../../shared/utils/error_messages.dart';
import '../widgets/branch_selector.dart';
import '../widgets/detail/detail_states.dart';
import '../widgets/tag_input.dart';

/// Başlık, içerik, branş (vaka) ve etiket düzenleme. Görseller düzenlenmez.
class EditPostScreen extends ConsumerWidget {
  final String postId;

  const EditPostScreen({super.key, required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(postDetailProvider(postId)).when(
          data: (post) => _EditPostForm(post: post),
          loading: () => const PostDetailLoading(),
          error: (e, _) => PostDetailError(message: getErrorMessage(e)),
        );
  }
}

class _EditPostForm extends ConsumerStatefulWidget {
  final PostModel post;

  const _EditPostForm({required this.post});

  @override
  ConsumerState<_EditPostForm> createState() => _EditPostFormState();
}

class _EditPostFormState extends ConsumerState<_EditPostForm> {
  // UX-8 limitleri.
  static const _titleMax = 150;
  static const _contentMax = 5000;

  final _formKey = GlobalKey<FormState>();
  late final _titleController = TextEditingController(text: widget.post.title);
  late final _contentController =
      TextEditingController(text: widget.post.content);
  late List<String> _tags = [for (final t in widget.post.tags) t.name];
  late DentalBranch? _branch = switch (widget.post) {
    CasePostModel(:final branch) => branch,
    _ => null,
  };
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final updated = await ref.read(createPostRepositoryProvider).updatePost(
            postId: widget.post.id,
            title: _titleController.text,
            content: _contentController.text,
            branch: _branch,
            tags: _tags,
          );
      ref.read(feedProvider.notifier).replacePost(updated);
      ref.invalidate(userPostsProvider(updated.userId));
      ref.invalidate(postDetailProvider(updated.id));
      messenger.showSnackBar(SnackBar(content: Text(l10n.postUpdated)));
      if (mounted) context.pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(getErrorMessage(e))));
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? value) => value == null || value.trim().isEmpty
      ? AppLocalizations.of(context)!.validationRequired
      : null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isCase = widget.post is CasePostModel;
    // Yalnızca sahibi düzenleyebilir (RPC de kontrol eder).
    final isOwner = ref.watch(currentUserProvider)?.id == widget.post.userId;
    if (!isOwner) {
      return PostDetailError(message: getErrorMessage(const NotFoundFailure()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editPost),
        actions: [
          TextButton(
            onPressed: _saving || (isCase && _branch == null) ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.save),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.spacing16),
          children: [
            TextFormField(
              controller: _titleController,
              maxLength: _titleMax,
              decoration: InputDecoration(
                labelText: l10n.postTitle,
                border: const OutlineInputBorder(),
              ),
              validator: _required,
            ),
            const SizedBox(height: AppDimensions.spacing16),
            TextFormField(
              controller: _contentController,
              maxLength: _contentMax,
              maxLines: 8,
              decoration: InputDecoration(
                labelText: l10n.postContent,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: _required,
            ),
            if (isCase) ...[
              const SizedBox(height: AppDimensions.spacing24),
              BranchSelector(
                selectedBranch: _branch,
                onBranchSelected: (b) => setState(() => _branch = b),
              ),
            ],
            const SizedBox(height: AppDimensions.spacing24),
            TagInput(
              initialTags: _tags,
              onTagsChanged: (tags) => setState(() => _tags = tags),
            ),
          ],
        ),
      ),
    );
  }
}
