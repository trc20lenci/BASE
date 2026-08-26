import 'package:flutter/material.dart';

enum AppButtonVariant { primary, outlined, text }

/// Кнопка с встроенным состоянием загрузки — используется во всех формах
/// (вход/регистрация/восстановление/создание проекта и т.д.), чтобы не
/// дублировать логику "показать спиннер, пока идёт запрос к Firebase".
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonVariant variant;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
  });

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : Text(label);

    final effectiveOnPressed = isLoading ? null : onPressed;

    switch (variant) {
      case AppButtonVariant.primary:
        return ElevatedButton(onPressed: effectiveOnPressed, child: child);
      case AppButtonVariant.outlined:
        return OutlinedButton(onPressed: effectiveOnPressed, child: child);
      case AppButtonVariant.text:
        return TextButton(onPressed: effectiveOnPressed, child: child);
    }
  }
}
