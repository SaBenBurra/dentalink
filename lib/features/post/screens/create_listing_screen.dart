import 'package:dentigo/core/constants/app_dimensions.dart';
import 'package:dentigo/core/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/media_prepare.dart';
import '../../../data/models/enums.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/utils/error_messages.dart';
import '../../../shared/utils/post_actions.dart';
import '../../../shared/widgets/unsaved_changes_scope.dart';
import '../providers/create_listing_controller.dart';
import '../widgets/form_section_label.dart';
import '../widgets/image_picker_grid.dart';
import '../widgets/listing_fields.dart';
import '../widgets/privacy_confirm_tile.dart';
import '../widgets/share_submit.dart';

/// Ticaret ilanı (052): başlık, açıklama, 1–6 fotoğraf, kategori, durum, şehir
/// ve isteğe bağlı fiyat. Yasaklı ürün onayı zorunlu.
class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({super.key});

  @override
  ConsumerState<CreateListingScreen> createState() =>
      _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  static const maxPhotos = 6;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _priceController = TextEditingController();
  // Profildeki şehir hazır gelir, değiştirilebilir.
  late final _cityController = TextEditingController(
    text: ref.read(currentUserProvider)?.city ?? '',
  );
  ListingCategory? _category;
  ItemCondition? _condition;
  List<PickedMedia> _photos = [];
  bool _rulesConfirmed = false;
  bool _dirty = false; // UX-2
  String? _sharedPostId;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _priceController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _snack(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_photos.isEmpty) return _snack(l10n.listingPhotoRequired);
    if (!_rulesConfirmed) return _snack(l10n.listingRulesRequired);

    final post = await ref
        .read(createListingProvider.notifier)
        .submit(
          title: _titleController.text,
          content: _contentController.text,
          images: [for (final p in _photos) p.file],
          category: _category!,
          condition: _condition!,
          city: _cityController.text,
          price: ListingFields.parsePrice(_priceController.text),
        );
    if (!mounted) return;

    final state = ref.read(createListingProvider);
    if (state.hasError) {
      _snack(getErrorMessage(l10n, state.error!));
    } else {
      invalidateMyPosts(ref);
      // Buton başarı animasyonunu oynatır; bitince _openShared.
      setState(() => _sharedPostId = post!.id);
    }
  }

  void _openShared() {
    _snack(AppLocalizations.of(context)!.listingShared);
    context.go('/feed/post/$_sharedPostId');
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLoading = ref.watch(createListingProvider).isLoading;

    return UnsavedChangesScope(
      dirty: _dirty,
      busy: isLoading || _sharedPostId != null,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.createListing)),
        bottomNavigationBar: ShareSubmitBar(
          isLoading: isLoading,
          onPressed: _submit,
          shared: _sharedPostId != null,
          onSharedAnimationEnd: _openShared,
        ),
        body: Form(
          key: _formKey,
          onChanged: _markDirty,
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.spacing16),
            children: [
              ImagePickerGrid(
                maxImages: maxPhotos,
                allowVideo: false,
                onChanged: (photos) => setState(() {
                  _dirty = true;
                  _photos = photos;
                }),
              ),
              const FormSectionDivider(),
              FormSectionLabel(
                icon: Icons.edit_note,
                label: l10n.postSectionContent,
              ),
              const SizedBox(height: AppDimensions.spacing12),
              TextFormField(
                controller: _titleController,
                maxLength: 150, // DB: posts_title_length (017)
                decoration: InputDecoration(
                  labelText: l10n.postTitle,
                  hintText: l10n.listingTitleHint,
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? l10n.validationTitleEmpty
                    : null,
              ),
              const SizedBox(height: AppDimensions.spacing16),
              TextFormField(
                controller: _contentController,
                maxLength: 5000, // DB: posts_content_length (017)
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: l10n.postContent,
                  hintText: l10n.listingContentHint,
                  alignLabelWithHint: true,
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? l10n.validationContentEmpty
                    : null,
              ),
              const FormSectionDivider(),
              ListingFields(
                category: _category,
                condition: _condition,
                priceController: _priceController,
                cityController: _cityController,
                onCategoryChanged: (c) => setState(() => _category = c),
                onConditionChanged: (c) => setState(() => _condition = c),
              ),
              const SizedBox(height: AppDimensions.spacing16),
              PrivacyConfirmTile(
                value: _rulesConfirmed,
                label: l10n.listingRulesConfirm,
                onChanged: (v) => setState(() {
                  _dirty = true;
                  _rulesConfirmed = v;
                }),
              ),
              const SizedBox(height: AppDimensions.spacing12),
              Text(
                l10n.listingDisclaimer,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppDimensions.spacing32),
            ],
          ),
        ),
      ),
    );
  }
}
