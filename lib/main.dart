import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/l10n/generated/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'shared/widgets/offline_banner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://lknvufbxekceevdblgmq.supabase.co',
    publishableKey: 'sb_publishable_CGm0mMqcvUubeXazytJr-w_WK6CLfS5',
  );
  final prefs = await SharedPreferences.getInstance();
  runApp(
    // Riverpod'un tüm uygulamayı sarması gerekiyor
    ProviderScope(
      overrides: [
        themeModeProvider.overrideWith(() => ThemeModeNotifier(prefs)),
        localeModeProvider.overrideWith(() => LocaleModeNotifier(prefs)),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeModeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'DentLink',
      debugShowCheckedModeBanner: false,

      // Router
      routerConfig: router,
      builder: (context, child) => OfflineBanner(child: child!),

      // Tema
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,

      // Lokalizasyon
      locale: locale,
      supportedLocales: appSupportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
