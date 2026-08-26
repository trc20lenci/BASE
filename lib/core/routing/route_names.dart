/// Именованные пути навигации.
///
/// Держим их строками-константами в одном месте, чтобы go_router
/// и вызовы context.go(...) по всему приложению не расходились.
class RouteNames {
  RouteNames._();

  static const String splash = '/splash';

  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  static const String home = '/home';
  static const String profile = '/profile';

  static const String createProject = '/project/create';
  static const String editor = '/editor'; // /editor/:projectId
  static const String export = '/export'; // /export/:projectId
}
