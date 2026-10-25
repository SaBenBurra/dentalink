import 'dart:io';
import 'package:dentlink/core/constants/app_colors.dart';
import 'package:dentlink/core/constants/app_dimensions.dart';
import 'package:dentlink/core/constants/app_text_styles.dart';
import 'package:dentlink/shared/widgets/glass_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dentlink/core/constants/profile_limits.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dentlink/shared/utils/error_messages.dart';

/// Kayıt Step 3 — Profil Detayları.
///
/// Avatar seçimi: Fotoğraf çekme, galeriden seçme, veya varsayılan avatarlar.
/// Biyografi alanı.
class RegisterStepThree extends StatelessWidget {
  const RegisterStepThree({
    super.key,
    required this.selectedImageFile,
    required this.bioController,
    required this.bioFocusNode,
    required this.onImageFilePicked,
  });

  final File? selectedImageFile;
  final TextEditingController bioController;
  final FocusNode bioFocusNode;
  final ValueChanged<File?> onImageFilePicked;

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final image = await ImagePicker().pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (image != null) onImageFilePicked(File(image.path));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(getErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textPrimaryColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    final textSecondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final glassBgColor = isDark
        ? Colors.black.withValues(alpha: 0.3)
        : Colors.white.withValues(alpha: 0.5);
    final glassBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.white.withValues(alpha: 0.6);

    final hasCustomImage = selectedImageFile != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppDimensions.spacing12),
          Text(
            'Profil Detayları',
            style: AppTextStyles.headlineSmall.copyWith(
              color: textPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.spacing8),
          Text(
            'Profil fotoğrafınızı seçin ve kısa bir biyografi ekleyin (İsteğe bağlı).',
            style: AppTextStyles.bodyMedium.copyWith(color: textSecondaryColor),
          ),
          const SizedBox(height: AppDimensions.spacing24),

          // ── Ana Avatar Gösterimi ──────────────────────────────────────
          Center(
            child: Column(
              children: [
                // Büyük avatar preview
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 54,
                      backgroundColor: const Color(
                        0xFF13B9A5,
                      ).withValues(alpha: 0.2),
                      backgroundImage:
                          hasCustomImage ? FileImage(selectedImageFile!) : null,
                      child: hasCustomImage
                          ? null
                          : Icon(
                              Icons.person_rounded,
                              size: 54,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                    ),
                    // Düzenleme ikonu
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF13B9A5),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF11211F) : Colors.white,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppDimensions.spacing16),

                // ── Fotoğraf Çek / Galeriden Seç Butonları ──────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ActionButton(
                      icon: Icons.camera_alt_outlined,
                      label: 'Fotoğraf Çek',
                      onTap: () => _pickImage(context, ImageSource.camera),
                      isDark: isDark,
                      glassBgColor: glassBgColor,
                      glassBorderColor: glassBorderColor,
                      textColor: textPrimaryColor,
                    ),
                    const SizedBox(width: AppDimensions.spacing12),
                    _ActionButton(
                      icon: Icons.photo_library_outlined,
                      label: 'Galeriden Seç',
                      onTap: () => _pickImage(context, ImageSource.gallery),
                      isDark: isDark,
                      glassBgColor: glassBgColor,
                      glassBorderColor: glassBorderColor,
                      textColor: textPrimaryColor,
                    ),
                  ],
                ),

                const SizedBox(height: AppDimensions.spacing16),

                // Seçilen fotoğrafı kaldır butonu
                if (hasCustomImage)
                  TextButton.icon(
                    onPressed: () => onImageFilePicked(null),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Fotoğrafı Kaldır'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      textStyle: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.spacing32),

          // Bio Multi-line input
          GlassField(
            controller: bioController,
            focusNode: bioFocusNode,
            hintText: 'Biyografi (Kendinizden kısaca bahsedin)',
            icon: Icons.description_outlined,
            inputFormatters: [LengthLimitingTextInputFormatter(ProfileLimits.bio)],
            maxLines: 4,
          ),
          const SizedBox(height: AppDimensions.spacing32),
        ],
      ),
    );
  }
}

/// Fotoğraf Çek / Galeriden Seç eylem butonu.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    required this.glassBgColor,
    required this.glassBorderColor,
    required this.textColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final Color glassBgColor;
  final Color glassBorderColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacing16,
          vertical: AppDimensions.spacing12,
        ),
        decoration: BoxDecoration(
          color: glassBgColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(color: glassBorderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: const Color(0xFF13B9A5),
            ),
            const SizedBox(width: AppDimensions.spacing8),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
