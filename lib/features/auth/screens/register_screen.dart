import 'dart:ui';
import 'package:dentlink/features/auth/widgets/register_dialog.dart';
import 'package:dentlink/shared/widgets/glass_background_effect.dart';
import 'package:dentlink/shared/widgets/glass_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../data/models/enums.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 3;

  // Form Controllers
  final _nameController = TextEditingController();
  final _uniController = TextEditingController();
  final _cityController = TextEditingController();
  final _clinicController = TextEditingController();
  final _expController = TextEditingController();
  final _bioController = TextEditingController();

  final _nameFocusNode = FocusNode();
  final _uniFocusNode = FocusNode();
  final _cityFocusNode = FocusNode();
  final _clinicFocusNode = FocusNode();
  final _expFocusNode = FocusNode();
  final _bioFocusNode = FocusNode();

  UserTitle? _selectedTitle;
  int _selectedAvatarIndex = 0;
  bool _isCompleting = false;

  // Validation state
  String? _nameError;

  // Mock avatars
  final List<String> _mockAvatars = [
    'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=150&h=150&fit=crop&crop=face', // Dentist 1
    'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=150&h=150&fit=crop&crop=face', // Dentist 2
    'https://images.unsplash.com/photo-1594824813573-246434de83fb?w=150&h=150&fit=crop&crop=face', // Dentist 3
    'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=150&h=150&fit=crop&crop=face', // Dentist 4
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _uniController.dispose();
    _cityController.dispose();
    _clinicController.dispose();
    _expController.dispose();
    _bioController.dispose();

    _nameFocusNode.dispose();
    _uniFocusNode.dispose();
    _cityFocusNode.dispose();
    _clinicFocusNode.dispose();
    _expFocusNode.dispose();
    _bioFocusNode.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // Validate Step 1
      setState(() {
        _nameError = _nameController.text.trim().isEmpty
            ? 'Ad Soyad alanı zorunludur'
            : null;
      });

      if (_nameError != null) return;
      if (_selectedTitle == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lütfen bir unvan seçin'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeRegistration();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/login');
    }
  }

  void _completeRegistration() {
    setState(() {
      _isCompleting = true;
    });

    // Simulate completion delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _isCompleting = false;
      });

      // Show success modal or direct redirect
      showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'Success',
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (context, anim1, anim2) {
          return const SizedBox.shrink();
        },
        transitionBuilder: (context, anim1, anim2, child) {
          final scale = Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.elasticOut));
          return RegisterDialog(scale: scale);
        },
      );

      // Transition to Feed after success dialog
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          // Pop dialog
          Navigator.of(context, rootNavigator: true).pop();
          // Go to Feed
          context.go('/feed');
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF11211F)
        : AppColors.bgGradientStart;
    final textPrimaryColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // 1. Background Gradients and Decorative Blurred Circles
          if (!isDark)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.bgGradientStart,
                      AppColors.bgGradientEnd,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),

          GlassBackgroundEffect(left: -120, top: -120, width: 320, height: 320),
          GlassBackgroundEffect(
            right: -120,
            bottom: -120,
            width: 380,
            height: 380,
          ),
          // 2. Main Page Layout
          SafeArea(
            child: Column(
              children: [
                // Top Custom Header with Progress Bar
                _buildHeader(isDark, textPrimaryColor),

                // Multi-step Wizard PageView
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (int page) {
                      setState(() {
                        _currentStep = page;
                      });
                    },
                    children: [
                      _buildStep1(isDark, textPrimaryColor),
                      _buildStep2(isDark, textPrimaryColor),
                      _buildStep3(isDark, textPrimaryColor),
                    ],
                  ),
                ),

                // Bottom Action Buttons
                _buildBottomActions(isDark),
              ],
            ),
          ),

          // Completion Loading overlay
          if (_isCompleting)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusMedium,
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.spacing32,
                          vertical: AppDimensions.spacing24,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.6)
                              : Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMedium,
                          ),
                          border: Border.all(
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF13B9A5),
                              ),
                            ),
                            const SizedBox(height: AppDimensions.spacing16),
                            Text(
                              'Profil oluşturuluyor...',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: textPrimaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color textPrimaryColor) {
    final progress = (_currentStep + 1) / _totalSteps;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacing24,
        vertical: AppDimensions.spacing16,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: textPrimaryColor,
                  size: 20,
                ),
                onPressed: _prevStep,
              ),
              Text(
                'Kayıt Ol',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textPrimaryColor,
                ),
              ),
              Opacity(
                opacity: _currentStep > 0 ? 1.0 : 0.0,
                child: TextButton(
                  onPressed: _currentStep > 0 ? _nextStep : null,
                  child: const Text(
                    'Geç',
                    style: TextStyle(
                      color: Color(0xFF13B9A5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing16),
          // Progress bar
          Stack(
            children: [
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 6,
                width: MediaQuery.of(context).size.width * progress - 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF13B9A5), Color(0xFF3B82F6)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF13B9A5).withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getStepTitle(),
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Adım ${_currentStep + 1} / $_totalSteps',
                style: AppTextStyles.bodySmall.copyWith(
                  color: const Color(0xFF13B9A5),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Temel Bilgiler';
      case 1:
        return 'Mesleki Bilgiler';
      case 2:
        return 'Profil Detayları';
      default:
        return '';
    }
  }

  // STEP 1: Basic Info & Title selection
  Widget _buildStep1(bool isDark, Color textPrimaryColor) {
    final textSecondaryColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final glassBgColor = isDark
        ? Colors.black.withValues(alpha: 0.3)
        : Colors.white.withValues(alpha: 0.5);
    final glassBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.white.withValues(alpha: 0.6);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppDimensions.spacing12),
          Text(
            'Sizi Tanıyalım',
            style: AppTextStyles.headlineSmall.copyWith(
              color: textPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.spacing8),
          Text(
            'Lütfen adınızı girin ve uzmanlık alanınızı seçin.',
            style: AppTextStyles.bodyMedium.copyWith(color: textSecondaryColor),
          ),
          const SizedBox(height: AppDimensions.spacing24),

          // Name field
          GlassField(
            controller: _nameController,
            focusNode: _nameFocusNode,
            hintText: 'Ad Soyad',
            icon: Icons.person_outline_rounded,
            errorText: _nameError,
            onChanged: (val) {
              if (_nameError != null && val.trim().isNotEmpty) {
                setState(() {
                  _nameError = null;
                });
              }
            },
          ),

          const SizedBox(height: AppDimensions.spacing32),
          Text(
            'Unvanınız',
            style: AppTextStyles.titleMedium.copyWith(
              color: textPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.spacing12),

          // Grid of Titles
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 3,
            ),
            itemCount: UserTitle.values.length,
            itemBuilder: (context, index) {
              final title = UserTitle.values[index];
              final isSelected = _selectedTitle == title;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedTitle = title;
                  });
                },
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacing12,
                    vertical: AppDimensions.spacing8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark
                              ? const Color(0xFF13B9A5).withValues(alpha: 0.15)
                              : const Color(0xFF13B9A5).withValues(alpha: 0.08))
                        : glassBgColor,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusMedium,
                    ),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF13B9A5)
                          : glassBorderColor,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(
                                0xFF13B9A5,
                              ).withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          title.titleIcon,
                          size: 16,
                          color: isSelected
                              ? const Color(0xFF13B9A5)
                              : (isDark ? Colors.white60 : Colors.black54),
                        ),
                        const SizedBox(width: AppDimensions.spacing8),
                        Expanded(
                          child: Text(
                            title.displayName,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? const Color(0xFF13B9A5)
                                  : textPrimaryColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppDimensions.spacing32),
        ],
      ),
    );
  }

  // STEP 2: Professional Details (Optional)
  Widget _buildStep2(bool isDark, Color textPrimaryColor) {
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
            'Mesleki Bilgiler',
            style: AppTextStyles.headlineSmall.copyWith(
              color: textPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.spacing8),
          Text(
            'Profesyonel geçmişinizi doldurarak diş hekimleri ağı ile daha iyi etkileşim kurun (İsteğe bağlı).',
            style: AppTextStyles.bodyMedium.copyWith(color: textSecondaryColor),
          ),
          const SizedBox(height: AppDimensions.spacing24),

          // University
          GlassField(
            controller: _uniController,
            focusNode: _uniFocusNode,
            hintText: 'Üniversite',
            icon: Icons.school_outlined,
          ),
          const SizedBox(height: AppDimensions.spacing16),

          // City
          GlassField(
            controller: _cityController,
            focusNode: _cityFocusNode,
            hintText: 'Şehir',
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: AppDimensions.spacing16),

          // Clinic
          GlassField(
            controller: _clinicController,
            focusNode: _clinicFocusNode,
            hintText: 'Çalıştığı Klinik/Hastane',
            icon: Icons.business_outlined,
          ),
          const SizedBox(height: AppDimensions.spacing16),

          // Experience Years
          GlassField(
            controller: _expController,
            focusNode: _expFocusNode,
            hintText: 'Deneyim Yılı',
            icon: Icons.trending_up_outlined,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppDimensions.spacing32),
        ],
      ),
    );
  }

  // STEP 3: Profile customization
  Widget _buildStep3(bool isDark, Color textPrimaryColor) {
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
                    _mockAvatars[_selectedAvatarIndex],
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
                  children: List.generate(_mockAvatars.length, (index) {
                    final isSelected = _selectedAvatarIndex == index;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedAvatarIndex = index;
                        });
                      },
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
                          backgroundImage: NetworkImage(_mockAvatars[index]),
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
            controller: _bioController,
            focusNode: _bioFocusNode,
            hintText: 'Biyografi (Kendinizden kısaca bahsedin)',
            icon: Icons.description_outlined,
            maxLines: 4,
          ),
          const SizedBox(height: AppDimensions.spacing32),
        ],
      ),
    );
  }

  Widget _buildBottomActions(bool isDark) {
    final isLastStep = _currentStep == _totalSteps - 1;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacing24,
        vertical: AppDimensions.spacing20,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.2),
        border: Border(
          top: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: _prevStep,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusMedium,
                  ),
                ),
              ),
              child: Text(
                _currentStep == 0 ? 'Girişe Dön' : 'Geri',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacing16),
          Expanded(
            flex: 2,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _nextStep,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                child: Ink(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13B9A5),
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusMedium,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF13B9A5).withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      isLastStep ? 'Profilimi Tamamla' : 'Devam Et',
                      style: AppTextStyles.button.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
