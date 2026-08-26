import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/auth_providers.dart';

/// Экран "Вход": Email, Пароль, кнопки "Войти" / "Регистрация".
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await ref.read(signInUseCaseProvider).call(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      // Успешный вход обработает go_router redirect через
      // authStateChangesProvider — отдельный context.go здесь не нужен.
    } on FirebaseAuthException catch (e) {
      setState(() => _errorText = _mapFirebaseError(e));
    } catch (_) {
      setState(() => _errorText = 'Не удалось войти. Попробуйте ещё раз.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Неверный email или пароль.';
      case 'invalid-email':
        return 'Некорректный формат email.';
      case 'too-many-requests':
        return 'Слишком много попыток. Попробуйте позже.';
      default:
        return 'Ошибка входа: ${e.message ?? e.code}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.lg,
            vertical: AppSizes.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset('assets/images/logo_black_bg.jpg', width: 64),
              const SizedBox(height: AppSizes.lg),
              Text('С возвращением', style: AppTextStyles.h1),
              const SizedBox(height: AppSizes.xs),
              Text(
                'Войдите, чтобы продолжить работу над проектами',
                style: AppTextStyles.bodySecondary,
              ),
              const SizedBox(height: AppSizes.xl),
              AppTextField(
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSizes.md),
              AppTextField(
                controller: _passwordController,
                label: 'Пароль',
                obscureText: true,
                errorText: _errorText,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push(RouteNames.forgotPassword),
                  child: const Text('Забыли пароль?'),
                ),
              ),
              const SizedBox(height: AppSizes.md),
              AppButton(
                label: 'Войти',
                isLoading: _isLoading,
                onPressed: _handleSignIn,
              ),
              const SizedBox(height: AppSizes.md),
              AppButton(
                label: 'Регистрация',
                variant: AppButtonVariant.outlined,
                onPressed: () => context.push(RouteNames.register),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
