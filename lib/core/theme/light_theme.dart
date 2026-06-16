import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_dimensions.dart';

/// DentLink aydınlık tema tanımı — Stitch "Clinical Glass" tasarımından.
ThemeData buildLightTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.lightTextOnPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.primaryDark,
    secondary: AppColors.secondary,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.secondaryOnContainer,
    tertiary: AppColors.tertiary,
    onTertiary: Colors.white,
    tertiaryContainer: AppColors.tertiaryContainer,
    onTertiaryContainer: AppColors.tertiaryOnContainer,
    error: AppColors.error,
    onError: AppColors.onError,
    errorContainer: AppColors.errorLight,
    onErrorContainer: AppColors.onErrorContainer,
    surface: AppColors.lightSurface,
    onSurface: AppColors.lightTextOnSurface,
    surfaceContainerHighest: AppColors.lightSurfaceVariant,
    onSurfaceVariant: AppColors.lightTextOnSurfaceVariant,
    outline: AppColors.lightOutline,
    outlineVariant: AppColors.lightDivider,
    shadow: Colors.black12,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.lightBackground,

    // ── AppBar ──
    appBarTheme: AppBarTheme(
      elevation: AppDimensions.appBarElevation,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      backgroundColor: AppColors.lightSurface,
      foregroundColor: AppColors.lightTextPrimary,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: AppTextStyles.appBarTitle.copyWith(
        color: AppColors.lightTextPrimary,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.lightIcon,
        size: AppDimensions.iconDefault,
      ),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),

    // ── Bottom Navigation ──
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.lightSurface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.lightIcon,
      selectedLabelStyle: AppTextStyles.navLabel,
      unselectedLabelStyle: AppTextStyles.navLabel,
      elevation: 8,
    ),

    // ── Navigation Bar (Material 3) ──
    navigationBarTheme: NavigationBarThemeData(
      height: AppDimensions.bottomNavHeight,
      backgroundColor: AppColors.lightSurface,
      indicatorColor: AppColors.primarySurface,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStatePropertyAll(
        AppTextStyles.navLabel.copyWith(color: AppColors.lightTextSecondary),
      ),
      iconTheme: const WidgetStatePropertyAll(
        IconThemeData(size: AppDimensions.iconDefault),
      ),
    ),

    // ── Card ──
    cardTheme: CardThemeData(
      elevation: AppDimensions.cardElevation,
      color: AppColors.lightCard,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        side: const BorderSide(color: AppColors.lightDivider),
      ),
      margin: EdgeInsets.zero,
    ),

    // ── ElevatedButton ──
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        textStyle: AppTextStyles.button,
        elevation: 0,
      ),
    ),

    // ── OutlinedButton ──
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        side: const BorderSide(color: AppColors.primary),
        textStyle: AppTextStyles.button,
      ),
    ),

    // ── TextButton ──
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: AppTextStyles.button,
      ),
    ),

    // ── TextField / Input ──
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightSurfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacing16,
        vertical: AppDimensions.spacing12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: AppDimensions.inputBorderWidth,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        borderSide: const BorderSide(
          color: AppColors.error,
          width: AppDimensions.inputBorderWidth,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        borderSide: const BorderSide(
          color: AppColors.error,
          width: AppDimensions.inputBorderWidth,
        ),
      ),
      hintStyle: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.lightTextTertiary,
      ),
      labelStyle: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.lightTextSecondary,
      ),
    ),

    // ── Chip ──
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.lightSurfaceContainer,
      selectedColor: AppColors.primarySurface,
      labelStyle: AppTextStyles.labelMedium.copyWith(
        color: AppColors.lightTextSecondary,
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacing12,
        vertical: AppDimensions.spacing4,
      ),
    ),

    // ── Divider ──
    dividerTheme: const DividerThemeData(
      color: AppColors.lightDivider,
      thickness: 1,
      space: 0,
    ),

    // ── TabBar ──
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.lightTextSecondary,
      labelStyle: AppTextStyles.tabLabel,
      unselectedLabelStyle: AppTextStyles.tabLabel,
      indicatorColor: AppColors.primary,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: AppColors.lightDivider,
    ),

    // ── BottomSheet ──
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.lightSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXLarge),
        ),
      ),
    ),

    // ── Dialog ──
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.lightSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      ),
    ),

    // ── Snackbar ──
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.darkSurfaceVariant,
      contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      behavior: SnackBarBehavior.floating,
    ),

    // ── ListTile ──
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppDimensions.spacing16,
      ),
      minVerticalPadding: AppDimensions.spacing12,
      iconColor: AppColors.lightIcon,
    ),

    // ── Text Tema ──
    textTheme: TextTheme(
      displayLarge: AppTextStyles.displayLarge.copyWith(color: AppColors.lightTextPrimary),
      displayMedium: AppTextStyles.displayMedium.copyWith(color: AppColors.lightTextPrimary),
      displaySmall: AppTextStyles.displaySmall.copyWith(color: AppColors.lightTextPrimary),
      headlineLarge: AppTextStyles.headlineLarge.copyWith(color: AppColors.lightTextPrimary),
      headlineMedium: AppTextStyles.headlineMedium.copyWith(color: AppColors.lightTextPrimary),
      headlineSmall: AppTextStyles.headlineSmall.copyWith(color: AppColors.lightTextPrimary),
      titleLarge: AppTextStyles.titleLarge.copyWith(color: AppColors.lightTextPrimary),
      titleMedium: AppTextStyles.titleMedium.copyWith(color: AppColors.lightTextPrimary),
      titleSmall: AppTextStyles.titleSmall.copyWith(color: AppColors.lightTextSecondary),
      bodyLarge: AppTextStyles.bodyLarge.copyWith(color: AppColors.lightTextPrimary),
      bodyMedium: AppTextStyles.bodyMedium.copyWith(color: AppColors.lightTextPrimary),
      bodySmall: AppTextStyles.bodySmall.copyWith(color: AppColors.lightTextSecondary),
      labelLarge: AppTextStyles.labelLarge.copyWith(color: AppColors.lightTextPrimary),
      labelMedium: AppTextStyles.labelMedium.copyWith(color: AppColors.lightTextSecondary),
      labelSmall: AppTextStyles.labelSmall.copyWith(color: AppColors.lightTextTertiary),
    ),

    // ── Icon ──
    iconTheme: const IconThemeData(
      color: AppColors.lightIcon,
      size: AppDimensions.iconDefault,
    ),

    // ── FloatingActionButton ──
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      ),
    ),
  );
}
