import 'package:dentigo/core/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers/repository_providers.dart';
import '../../providers/welcome_provider.dart';
import '../../features/auth/screens/auth_error_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/feed/screens/feed_screen.dart';
import '../../features/messaging/screens/conversations_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/treatments/screens/treatment_archive_screen.dart';
import '../../data/models/case_treatment.dart';
import '../../features/shell/main_shell.dart';
import '../../features/post/screens/post_likers_screen.dart';
import '../../features/post/screens/post_screen.dart';
import '../../features/post/screens/create_case_screen.dart';
import '../../features/post/screens/create_question_screen.dart';
import '../../features/post/screens/create_listing_screen.dart';
import '../../features/post/screens/edit_post_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/followers_screen.dart';
import '../../features/messaging/screens/chat_screen.dart';
import '../../features/support/screens/support_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/settings/screens/blocked_users_screen.dart';
import '../../features/settings/screens/change_contact_screen.dart';
import '../../features/settings/screens/legal_screen.dart';
import '../../features/settings/screens/verification_screen.dart';
import '../../features/bookmarks/screens/bookmarks_screen.dart';
import '../../features/search/screens/popular_people_screen.dart';
import 'package:dentigo/core/constants/app_dimensions.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_version_provider.dart';
import '../../features/update/screens/update_required_screen.dart';
import '../../data/models/post_model.dart';
import '../../data/models/user_model.dart';

/// Auth durumu değişince GoRouter redirect'ini yeniden çalıştırır.
class _AuthRefreshNotifier extends ChangeNotifier {
  void ping() => notifyListeners();
}

/// Doğrulanmamış hesabın tek ekranı (066).
const verifyGate = '/verify';

/// Auth guard kararı (saf fonksiyon; test: test/core/router/auth_redirect_test.dart).
///
/// [hold]: OTP başarı animasyonu sürerken yönlendirme bekletilir.
/// [welcomed]: kullanıcı onay sonrası "Hoş geldin" ekranını gördü mü.
String? resolveAuthRedirect({
  required String location,
  required bool hasSession,
  required bool hold,
  required bool Function(String uid) welcomed,
  required AsyncValue<UserModel?> auth,
}) {
  final isLogin = location == '/login';
  final isRegister = location == '/register';
  final isAuthError = location == '/auth-error';
  // Açılış: profil yüklenene kadar boş ekran, giriş ekranı görünüp kaybolmasın.
  final isSplash = location == '/splash';
  final isAuthRoute = isLogin || isRegister || isAuthError || isSplash;

  // Hukuk metinleri her durumda okunabilir (kayıtta onay kutusundan açılır).
  if (location.startsWith('/legal/')) return null;

  // Oturum yoksa korumalı sayfalara girilemez.
  if (!hasSession) return (isLogin || isRegister) ? null : '/login';

  if (hold) return null;

  // Profil yüklenirken karar verme (yanlış /feed veya /register atlamasını önler).
  if (auth.isLoading) return null;

  // Profil yüklenemedi (ağ/sunucu hatası) ≠ profil yok (AUDIT AUTH-1).
  // Kayıt ekranındaki hatalar (ör. kayıt insert'ü) ekranın kendisinde gösterilir.
  if (auth.hasError) return (isRegister || isAuthError) ? null : '/auth-error';

  // Oturum var ama public.users satırı yok → kayıt tamamlanmamış.
  final user = auth.valueOrNull;
  if (user == null) return isRegister ? null : '/register';

  // 066: doğrulanmamış hesap yalnızca doğrulama ekranını ve destek sohbetini
  // açar (sunucu da diğer her isteği reddeder).
  if (!user.isVerified) {
    return location == verifyGate || location == '/support' ? null : verifyGate;
  }

  // Onaydan sonra bir kez "Hoş geldin" (doğrulama ekranında); butonla /feed.
  if (!welcomed(user.id)) return location == verifyGate ? null : verifyGate;

  // Tam kayıtlı kullanıcı login/register/hata ekranında kalmasın.
  return isAuthRoute || location == verifyGate ? '/feed' : null;
}

/// Sürüm kilidi (062; test: test/core/router/version_redirect_test.dart).
/// Auth guard'dan önce çalışır: [required] iken her rota (hukuk metinleri dahil)
/// `/update-required`'a gider; kilit kalkınca açılış akışına (`/splash`) dönülür.
String? resolveVersionRedirect({
  required String location,
  required bool required,
}) {
  const lock = '/update-required';
  if (required) return location == lock ? null : lock;
  return location == lock ? '/splash' : null;
}

