import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_providers.dart';

/// Экран "Регистрация": Имя пользователя, Email, Пароль.
/// При регистрации создаётся уникальный ID пользователя и данные
/// сохраняются в Supabase (см. AuthRemoteDataSource.signUp).
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (_usernameController.text.trim().isEmpty) {
      setState(() => _errorText = 'Введите имя пользователя.');
      return;
    }
    if (_passwordController.text.length < 6) {
      setState(() => _errorText = 'Пароль должен содержать минимум 6 символов.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await ref.read(signUpUseCaseProvider).call(
            username: _usernameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      // Redirect на Home произойдёт автоматически через authStateChanges.
    } on AuthException catch (e) {
      setState(() => _errorText = _mapAuthError(e));
    } catch (_) {
      setState(() => _errorText = 'Не удалось зарегистрироваться. Попробуйте ещё раз.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapAuthError(AuthException e) {
    switch (e.code) {
      case 'user_already_exists':
      case 'email_exists':
        return 'Этот email уже зарегистрирован.';
      case 'weak_password':
        return 'Пароль слишком простой.';
      case 'validation_failed':
        return 'Некорректный формат email.';
      default:
        return 'Ошибка регистрации: ${e.message}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Создать аккаунт', style: AppTextStyles.h1),
              const SizedBox(height: AppSizes.xs),
              Text(
                'Заполните данные, чтобы начать монтировать',
                style: AppTextStyles.bodySecondary,
              ),
              const SizedBox(height: AppSizes.xl),
              AppTextField(
                controller: _usernameController,
                label: 'Имя пользователя',
              ),
              const SizedBox(height: AppSizes.md),
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
              const SizedBox(height: AppSizes.xl),
              AppButton(
                label: 'Зарегистрироваться',
                isLoading: _isLoading,
                onPressed: _handleSignUp,
              ),
              const SizedBox(height: AppSizes.lg),
            ],
          ),
        ),
      ),
    );
  }
}
