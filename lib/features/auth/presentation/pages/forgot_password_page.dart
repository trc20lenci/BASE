import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/auth_providers.dart';

/// Экран восстановления пароля через email.
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await ref.read(resetPasswordUseCaseProvider).call(
            email: _emailController.text.trim(),
          );
      setState(() => _emailSent = true);
    } on AuthException catch (e) {
      setState(() => _errorText = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Восстановление пароля')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: _emailSent ? _buildSuccessState() : _buildFormState(),
        ),
      ),
    );
  }

  Widget _buildFormState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Введите email, привязанный к аккаунту — мы отправим ссылку '
          'для сброса пароля.',
          style: AppTextStyles.bodySecondary,
        ),
        const SizedBox(height: AppSizes.xl),
        AppTextField(
          controller: _emailController,
          label: 'Email',
          keyboardType: TextInputType.emailAddress,
          errorText: _errorText,
        ),
        const SizedBox(height: AppSizes.xl),
        AppButton(
          label: 'Отправить ссылку',
          isLoading: _isLoading,
          onPressed: _handleReset,
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.mark_email_read_outlined, color: AppColors.success, size: 40),
        const SizedBox(height: AppSizes.md),
        Text('Письмо отправлено', style: AppTextStyles.h2),
        const SizedBox(height: AppSizes.xs),
        Text(
          'Проверьте почту ${_emailController.text.trim()} и перейдите по ссылке.',
          style: AppTextStyles.bodySecondary,
        ),
      ],
    );
  }
}