/// Dentigo uygulama router'ı.
///
/// Navigasyon yapısı:
///   /splash           → SplashScreen (profil yüklenirken)
///   /login            → LoginScreen
///   /register         → RegisterScreen
///   /                 → redirect → /feed
///   StatefulShellRoute → MainShell (bottom nav, sekmeler canlı kalır)
///     /feed           → FeedScreen
///     /search         → SearchScreen
///     /messages       → ConversationsScreen
///     /profile        → ProfileScreen
///     `<tab>`/…         → detay sayfaları ([_detailRoutes], alt menü görünür)
///   /post/:id, /treatment/:slug… → aynı detaylar kökte (sekme dışından ve
///                       deep link; alt menü gizli)
///
/// Detay açmak için `context.push` yerine `context.pushDetail` kullanılır.
///
/// Oturum var ama `public.users` profili yoksa kullanıcı kayıt
/// ekranında tutulur (OTP sonrası yarım kalan kayıt).
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefreshNotifier();
  ref.onDispose(refresh.dispose);
  ref.listen(authProvider, (prev, next) => refresh.ping());
  ref.listen(authRedirectHoldProvider, (prev, next) => refresh.ping());
  ref.listen(appVersionStatusProvider, (prev, next) => refresh.ping());
  ref.listen(welcomedUsersProvider, (prev, next) => refresh.ping());

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    refreshListenable: refresh,

    // ── Sürüm + Auth Redirect ─────────────────────────────────────────
    redirect: (context, state) =>
        resolveVersionRedirect(
          location: state.matchedLocation,
          required:
              ref.read(appVersionStatusProvider) ==
              AppVersionStatus.updateRequired,
        ) ??
        resolveAuthRedirect(
          location: state.matchedLocation,
          hasSession: ref.read(authRepositoryProvider).hasSession,
          hold: ref.read(authRedirectHoldProvider),
          welcomed: ref.read(welcomedUsersProvider).contains,
          auth: ref.read(authProvider),
        ),

    routes: [
      GoRoute(
        path: '/update-required',
        builder: (context, state) => const UpdateRequiredScreen(),
      ),
      // ── Auth ──────────────────────────────────────────────
      GoRoute(path: '/', redirect: (context, state) => '/feed'),
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
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
        path: '/create-listing',
        name: 'createListing',
        builder: (context, state) => const CreateListingScreen(),
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
        path: '/chat/:userId',
        name: 'chat',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          final name = state.uri.queryParameters['name'] ?? '';
          final avatar = state.uri.queryParameters['avatar'] ?? '';
          return ChatScreen(
            userId: userId,
            userName: name,
            avatarUrl: avatar,
            initialText: state.uri.queryParameters['text'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/support',
        builder: (context, state) => const SupportScreen(),
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
        path: verifyGate,
        builder: (context, state) => const VerificationScreen(gate: true),
      ),
      GoRoute(
        path: '/settings/verification',
        builder: (context, state) => const VerificationScreen(),
      ),
      GoRoute(
        path: '/settings/contact/email',
        builder: (context, state) => const ChangeContactScreen(isEmail: true),
      ),
      GoRoute(
        path: '/settings/contact/phone',
        builder: (context, state) => const ChangeContactScreen(isEmail: false),
      ),
      GoRoute(
        path: '/legal/:doc',
        redirect: (context, state) =>
            LegalDoc.tryParse(state.pathParameters['doc']) == null
            ? '/settings'
            : null,
        builder: (context, state) =>
            LegalScreen(doc: LegalDoc.tryParse(state.pathParameters['doc'])!),
      ),
      // ── Ana Kabuk (Bottom Nav Shell) ───────────────────────
      // Her sekme kendi navigator'ında canlı kalır: sekme değişince veri ve
      // kaydırma konumu korunur. Detay sayfaları açıldıkları sekmenin içinde
      // açılır (`pushDetail`). Kabuk, kök seviyedeki `/profile/:id`'den önce
      // gelir: yoksa `/profile/bookmarks` kullanıcı profili sanılırdı.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/feed',
                name: 'feed',
                builder: (context, state) => const FeedScreen(),
                routes: _detailRoutes(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                name: 'search',
                builder: (context, state) => SearchScreen(
                  autofocus: state.uri.queryParameters['focus'] == '1',
                  tag: state.uri.queryParameters['tag'],
                  branch: state.uri.queryParameters['branch'],
                ),
                routes: _detailRoutes(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/messages',
                name: 'messages',
                builder: (context, state) => const ConversationsScreen(),
                routes: _detailRoutes(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
                routes: _detailRoutes(),
              ),
            ],
          ),
        ],
      ),
      // Sekme dışı (sohbet, ayarlar, oluşturma) ve uygulama açılışındaki
      // deep link hedefi; alt menü gizli.
      ..._detailRoutes(root: true),
    ],

    // Bilinmeyen route'a düşülürse login'e dön
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: AppDimensions.spacing16),
            Text(
              AppLocalizations.of(context)!.pageNotFound(state.uri.toString()),
            ),
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

