import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/feed/screens/feed_screen.dart';
import '../../features/messaging/screens/conversations_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/shell/main_shell.dart';

/// DentLink uygulama router'ı.
///
/// Navigasyon yapısı:
///   /login            → LoginScreen
///   /register         → RegisterScreen
///   /                 → redirect → /login
///   ShellRoute        → MainShell (bottom nav)
///     /feed           → FeedScreen
///     /search         → SearchScreen
///     /messages       → ConversationsScreen
///     /profile        → ProfileScreen
///
/// Faz 3'te auth durumuna göre redirect eklenecek.
final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  debugLogDiagnostics: false,
  routes: [
    // ── Auth ──────────────────────────────────────────────
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),

    // ── Ana Kabuk (Bottom Nav Shell) ───────────────────────
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/feed',
          name: 'feed',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: FeedScreen(),
          ),
        ),
        GoRoute(
          path: '/search',
          name: 'search',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SearchScreen(),
          ),
        ),
        GoRoute(
          path: '/messages',
          name: 'messages',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ConversationsScreen(),
          ),
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProfileScreen(),
          ),
        ),
      ],
    ),
  ],

  // Bilinmeyen route'a düşülürse login'e dön
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 16),
          Text('Sayfa bulunamadı: ${state.uri}'),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Giriş sayfasına dön'),
          ),
        ],
      ),
    ),
  ),
);
