import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/routing/route_names.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Splash Screen — согласно ТЗ:
/// 1. Показывает логотип BASE.
/// 2. Проверяет авторизацию пользователя.
/// 3. Автоматически переходит на нужный экран (Home, если авторизован,
///    иначе — Login).
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Даём кадру отрисоваться, затем решаем куда переходить.
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveDestination());
  }

  Future<void> _resolveDestination() async {
    // authStateChangesProvider стримит текущее состояние сессии Supabase.
    // Ждём первое значение (null или User) и решаем маршрут.
    final authState = await ref.read(authStateChangesProvider.future);

    if (!mounted) return;

    if (authState != null) {
      context.go(RouteNames.home);
    } else {
      context.go(RouteNames.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo_black_bg.jpg',
              width: 160,
              // Плейсхолдер: логотип загружен как фото-ассет пользователем.
              // Когда появится прозрачный PNG/SVG логотипа, заменить на него.
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