/// Detay sayfaları: her sekmenin altında (`/feed/post/:id`, `/search/post/:id`…)
/// ve sekme dışı için kökte (`/post/:id`). Sekme içindekilerde alt menü görünür
/// kalır; aktif sekmeye dokunmak köke döner.
List<RouteBase> _detailRoutes({bool root = false}) {
  final p = root ? '/' : '';
  return [
    GoRoute(
      path: '${p}post/:id',
      builder: (context, state) => PostScreen(
        postId: state.pathParameters['id']!,
        initialPost: state.extra is PostModel ? state.extra as PostModel : null,
        scrollToComments: state.uri.queryParameters['comments'] == '1',
        highlightCommentId: state.uri.queryParameters['comment'],
      ),
      routes: [
        GoRoute(
          path: 'likes',
          builder: (context, state) =>
              PostLikersScreen(postId: state.pathParameters['id']!),
        ),
      ],
    ),
    // Tedavi arşivi; karttan gelince tedavi ve Hero etiketi extra ile taşınır.
    GoRoute(
      path: '${p}treatment/:slug',
      builder: (context, state) {
        final extra =
            state.extra is ({CaseTreatment treatment, Object? heroTag})
            ? state.extra as ({CaseTreatment treatment, Object? heroTag})
            : null;
        return TreatmentArchiveScreen(
          slug: state.pathParameters['slug']!,
          initial: extra?.treatment,
          heroTag: extra?.heroTag,
        );
      },
    ),
    GoRoute(
      path: '${p}profile/:id',
      builder: (context, state) =>
          ProfileScreen(userId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '${p}network/:id',
      builder: (context, state) => FollowersScreen(
        userId: state.pathParameters['id']!,
        initialIndex:
            int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0,
      ),
    ),
    GoRoute(
      path: '${p}bookmarks',
      builder: (context, state) => const BookmarksScreen(),
    ),
    GoRoute(
      path: '${p}notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '${p}popular-people',
      builder: (context, state) => const PopularPeopleScreen(),
    ),
  ];
}

final _detailPath = RegExp(
  r'^/(post|treatment|profile|network|bookmarks|notifications|popular-people)/?',
);

/// [location] bir detay sayfasıysa ve [tabRoot] (`/feed` gibi) verildiyse onu
/// sekmenin altına taşır; diğer rotalar (sohbet, ayarlar…) olduğu gibi kalır.
String detailLocationIn(String? tabRoot, String location) =>
    tabRoot != null && _detailPath.hasMatch(location)
    ? '$tabRoot$location'
    : location;

/// Detay sayfasını açık sekmenin içinde açar (alt menü görünür kalır). En üstte
/// sekme dışı bir sayfa (sohbet, ayarlar) varsa kökte açar: kabuk ikinci kez
/// kurulamaz.
Future<T?> pushDetailOn<T extends Object?>(
  GoRouter router,
  String location, {
  Object? extra,
}) {
  final top = router.routerDelegate.currentConfiguration.matches.lastOrNull;
  final tabRoot = top is ShellRouteMatch
      ? top.matches.first.matchedLocation
      : null;
  return router.push<T>(detailLocationIn(tabRoot, location), extra: extra);
}

extension DetailNavigation on BuildContext {
  /// Bkz. [pushDetailOn].
  Future<T?> pushDetail<T extends Object?>(String location, {Object? extra}) =>
      pushDetailOn<T>(GoRouter.of(this), location, extra: extra);
}
