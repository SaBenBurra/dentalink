import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/feed/screens/feed_screen.dart';
import '../../features/messaging/screens/conversations_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/post/screens/case_detail_screen.dart';
import '../../features/post/screens/question_detail_screen.dart';
import '../../features/post/screens/create_case_screen.dart';
import '../../features/post/screens/create_question_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/followers_screen.dart';
import '../../features/messaging/screens/chat_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/bookmarks/screens/bookmarks_screen.dart';
import 'package:dentlink/core/constants/app_dimensions.dart';
import '../../providers/auth_provider.dart';

/// Auth durumu değişince GoRouter redirect'ini yeniden çalıştırır.
class _AuthRefreshNotifier extends ChangeNotifier {
  void ping() => notifyListeners();
}

/// DentLink uygulama router'ı.
///
/// Navigasyon yapısı:
///   /login            → LoginScreen
///   /register         → RegisterScreen
///   /feed/case/:id    → CaseDetailScreen
///   /feed/question/:id → QuestionDetailScreen
///   /                 → redirect → /login
///   ShellRoute        → MainShell (bottom nav)
///     /feed           → FeedScreen
///     /search         → SearchScreen
///     /messages       → ConversationsScreen
///     /profile        → ProfileScreen
///
/// Oturum var ama `public.users` profili yoksa kullanıcı kayıt
/// ekranında tutulur (OTP sonrası yarım kalan kayıt).
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefreshNotifier();
  ref.onDispose(refresh.dispose);
  ref.listen(authProvider, (_, _) => refresh.ping());
  ref.listen(authRedirectHoldProvider, (_, _) => refresh.ping());

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: false,
    refreshListenable: refresh,

    // ── Auth Redirect ─────────────────────────────────────────────────
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final hasSession = session != null;
      final location = state.matchedLocation;
      final isLogin = location == '/login';
      final isRegister = location == '/register';
      final isAuthRoute = isLogin || isRegister;

      // Oturum yoksa korumalı sayfalara girilemez.
      if (!hasSession && !isAuthRoute) {
        return '/login';
      }

      // OTP başarı animasyonu bitene kadar yönlendirmeyi beklet.
      if (ref.read(authRedirectHoldProvider)) {
        return null;
      }

      // Profil henüz yüklenirken yönlendirme yapma (yanlış /feed atlamasını
      // önler). Oturum varsa login'de bekleriz; yükleme bitince karar veririz.
      final authAsync = ref.read(authProvider);
      if (hasSession && authAsync.isLoading) {
        return null;
      }

      // Oturum var ama public.users satırı yok → kayıt tamamlanmamış.
      final hasProfile = authAsync.valueOrNull != null;
      if (hasSession && !hasProfile) {
        return isRegister ? null : '/register';
      }

      // Tam kayıtlı kullanıcı login/register'da kalmasın.
      if (hasSession && hasProfile && isAuthRoute) {
        return '/feed';
      }

      return null;
    },

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

      // ── Gönderi Detayları (Root level - Bottom Nav gizlenir) ─
      GoRoute(
        path: '/feed/case/:id',
        name: 'caseDetail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CaseDetailScreen(postId: id);
        },
      ),
      GoRoute(
        path: '/feed/question/:id',
        name: 'questionDetail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return QuestionDetailScreen(postId: id);
        },
      ),
      GoRoute(
        path: '/create-case',
        name: 'createCase',
        builder: (context, state) => const CreateCaseScreen(),
      ),
      GoRoute(
        path: '/create-question',
        name: 'createQuestion',
        builder: (context, state) => const CreateQuestionScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        name: 'editProfile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/network/:id',
        name: 'network',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final initialIndex =
              int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0;
          return FollowersScreen(userId: id, initialIndex: initialIndex);
        },
      ),
      GoRoute(
        path: '/chat/:userId',
        name: 'chat',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          final name = state.uri.queryParameters['name'] ?? 'Kullanıcı';
          final avatar = state.uri.queryParameters['avatar'] ?? '';
          return ChatScreen(userId: userId, userName: name, avatarUrl: avatar);
        },
      ),

      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/bookmarks',
        name: 'bookmarks',
        builder: (context, state) => const BookmarksScreen(),
      ),

      // ── Ana Kabuk (Bottom Nav Shell) ───────────────────────
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/feed',
            name: 'feed',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: FeedScreen()),
          ),
          GoRoute(
            path: '/search',
            name: 'search',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SearchScreen()),
          ),
          GoRoute(
            path: '/messages',
            name: 'messages',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ConversationsScreen()),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfileScreen()),
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
            const SizedBox(height: AppDimensions.spacing16),
            Text('Sayfa bulunamadı: ${state.uri}'),
            const SizedBox(height: AppDimensions.spacing16),
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Giriş sayfasına dön'),
            ),
          ],
        ),
      ),
    ),
  );
});
