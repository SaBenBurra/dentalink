import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_dimensions.dart';

/// DentLink karanlık tema tanımı — Stitch "Clinical Glass" tasarımından.
ThemeData buildDarkTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primaryLight,
    onPrimary: AppColors.darkBackground,
    primaryContainer: AppColors.primaryDark,
    onPrimaryContainer: AppColors.primarySurface,
    secondary: AppColors.secondaryLight,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.secondaryDark,
    onSecondaryContainer: AppColors.secondaryContainer,
    tertiary: AppColors.tertiaryLight,
    onTertiary: Colors.black,
    tertiaryContainer: AppColors.tertiaryDark,
    onTertiaryContainer: AppColors.tertiaryOnContainer,
    error: AppColors.error,
    onError: Colors.white,
    errorContainer: Color(0xFF93000A),
    onErrorContainer: AppColors.errorLight,
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkTextPrimary,
    surfaceContainerHighest: AppColors.darkSurfaceVariant,
    onSurfaceVariant: AppColors.darkTextSecondary,
    outline: AppColors.darkDivider,
    outlineVariant: AppColors.darkDivider,
    shadow: Colors.black26,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.darkBackground,

    // ── AppBar ──
    appBarTheme: AppBarTheme(
      elevation: AppDimensions.appBarElevation,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      backgroundColor: AppColors.darkSurface,
      foregroundColor: AppColors.darkTextPrimary,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: AppTextStyles.appBarTitle.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.darkIcon,
        size: AppDimensions.iconDefault,
      ),
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),

    // ── Bottom Navigation ──
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.darkSurface,
      selectedItemColor: AppColors.primaryLight,
      unselectedItemColor: AppColors.darkIcon,
      selectedLabelStyle: AppTextStyles.navLabel,
      unselectedLabelStyle: AppTextStyles.navLabel,
      elevation: 8,
    ),

    // ── Navigation Bar (Material 3) ──
    navigationBarTheme: NavigationBarThemeData(
      height: AppDimensions.bottomNavHeight,
      backgroundColor: AppColors.darkSurface,
      indicatorColor: AppColors.primaryDark.withValues(alpha: 0.3),
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStatePropertyAll(
        AppTextStyles.navLabel.copyWith(color: AppColors.darkTextSecondary),
      ),
      iconTheme: const WidgetStatePropertyAll(
        IconThemeData(size: AppDimensions.iconDefault),
      ),
    ),

    // ── Card ──
    cardTheme: CardThemeData(
      elevation: AppDimensions.cardElevation,
      color: AppColors.darkCard,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        side: const BorderSide(color: AppColors.darkDivider),
      ),
      margin: EdgeInsets.zero,
    ),

    // ── ElevatedButton ──
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: AppColors.darkBackground,
        minimumSize: const Size(64, AppDimensions.buttonHeight),
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
        foregroundColor: AppColors.primaryLight,
        minimumSize: const Size(64, AppDimensions.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        side: const BorderSide(color: AppColors.primaryLight),
        textStyle: AppTextStyles.button,
      ),
    ),

    // ── TextButton ──
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        textStyle: AppTextStyles.button,
      ),
    ),

    // ── TextField / Input ──
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurfaceVariant,
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
          color: AppColors.primaryLight,
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
        color: AppColors.darkTextTertiary,
      ),
      labelStyle: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.darkTextSecondary,
      ),
    ),

    // ── Chip ──
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.darkSurfaceVariant,
      selectedColor: AppColors.primaryDark.withValues(alpha: 0.3),
      labelStyle: AppTextStyles.labelMedium.copyWith(
        color: AppColors.darkTextSecondary,
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
      color: AppColors.darkDivider,
      thickness: 1,
      space: 0,
    ),

    // ── TabBar ──
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.primaryLight,
      unselectedLabelColor: AppColors.darkTextSecondary,
      labelStyle: AppTextStyles.tabLabel,
      unselectedLabelStyle: AppTextStyles.tabLabel,
      indicatorColor: AppColors.primaryLight,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: AppColors.darkDivider,
    ),

    // ── BottomSheet ──
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.darkSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXLarge),
        ),
      ),
    ),

    // ── Dialog ──
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.darkSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      ),
    ),

    // ── Snackbar ──
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.darkSurfaceVariant,
      contentTextStyle: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      behavior: SnackBarBehavior.floating,
    ),

    // ── ListTile ──
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: AppDimensions.spacing16),
      minVerticalPadding: AppDimensions.spacing12,
      iconColor: AppColors.darkIcon,
    ),

    // ── Text Tema ──
    textTheme: TextTheme(
      displayLarge: AppTextStyles.displayLarge.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      displayMedium: AppTextStyles.displayMedium.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      displaySmall: AppTextStyles.displaySmall.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      headlineLarge: AppTextStyles.headlineLarge.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      headlineMedium: AppTextStyles.headlineMedium.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      headlineSmall: AppTextStyles.headlineSmall.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      titleLarge: AppTextStyles.titleLarge.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      titleMedium: AppTextStyles.titleMedium.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      titleSmall: AppTextStyles.titleSmall.copyWith(
        color: AppColors.darkTextSecondary,
      ),
      bodyLarge: AppTextStyles.bodyLarge.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      bodyMedium: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      bodySmall: AppTextStyles.bodySmall.copyWith(
        color: AppColors.darkTextSecondary,
      ),
      labelLarge: AppTextStyles.labelLarge.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      labelMedium: AppTextStyles.labelMedium.copyWith(
        color: AppColors.darkTextSecondary,
      ),
      labelSmall: AppTextStyles.labelSmall.copyWith(
        color: AppColors.darkTextTertiary,
      ),
    ),

    // ── Icon ──
    iconTheme: const IconThemeData(
      color: AppColors.darkIcon,
      size: AppDimensions.iconDefault,
    ),

    // ── FloatingActionButton ──
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryLight,
      foregroundColor: AppColors.darkBackground,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      ),
    ),
  );
}
