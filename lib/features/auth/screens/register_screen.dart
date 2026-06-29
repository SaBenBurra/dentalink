import 'dart:ui';
import 'package:dentlink/features/auth/widgets/register_bottom_actions.dart';
import 'package:dentlink/features/auth/widgets/register_dialog.dart';
import 'package:dentlink/features/auth/widgets/register_header.dart';
import 'package:dentlink/features/auth/widgets/register_step_one.dart';
import 'package:dentlink/features/auth/widgets/register_step_three.dart';
import 'package:dentlink/features/auth/widgets/register_step_two.dart';
import 'package:dentlink/shared/widgets/glass_background_effect.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../data/models/enums.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
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

  Future<void> _completeRegistration() async {
    setState(() {
      _isCompleting = true;
    });

    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;
    setState(() {
      _isCompleting = false;
    });

    // 2. Başarı dialogunu göster // <-- await kullanıldı
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Success',
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        final scale = Tween<double>(
          begin: 0.8,
          end: 1.0,
        ).animate(CurvedAnimation(parent: anim1, curve: Curves.elasticOut));
        return RegisterDialog(scale: scale);
      },
    );

    // 3. Dialog sonrası yönlendirme beklemesi (Opsiyonel ise dialog içine de alınabilir)
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      // Önce dialogu kapat, sonra yönlendir
      Navigator.of(context, rootNavigator: true).pop();
      context.go('/feed');
    }
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

          const GlassBackgroundEffect(
            left: -120,
            top: -120,
            width: 320,
            height: 320,
          ),
          const GlassBackgroundEffect(
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
                RegisterHeader(
                  currentStep: _currentStep,
                  totalSteps: _totalSteps,
                  prevStep: _prevStep,
                  nextStep: _nextStep,
                ),

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
                      RegisterStepOne(
                        nameController: _nameController,
                        nameError: _nameError,
                        nameFocusNode: _nameFocusNode,
                        selectedTitle: _selectedTitle,
                        onNameChanged: (val) {
                          if (_nameError != null && val.trim().isNotEmpty) {
                            setState(() {
                              _nameError = null;
                            });
                          }
                        },
                        onTitleSelected: (title) {
                          setState(() {
                            _selectedTitle = title;
                          });
                        },
                      ),
                      RegisterStepTwo(
                        uniController: _uniController,
                        uniFocusNode: _uniFocusNode,
                        cityController: _cityController,
                        cityFocusNode: _cityFocusNode,
                        clinicController: _clinicController,
                        clinicFocusNode: _clinicFocusNode,
                        expController: _expController,
                        expFocusNode: _expFocusNode,
                      ),
                      RegisterStepThree(
                        mockAvatars: _mockAvatars,
                        selectedAvatarIndex: _selectedAvatarIndex,
                        bioController: _bioController,
                        bioFocusNode: _bioFocusNode,
                        onAvatarSelected: (int index) {
                          // <-- Callback yakalanıyor
                          setState(() {
                            _selectedAvatarIndex =
                                index; // <-- Değer ana state'te güncelleniyor
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // Bottom Action Buttons
                RegisterBottomActions(
                  currentStep: _currentStep,
                  totalSteps: _totalSteps,
                  nextStep: _nextStep,
                  prevStep: _prevStep,
                ),
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
}
