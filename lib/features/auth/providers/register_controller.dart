import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/enums.dart';
import '../../../providers/auth_provider.dart';

class RegisterState {
  final int currentStep;
  final bool isCompleting;
  final String? nameError;
  final UserTitle? selectedTitle;
  final int selectedAvatarIndex;
  final File? selectedImageFile;

  const RegisterState({
    this.currentStep = 0,
    this.isCompleting = false,
    this.nameError,
    this.selectedTitle,
    this.selectedAvatarIndex = 0,
    this.selectedImageFile,
  });

  RegisterState copyWith({
    int? currentStep,
    bool? isCompleting,
    String? Function()? nameError,
    UserTitle? Function()? selectedTitle,
    int? selectedAvatarIndex,
    File? Function()? selectedImageFile,
  }) {
    return RegisterState(
      currentStep: currentStep ?? this.currentStep,
      isCompleting: isCompleting ?? this.isCompleting,
      nameError: nameError != null ? nameError() : this.nameError,
      selectedTitle: selectedTitle != null ? selectedTitle() : this.selectedTitle,
      selectedAvatarIndex: selectedAvatarIndex ?? this.selectedAvatarIndex,
      selectedImageFile: selectedImageFile != null ? selectedImageFile() : this.selectedImageFile,
    );
  }
}

class RegisterController extends AutoDisposeNotifier<RegisterState> {
  static const int totalSteps = 3;

  @override
  RegisterState build() {
    return const RegisterState();
  }

  void setStep(int step) {
    if (step >= 0 && step < totalSteps) {
      state = state.copyWith(currentStep: step);
    }
  }

  void nextStep(String name) {
    if (state.currentStep == 0) {
      final error = name.trim().isEmpty ? 'Ad Soyad alanı zorunludur' : null;
      state = state.copyWith(nameError: () => error);
      
      if (error != null) return;
      if (state.selectedTitle == null) {
        throw Exception('Lütfen bir unvan seçin');
      }
    }
    
    if (state.currentStep < totalSteps - 1) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void prevStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void clearNameError() {
    if (state.nameError != null) {
      state = state.copyWith(nameError: () => null);
    }
  }

  void setTitle(UserTitle title) {
    state = state.copyWith(selectedTitle: () => title);
  }

  void setAvatar(int index, {File? file}) {
    state = state.copyWith(
      selectedAvatarIndex: index,
      selectedImageFile: () => file,
    );
  }

  Future<void> completeRegistration({
    required String fullName,
    String? bio,
    String? university,
    String? city,
    String? workplace,
    String? experienceYearsStr,
  }) async {
    state = state.copyWith(isCompleting: true);

    try {
      final expYears = int.tryParse(experienceYearsStr ?? '');

      await ref.read(authProvider.notifier).completeRegistration(
            fullName: fullName,
            title: state.selectedTitle!,
            bio: bio?.isNotEmpty == true ? bio : null,
            university: university?.isNotEmpty == true ? university : null,
            city: city?.isNotEmpty == true ? city : null,
            workplace: workplace?.isNotEmpty == true ? workplace : null,
            experienceYears: expYears,
            avatarFile: state.selectedImageFile,
          );
      state = state.copyWith(isCompleting: false);
    } catch (e) {
      state = state.copyWith(isCompleting: false);
      rethrow;
    }
  }
}

final registerControllerProvider = AutoDisposeNotifierProvider<RegisterController, RegisterState>(() {
  return RegisterController();
});
