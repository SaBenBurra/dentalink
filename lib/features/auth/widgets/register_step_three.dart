import 'package:dentlink/core/constants/app_colors.dart';
import 'package:dentlink/core/constants/app_dimensions.dart';
import 'package:dentlink/core/constants/app_text_styles.dart';
import 'package:dentlink/shared/widgets/glass_field.dart';
import 'package:flutter/material.dart';

class RegisterStepThree extends StatelessWidget {
  const RegisterStepThree({
    super.key,
    required this.mockAvatars,
    required this.selectedAvatarIndex,
    required this.bioController,
    required this.bioFocusNode,
    required this.onAvatarSelected,
  });
  final List<String> mockAvatars;
  final int selectedAvatarIndex;
  final TextEditingController bioController;
  final FocusNode bioFocusNode;

  final ValueChanged<int> onAvatarSelected;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final textPrimaryColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    final textSecondaryColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

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

          // Avatar picker
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 54,
                  backgroundImage: NetworkImage(
                    mockAvatars[selectedAvatarIndex],
                  ),
                  backgroundColor: const Color(
                    0xFF13B9A5,
                  ).withValues(alpha: 0.2),
                ),
                const SizedBox(height: AppDimensions.spacing16),
                Text(
                  'Bir Avatar Seçin',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textPrimaryColor,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacing12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(mockAvatars.length, (index) {
                    final isSelected = selectedAvatarIndex == index;
                    return InkWell(
                      onTap: () => onAvatarSelected(index),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.spacing6,
                        ),
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF13B9A5)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundImage: NetworkImage(mockAvatars[index]),
                        ),
                      ),
                    );
                  }),
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
            maxLines: 4,
          ),
          const SizedBox(height: AppDimensions.spacing32),
        ],
      ),
    );
  }
}
