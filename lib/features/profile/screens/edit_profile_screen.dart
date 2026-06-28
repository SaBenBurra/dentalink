import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/enums.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/user_avatar.dart';

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

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).value;
    
    _nameController = TextEditingController(text: user?.fullName);
    _bioController = TextEditingController(text: user?.bio);
    _universityController = TextEditingController(text: user?.university);
    _cityController = TextEditingController(text: user?.city);
    _experienceController = TextEditingController(text: user?.experienceYears?.toString() ?? '');
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

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      // Mock save action
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil güncellendi')),
      );
      context.pop();
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
          TextButton(
            onPressed: _saveProfile,
            child: const Text('Kaydet'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Center(
              child: Stack(
                children: [
                  UserAvatar(
                    name: user.fullName,
                    imageUrl: user.avatarUrl,
                    size: AvatarSize.large,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                        onPressed: () {
                          // Mock image picker
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Ad - Soyad *',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Ad Soyad zorunludur' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<UserTitle>(
              value: _selectedTitle,
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: 'Biyografi',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _universityController,
              decoration: const InputDecoration(
                labelText: 'Üniversite',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'Şehir',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _experienceController,
              decoration: const InputDecoration(
                labelText: 'Deneyim Yılı',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _workplaceController,
              decoration: const InputDecoration(
                labelText: 'Çalıştığı Klinik/Hastane',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
