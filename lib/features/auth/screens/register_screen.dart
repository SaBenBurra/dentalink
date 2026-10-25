import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'dart:io';
import 'package:dentlink/features/auth/widgets/register_bottom_actions.dart';
import 'package:dentlink/features/auth/widgets/register_dialog.dart';
import 'package:dentlink/features/auth/widgets/register_header.dart';
import 'package:dentlink/features/auth/widgets/register_step_one.dart';
import 'package:dentlink/features/auth/widgets/register_step_three.dart';
import 'package:dentlink/features/auth/widgets/register_step_two.dart';
import 'package:dentlink/shared/widgets/glass_background_effect.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../providers/register_controller.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/utils/error_messages.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final PageController _pageController = PageController();
  final int _totalSteps = RegisterController.totalSteps;

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

  // Başarı diyaloğu sürerken router'ın /feed'e atlaması bekletilir (BUG-21).
  ProviderContainer? _container;
  bool _holdsAuthRedirect = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _container = ProviderScope.containerOf(context);
  }

  void _setAuthRedirectHold(bool hold) {
    if (_holdsAuthRedirect == hold) return;
    _holdsAuthRedirect = hold;
    _container?.read(authRedirectHoldProvider.notifier).state = hold;
  }

  @override
  void dispose() {
    _setAuthRedirectHold(false);
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
    FocusScope.of(context).unfocus();
    final state = ref.read(registerControllerProvider);
    
    if (state.currentStep == 0 && state.selectedTitle == null) {
      // Validate first step title
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.validationTitleRequired),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (state.currentStep == 0 && !state.acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.validationTermsRequired),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    
    try {
      ref.read(registerControllerProvider.notifier).nextStep(_nameController.text);
      final newState = ref.read(registerControllerProvider);
      
      if (newState.currentStep > state.currentStep) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else if (state.currentStep == _totalSteps - 1 && newState.nameError == null) {
        _completeRegistration();
      }
    } catch (e) {
      // Exception thrown for missing title or name
    }
  }

  void _prevStep() {
    FocusScope.of(context).unfocus();
    final state = ref.read(registerControllerProvider);
    
    if (state.currentStep > 0) {
      ref.read(registerControllerProvider.notifier).prevStep();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Oturum açık kaldıkça redirect /register'a geri atar; başka hesaba
      // geçebilmek için çıkış yapılır (AUDIT AUTH-3). Router /login'e taşır.
      ref.read(authProvider.notifier).signOut();
    }
  }

  Future<void> _completeRegistration() async {
    _setAuthRedirectHold(true);
    try {
      await ref.read(registerControllerProvider.notifier).completeRegistration(
        fullName: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        university: _uniController.text.trim(),
        city: _cityController.text.trim(),
        workplace: _clinicController.text.trim(),
        experienceYearsStr: _expController.text.trim(),
      );

      if (!mounted) return;

      // Başarı dialogu göster
      showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'Success',
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
        transitionBuilder: (context, anim1, anim2, child) {
          final scale = Tween<double>(begin: 0.8, end: 1.0)
              .animate(CurvedAnimation(parent: anim1, curve: Curves.elasticOut));
          return RegisterDialog(scale: scale);
        },
      );

      await Future.delayed(const Duration(milliseconds: 1500));

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      context.go('/feed');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getErrorMessage(AppLocalizations.of(context)!, e)),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      _setAuthRedirectHold(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registerControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.darkBackground
        : AppColors.bgGradientStart;
    final textPrimaryColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
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
          
          SafeArea(
            child: Column(
              children: [
                RegisterHeader(
                  currentStep: state.currentStep,
                  totalSteps: _totalSteps,
                  prevStep: _prevStep,
                  nextStep: _nextStep,
                ),

                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (int page) {
                      ref.read(registerControllerProvider.notifier).setStep(page);
                    },
                    children: [
                      RegisterStepOne(
                        nameController: _nameController,
                        nameError: state.nameError,
                        nameFocusNode: _nameFocusNode,
                        selectedTitle: state.selectedTitle,
                        onNameChanged: (val) {
                          ref.read(registerControllerProvider.notifier).clearNameError();
                        },
                        onTitleSelected: (title) {
                          ref.read(registerControllerProvider.notifier).setTitle(title);
                        },
                        acceptedTerms: state.acceptedTerms,
                        onAcceptedTermsChanged: (value) {
                          ref.read(registerControllerProvider.notifier).setAcceptedTerms(value);
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
                        selectedImageFile: state.selectedImageFile,
                        bioController: _bioController,
                        bioFocusNode: _bioFocusNode,
                        onImageFilePicked: (File? file) {
                          ref.read(registerControllerProvider.notifier).setImageFile(file);
                        },
                      ),
                    ],
                  ),
                ),

                RegisterBottomActions(
                  currentStep: state.currentStep,
                  totalSteps: _totalSteps,
                  nextStep: _nextStep,
                  prevStep: _prevStep,
                ),
              ],
            ),
          ),

          if (state.isCompleting)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacing32,
                      vertical: AppDimensions.spacing24,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.85)
                          : Colors.white.withValues(alpha: 0.92),
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
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacing16),
                        Text(
                          AppLocalizations.of(context)!.registerCreatingProfile,
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
        ],
      ),
    );
  }
}
