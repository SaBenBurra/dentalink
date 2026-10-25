import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../providers/locale_provider.dart';
import '../../../providers/theme_provider.dart';
import '../widgets/settings_section.dart';
import '../widgets/delete_account_dialog.dart';
import '../widgets/settings_tile.dart';
import '../../../providers/auth_provider.dart';

/// Ayarlar ekranı.
///
/// Genişletilebilirlik prensibi: Yeni bir ayar eklemek için
/// [_buildSections] metoduna yeni bir [SettingsSection] eklemek yeterlidir.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settingsTitle),
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacing16),
        children: _buildSections(context, ref, isDark),
      ),
    );
  }

  /// Ayar bölümlerini oluşturur. Yeni bölüm eklemek için listeye ekleme yapın.
  List<Widget> _buildSections(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
  ) {
    return [
      _buildAppearanceSection(context, ref, isDark),
      _buildLanguageSection(context, ref, isDark),
      _buildAccountSection(context, ref, isDark),
      _buildAboutSection(context, ref, isDark),
    ];
  }

  // ─── Görünüm ──────────────────────────────────────────────────────────

  Widget _buildAppearanceSection(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
  ) {
    final themeMode = ref.watch(themeModeProvider);

    return SettingsSection(
      title: AppLocalizations.of(context)!.settingsAppearance,
      icon: Icons.palette_outlined,
      children: [
        SettingsTile(
          icon: Icons.dark_mode_outlined,
          title: AppLocalizations.of(context)!.settingsTheme,
          subtitle: _themeModeLabel(AppLocalizations.of(context)!, themeMode),
          onTap: () => _showThemePicker(context, ref, themeMode),
        ),
      ],
    );
  }

  String _themeModeLabel(AppLocalizations l10n, ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => l10n.settingsThemeSystem,
      ThemeMode.light => l10n.settingsThemeLight,
      ThemeMode.dark => l10n.settingsThemeDark,
    };
  }

  void _showThemePicker(
    BuildContext context,
    WidgetRef ref,
    ThemeMode current,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXLarge),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.spacing16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacing24,
                    vertical: AppDimensions.spacing8,
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.settingsChooseTheme,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(),
                _buildThemeOption(
                  context,
                  ref,
                  icon: Icons.brightness_auto_outlined,
                  label: AppLocalizations.of(context)!.settingsThemeSystem,
                  mode: ThemeMode.system,
                  current: current,
                ),
                _buildThemeOption(
                  context,
                  ref,
                  icon: Icons.light_mode_outlined,
                  label: AppLocalizations.of(context)!.settingsThemeLight,
                  mode: ThemeMode.light,
                  current: current,
                ),
                _buildThemeOption(
                  context,
                  ref,
                  icon: Icons.dark_mode_outlined,
                  label: AppLocalizations.of(context)!.settingsThemeDark,
                  mode: ThemeMode.dark,
                  current: current,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String label,
    required ThemeMode mode,
    required ThemeMode current,
  }) {
    final isSelected = mode == current;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Theme.of(context).colorScheme.primary : null),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_rounded, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: () {
        ref.read(themeModeProvider.notifier).setThemeMode(mode);
        Navigator.pop(context);
      },
    );
  }

  // ─── Dil ────────────────────────────────────────────────────────────────

  Widget _buildLanguageSection(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
  ) {
    final locale = ref.watch(localeModeProvider);
    final isTurkish = locale.languageCode == 'tr';

    return SettingsSection(
      title: AppLocalizations.of(context)!.settingsLanguage,
      icon: Icons.language_outlined,
      children: [
        SettingsTile(
          icon: Icons.translate_outlined,
          title: AppLocalizations.of(context)!.settingsAppLanguage,
          // Dil adları her dilde kendi yazımıyla gösterilir (çevrilmez).
          subtitle: isTurkish ? 'Türkçe' : 'English',
          onTap: () => _showLanguagePicker(context, ref, locale),
        ),
      ],
    );
  }

  void _showLanguagePicker(
    BuildContext context,
    WidgetRef ref,
    Locale current,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXLarge),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.spacing16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacing24,
                    vertical: AppDimensions.spacing8,
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.settingsChooseLanguage,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(),
                _buildLanguageOption(
                  context,
                  ref,
                  flag: '🇹🇷',
                  label: 'Türkçe',
                  locale: const Locale('tr'),
                  current: current,
                ),
                _buildLanguageOption(
                  context,
                  ref,
                  flag: '🇬🇧',
                  label: 'English',
                  locale: const Locale('en'),
                  current: current,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    WidgetRef ref, {
    required String flag,
    required String label,
    required Locale locale,
    required Locale current,
  }) {
    final isSelected = locale == current;
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_rounded, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: () {
        ref.read(localeModeProvider.notifier).setLocale(locale);
        Navigator.pop(context);
      },
    );
  }

  // ─── Hesap ──────────────────────────────────────────────────────────────

  Widget _buildAccountSection(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
  ) {
    return SettingsSection(
      title: AppLocalizations.of(context)!.settingsAccount,
      icon: Icons.person_outline_rounded,
      children: [
        SettingsTile(
          icon: Icons.edit_outlined,
          title: AppLocalizations.of(context)!.editProfile,
          onTap: () => context.push('/edit-profile'),
        ),
        SettingsTile(
          icon: Icons.block_outlined,
          title: AppLocalizations.of(context)!.settingsBlocked,
          onTap: () => context.push('/settings/blocked'),
        ),
        SettingsTile(
          icon: Icons.delete_forever_outlined,
          title: AppLocalizations.of(context)!.settingsDeleteAccount,
          onTap: () => showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (_) => const DeleteAccountDialog(),
          ),
        ),
      ],
    );
  }

  // ─── Hakkında ───────────────────────────────────────────────────────────

  Widget _buildAboutSection(BuildContext context, WidgetRef ref, bool isDark) {
    return SettingsSection(
      title: AppLocalizations.of(context)!.settingsAbout,
      icon: Icons.info_outline_rounded,
      children: [
        SettingsTile(
          icon: Icons.description_outlined,
          title: AppLocalizations.of(context)!.settingsTerms,
          subtitle: AppLocalizations.of(context)!.comingSoon,
          enabled: false,
          onTap: () {},
        ),
        SettingsTile(
          icon: Icons.privacy_tip_outlined,
          title: AppLocalizations.of(context)!.settingsPrivacyPolicy,
          subtitle: AppLocalizations.of(context)!.comingSoon,
          enabled: false,
          onTap: () {},
        ),
        SettingsTile(
          icon: Icons.info_outline_rounded,
          title: AppLocalizations.of(context)!.settingsAppVersion,
          subtitle: 'v0.1.0 (Demo)',
          onTap: () {},
        ),
        const SizedBox(height: AppDimensions.spacing16),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacing24,
          ),
          child: OutlinedButton.icon(
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
              // Router will automatically redirect to /login due to auth state change.
            },
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            label: Text(
              AppLocalizations.of(context)!.settingsLogout,
              style: AppTextStyles.button.copyWith(color: AppColors.error),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.spacing12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spacing32),
      ],
    );
  }
}
