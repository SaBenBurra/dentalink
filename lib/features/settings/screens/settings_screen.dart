import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../providers/locale_provider.dart';
import '../../../providers/theme_provider.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';

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
          ? const Color(0xFF11211F)
          : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Ayarlar'),
        leading: IconButton(
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
      _buildNotificationSection(context, ref, isDark),
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
      title: 'Görünüm',
      icon: Icons.palette_outlined,
      children: [
        SettingsTile(
          icon: Icons.dark_mode_outlined,
          title: 'Tema',
          subtitle: _themeModeLabel(themeMode),
          onTap: () => _showThemePicker(context, ref, themeMode),
        ),
      ],
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => 'Sistem',
      ThemeMode.light => 'Aydınlık',
      ThemeMode.dark => 'Karanlık',
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
                    'Tema Seçin',
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
                  label: 'Sistem',
                  mode: ThemeMode.system,
                  current: current,
                ),
                _buildThemeOption(
                  context,
                  ref,
                  icon: Icons.light_mode_outlined,
                  label: 'Aydınlık',
                  mode: ThemeMode.light,
                  current: current,
                ),
                _buildThemeOption(
                  context,
                  ref,
                  icon: Icons.dark_mode_outlined,
                  label: 'Karanlık',
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
      leading: Icon(icon, color: isSelected ? const Color(0xFF13B9A5) : null),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? const Color(0xFF13B9A5) : null,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_rounded, color: Color(0xFF13B9A5))
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
      title: 'Dil',
      icon: Icons.language_outlined,
      children: [
        SettingsTile(
          icon: Icons.translate_outlined,
          title: 'Uygulama Dili',
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
                    'Dil Seçin',
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
          color: isSelected ? const Color(0xFF13B9A5) : null,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_rounded, color: Color(0xFF13B9A5))
          : null,
      onTap: () {
        ref.read(localeModeProvider.notifier).setLocale(locale);
        Navigator.pop(context);
      },
    );
  }

  // ─── Bildirimler ────────────────────────────────────────────────────────

  Widget _buildNotificationSection(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
  ) {
    return SettingsSection(
      title: 'Bildirimler',
      icon: Icons.notifications_outlined,
      children: [
        SettingsTile.toggle(
          icon: Icons.favorite_outline_rounded,
          title: 'Beğeni Bildirimleri',
          subtitle: 'Gönderileriniz beğenildiğinde bildirim alın',
          value: true,
          onToggle: (_) {
            // Faz 3'te notification_preferences JSONB güncellenecek
          },
        ),
        SettingsTile.toggle(
          icon: Icons.chat_bubble_outline_rounded,
          title: 'Yorum Bildirimleri',
          subtitle: 'Gönderilerinize yorum yapıldığında bildirim alın',
          value: true,
          onToggle: (_) {},
        ),
        SettingsTile.toggle(
          icon: Icons.person_add_outlined,
          title: 'Takip Bildirimleri',
          subtitle: 'Yeni takipçileriniz olduğunda bildirim alın',
          value: true,
          onToggle: (_) {},
        ),
        SettingsTile.toggle(
          icon: Icons.mail_outline_rounded,
          title: 'Mesaj Bildirimleri',
          subtitle: 'Yeni mesaj aldığınızda bildirim alın',
          value: true,
          onToggle: (_) {},
        ),
      ],
    );
  }

  // ─── Hesap ──────────────────────────────────────────────────────────────

  Widget _buildAccountSection(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
  ) {
    return SettingsSection(
      title: 'Hesap',
      icon: Icons.person_outline_rounded,
      children: [
        SettingsTile(
          icon: Icons.edit_outlined,
          title: 'Profili Düzenle',
          onTap: () => context.push('/edit-profile'),
        ),
        SettingsTile(
          icon: Icons.lock_outline_rounded,
          title: 'Gizlilik',
          subtitle: 'Yakında',
          enabled: false,
          onTap: () {},
        ),
        SettingsTile(
          icon: Icons.block_outlined,
          title: 'Engellenenler',
          subtitle: 'Yakında',
          enabled: false,
          onTap: () {},
        ),
      ],
    );
  }

  // ─── Hakkında ───────────────────────────────────────────────────────────

  Widget _buildAboutSection(BuildContext context, WidgetRef ref, bool isDark) {
    return SettingsSection(
      title: 'Hakkında',
      icon: Icons.info_outline_rounded,
      children: [
        SettingsTile(
          icon: Icons.description_outlined,
          title: 'Kullanım Koşulları',
          subtitle: 'Yakında',
          enabled: false,
          onTap: () {},
        ),
        SettingsTile(
          icon: Icons.privacy_tip_outlined,
          title: 'Gizlilik Politikası',
          subtitle: 'Yakında',
          enabled: false,
          onTap: () {},
        ),
        SettingsTile(
          icon: Icons.info_outline_rounded,
          title: 'Uygulama Sürümü',
          subtitle: 'v0.1.0 (Demo)',
          onTap: () {},
        ),
        const SizedBox(height: AppDimensions.spacing16),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacing24,
          ),
          child: OutlinedButton.icon(
            onPressed: () {
              // Faz 3'te Supabase Auth signOut çağrılacak
              context.go('/login');
            },
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            label: Text(
              'Çıkış Yap',
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
