import 'package:dentlink/core/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers/repository_providers.dart';
import '../../features/auth/screens/auth_error_screen.dart';
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
import '../../features/post/screens/edit_post_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/followers_screen.dart';
import '../../features/messaging/screens/chat_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/settings/screens/blocked_users_screen.dart';
import '../../features/bookmarks/screens/bookmarks_screen.dart';
import 'package:dentlink/core/constants/app_dimensions.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/user_model.dart';

/// Auth durumu değişince GoRouter redirect'ini yeniden çalıştırır.
class _AuthRefreshNotifier extends ChangeNotifier {
  void ping() => notifyListeners();
}

/// Auth guard kararı (saf fonksiyon; test: test/core/router/auth_redirect_test.dart).
///
/// [hold]: OTP başarı animasyonu sürerken yönlendirme bekletilir.
String? resolveAuthRedirect({
  required String location,
  required bool hasSession,
  required bool hold,
  required AsyncValue<UserModel?> auth,
}) {
  final isLogin = location == '/login';
  final isRegister = location == '/register';
  final isAuthError = location == '/auth-error';
  final isAuthRoute = isLogin || isRegister || isAuthError;

  // Oturum yoksa korumalı sayfalara girilemez.
  if (!hasSession) return (isLogin || isRegister) ? null : '/login';

  if (hold) return null;

  // Profil yüklenirken karar verme (yanlış /feed veya /register atlamasını önler).
  if (auth.isLoading) return null;

  // Profil yüklenemedi (ağ/sunucu hatası) ≠ profil yok (AUDIT AUTH-1).
  // Kayıt ekranındaki hatalar (ör. kayıt insert'ü) ekranın kendisinde gösterilir.
  if (auth.hasError) return (isRegister || isAuthError) ? null : '/auth-error';

  // Oturum var ama public.users satırı yok → kayıt tamamlanmamış.
  if (auth.valueOrNull == null) return isRegister ? null : '/register';

  // Tam kayıtlı kullanıcı login/register/hata ekranında kalmasın.
  return isAuthRoute ? '/feed' : null;
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
  ref.listen(authProvider, (prev, next) => refresh.ping());
  ref.listen(authRedirectHoldProvider, (prev, next) => refresh.ping());

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: false,
    refreshListenable: refresh,

    // ── Auth Redirect ─────────────────────────────────────────────────
    redirect: (context, state) => resolveAuthRedirect(
          location: state.matchedLocation,
          hasSession: ref.read(authRepositoryProvider).hasSession,
          hold: ref.read(authRedirectHoldProvider),
          auth: ref.read(authProvider),
        ),

    routes: [
      // ── Auth ──────────────────────────────────────────────
      GoRoute(
        path: '/',
        redirect: (context, state) => '/feed',
      ),
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
      GoRoute(
        path: '/auth-error',
        name: 'authError',
        builder: (context, state) => const AuthErrorScreen(),
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
        path: '/edit-post/:id',
        name: 'editPost',
        builder: (context, state) =>
            EditPostScreen(postId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/edit-profile',
        name: 'editProfile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile/:id',
        name: 'userProfile',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProfileScreen(userId: id);
        },
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
          final name = state.uri.queryParameters['name'] ?? '';
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
        path: '/settings/blocked',
        builder: (context, state) => const BlockedUsersScreen(),
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
            Text(AppLocalizations.of(context)!.pageNotFound(state.uri.toString())),
            const SizedBox(height: AppDimensions.spacing16),
            TextButton(
              onPressed: () => context.go('/login'),
              child: Text(AppLocalizations.of(context)!.backToLoginPage),
            ),
          ],
        ),
      ),
    ),
  );
});
