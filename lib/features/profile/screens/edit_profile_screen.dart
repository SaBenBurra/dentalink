import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../shared/utils/error_messages.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/enums/enums.dart';
import '../../../providers/auth_provider.dart';
import '../providers/edit_profile_controller.dart';
import '../../../shared/widgets/user_avatar.dart';
import 'package:dentlink/core/constants/app_dimensions.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _universityController;
  late TextEditingController _cityController;
  late TextEditingController _experienceController;
  late TextEditingController _workplaceController;

  UserTitle? _selectedTitle;
  File? _avatarFile;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).value;

    _nameController = TextEditingController(text: user?.fullName);
    _bioController = TextEditingController(text: user?.bio);
    _universityController = TextEditingController(text: user?.university);
    _cityController = TextEditingController(text: user?.city);
    _experienceController = TextEditingController(
      text: user?.experienceYears?.toString() ?? '',
    );
    _workplaceController = TextEditingController(text: user?.workplace);
    _selectedTitle = user?.title;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _universityController.dispose();
    _cityController.dispose();
    _experienceController.dispose();
    _workplaceController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      await ref.read(editProfileProvider.notifier).saveProfile(
            fullName: _nameController.text,
            title: _selectedTitle!,
            bio: _bioController.text,
            university: _universityController.text,
            city: _cityController.text,
            experience: _experienceController.text,
            workplace: _workplaceController.text,
            avatarFile: _avatarFile,
          );

      if (!mounted) return;

      final state = ref.read(editProfileProvider);
      if (state.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(getErrorMessage(state.error!))),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profil güncellendi')));
        context.pop();
      }
    }
  }

  Future<void> _pickAvatar() async {
    final l10n = AppLocalizations.of(context)!;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l10n.pickFromGallery),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(l10n.pickFromCamera),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      // Kayıttaki avatar ile aynı boyut ve kalite.
      final image = await ImagePicker().pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (image != null && mounted) setState(() => _avatarFile = File(image.path));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(getErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profili Düzenle')),
        body: const Center(child: Text('Kullanıcı bilgisi bulunamadı')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profili Düzenle'),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final isLoading = ref.watch(editProfileProvider).isLoading;
              return TextButton(
                onPressed: isLoading ? null : _saveProfile,
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Kaydet'),
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
            // Dokunma alanı avatarın tamamı; kamera yalnızca küçük bir rozet
            // (IconButton'ın 48dp alanı küçük avatarı kapatıyordu).
            Center(
              child: Tooltip(
                message: AppLocalizations.of(context)!.changePhoto,
                child: InkWell(
                  onTap: _pickAvatar,
                  customBorder: const CircleBorder(),
                  child: Stack(
                    children: [
                      if (_avatarFile != null)
                        CircleAvatar(
                          radius: AvatarSize.profile.value / 2,
                          backgroundImage: FileImage(_avatarFile!),
                        )
                      else
                        UserAvatar(
                          name: user.fullName,
                          imageUrl: user.avatarUrl,
                          size: AvatarSize.profile,
                        ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(AppDimensions.spacing6),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.scaffoldBackgroundColor,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.spacing24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Ad - Soyad *',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Ad Soyad zorunludur' : null,
            ),
            const SizedBox(height: AppDimensions.spacing16),
            DropdownButtonFormField<UserTitle>(
              initialValue: _selectedTitle,
              decoration: const InputDecoration(
                labelText: 'Unvan *',
                border: OutlineInputBorder(),
              ),
              items: UserTitle.values.map((title) {
                return DropdownMenuItem(
                  value: title,
                  child: Text(title.displayName),
                );
              }).toList(),
              onChanged: (val) {
                setState(() => _selectedTitle = val);
              },
              validator: (value) => value == null ? 'Unvan zorunludur' : null,
            ),
            const SizedBox(height: AppDimensions.spacing16),
            TextFormField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: 'Biyografi',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: AppDimensions.spacing16),
            TextFormField(
              controller: _universityController,
              decoration: const InputDecoration(
                labelText: 'Üniversite',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppDimensions.spacing16),
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'Şehir',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppDimensions.spacing16),
            TextFormField(
              controller: _experienceController,
              decoration: const InputDecoration(
                labelText: 'Deneyim Yılı',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                final v = value?.trim() ?? '';
                if (v.isEmpty) return null;
                final n = int.tryParse(v);
                return n == null || n < 0 || n > 70
                    ? AppLocalizations.of(context)!.validationExperience
                    : null;
              },
            ),
            const SizedBox(height: AppDimensions.spacing16),
            TextFormField(
              controller: _workplaceController,
              decoration: const InputDecoration(
                labelText: 'Çalıştığı Klinik/Hastane',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppDimensions.spacing32),
          ],
        ),
      ),
    );
  }
}
