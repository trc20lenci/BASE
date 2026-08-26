import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/editor/presentation/pages/editor_page.dart';
import '../../features/export/presentation/pages/export_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/project/presentation/pages/create_project_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import 'route_names.dart';

/// Единая точка навигации приложения.
///
/// Архитектурное решение: redirect строится на authStateChangesProvider,
/// а не на локальном флаге в каждом экране — это гарантирует, что
/// логаут/логин из любого места приложения мгновенно приводит к
/// правильному экрану, без ручных context.go() россыпью по коду.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: RouteNames.splash,
    refreshListenable: GoRouterRefreshStream(ref),
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == RouteNames.login ||
          state.matchedLocation == RouteNames.register ||
          state.matchedLocation == RouteNames.forgotPassword;
      final isSplash = state.matchedLocation == RouteNames.splash;

      // Пока authState грузится впервые — не решаем ничего, Splash сам
      // подождёт и перейдёт куда нужно.
      if (isSplash) return null;

      return authState.when(
        data: (user) {
          final isAuthenticated = user != null;
          if (!isAuthenticated && !loggingIn) return RouteNames.login;
          if (isAuthenticated && loggingIn) return RouteNames.home;
          return null;
        },
        loading: () => null,
        error: (_, __) => null,
      );
    },
    routes: [
      GoRoute(path: RouteNames.splash, builder: (_, __) => const SplashPage()),
      GoRoute(path: RouteNames.login, builder: (_, __) => const LoginPage()),
      GoRoute(path: RouteNames.register, builder: (_, __) => const RegisterPage()),
      GoRoute(
        path: RouteNames.forgotPassword,
        builder: (_, __) => const ForgotPasswordPage(),
      ),
      GoRoute(path: RouteNames.home, builder: (_, __) => const HomePage()),
      GoRoute(path: RouteNames.profile, builder: (_, __) => const ProfilePage()),
      GoRoute(
        path: RouteNames.createProject,
        builder: (_, __) => const CreateProjectPage(),
      ),
      GoRoute(
        path: '${RouteNames.editor}/:projectId',
        builder: (_, state) => EditorPage(projectId: state.pathParameters['projectId']!),
      ),
      GoRoute(
        path: '${RouteNames.export}/:projectId',
        builder: (_, state) => ExportPage(projectId: state.pathParameters['projectId']!),
      ),
    ],
  );
});

/// Мостик между Riverpod Stream и Listenable, который требует go_router
/// для реактивного redirect при изменении authState (вход/выход из
/// любого места приложения сразу триггерит пересчёт redirect).
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Ref ref) {
    ref.listen(authStateChangesProvider, (_, __) => notifyListeners());
  }
}
