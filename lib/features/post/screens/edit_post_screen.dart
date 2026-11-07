import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../data/models/post_model.dart';
import '../../../data/providers/repository_providers.dart';
import '../../../core/error/app_failures.dart';
import '../../../data/models/case_treatment.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/feed_provider.dart';
import '../../../providers/post_provider.dart';
import '../../../shared/utils/error_messages.dart';
import '../widgets/form_section_label.dart';
import '../widgets/treatments_field.dart';
import '../widgets/media_reorder_strip.dart';
import '../widgets/detail/detail_states.dart';
import '../widgets/tag_input.dart';
import '../../../shared/widgets/unsaved_changes_scope.dart';

/// Başlık, içerik, tedaviler (vaka), etiket ve medya sırası düzenleme.
/// Medya eklenmez/silinmez, yalnızca sıralanır (046).
class EditPostScreen extends ConsumerWidget {
  final String postId;

  const EditPostScreen({super.key, required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(postDetailProvider(postId))
        .when(
          data: (post) => _EditPostForm(post: post),
          loading: () => const PostDetailLoading(),
          error: (e, _) => PostDetailError(
            message: getErrorMessage(AppLocalizations.of(context)!, e),
            onRetry: () => ref.invalidate(postDetailProvider(postId)),
          ),
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
  late final _contentController = TextEditingController(
    text: widget.post.content,
  );
  // Tedavi etiketleri ayrı alanda; etiket alanında yalnızca serbest etiketler.
  late List<String> _tags = [
    for (final t in switch (widget.post) {
      CasePostModel p => p.freeTags,
      final p => p.tags,
    })
      t.name,
  ];
  late List<CaseTreatment> _treatments = switch (widget.post) {
    CasePostModel(:final treatments) => treatments,
    _ => const [],
  };
  late final List<PostMediaItem> _media = [...widget.post.media];
  bool _mediaReordered = false;
  bool _saving = false;
  bool _dirty = false; // UX-2

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
      final updated = await ref
          .read(createPostRepositoryProvider)
          .updatePost(
            postId: widget.post.id,
            title: _titleController.text,
            content: _contentController.text,
            treatments: _treatments,
            tags: _tags,
            mediaOrder: _mediaReordered ? [for (final m in _media) m.id] : null,
          );
      ref.read(feedProvider.notifier).replacePost(updated);
      if (ref.exists(userPostsProvider(updated.userId))) {
        ref
            .read(userPostsProvider(updated.userId).notifier)
            .patchPost(updated.id, (_) => updated);
      }
      ref.invalidate(postDetailProvider(updated.id));
      messenger.showSnackBar(SnackBar(content: Text(l10n.postUpdated)));
      if (mounted) context.pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(getErrorMessage(l10n, e))));
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
      return PostDetailError(
        message: getErrorMessage(l10n, const NotFoundFailure()),
      );
    }

    return UnsavedChangesScope(
      dirty: _dirty,
      busy: _saving,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.editPost),
          actions: [
            TextButton(
              onPressed: _saving || (isCase && _treatments.isEmpty)
                  ? null
                  : _save,
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
              TextFormField(
                controller: _titleController,
                maxLength: _titleMax,
                decoration: InputDecoration(labelText: l10n.postTitle),
                validator: _required,
              ),
              const SizedBox(height: AppDimensions.spacing16),
              TextFormField(
                controller: _contentController,
                maxLength: _contentMax,
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: l10n.postContent,
                  alignLabelWithHint: true,
                ),
                validator: _required,
              ),
              if (isCase) ...[
                const FormSectionDivider(),
                TreatmentsField(
                  treatments: _treatments,
                  search: (q) => ref
                      .read(searchRepositoryProvider)
                      .listTreatments(query: q, limit: 10),
                  onChanged: (t) => setState(() {
                    _treatments = t;
                    _dirty = true;
                  }),
                ),
              ],
              if (_media.length > 1) ...[
                const FormSectionDivider(),
                FormSectionLabel(
                  icon: Icons.photo_library_outlined,
                  label: l10n.mediaOrder,
                ),
                const SizedBox(height: AppDimensions.spacing12),
                MediaReorderStrip(
                  onReorder: (oldIndex, newIndex) => setState(() {
                    _media.insert(newIndex, _media.removeAt(oldIndex));
                    _mediaReordered = true;
                    _dirty = true;
                  }),
                  children: [
                    for (final m in _media)
                      MediaTile(
                        key: ValueKey(m.id),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: m.url,
                              // İmzalı URL her çekişte değişir; önbellek dosya yoluna bağlı (SEC-9).
                              cacheKey: Uri.parse(m.url).path,
                              fit: BoxFit.cover,
                            ),
                            if (m.videoUrl != null)
                              const Icon(
                                Icons.play_circle_outline,
                                color: Colors.white,
                                size: 32,
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
              const FormSectionDivider(),
              TagInput(
                suggest: ref.read(createPostRepositoryProvider).suggestTags,
                initialTags: _tags,
                onTagsChanged: (tags) => setState(() {
                  _tags = tags;
                  _dirty = true;
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
