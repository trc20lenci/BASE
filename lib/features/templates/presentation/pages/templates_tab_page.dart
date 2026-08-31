import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Вкладка "Шаблоны" — пользовательские шаблоны. По ТЗ на этом этапе
/// не реализуется, оставлена как пустое состояние-заглушка.
class TemplatesTabPage extends StatelessWidget {
  const TemplatesTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Шаблоны')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.grid_view_outlined, color: AppColors.textDisabled, size: 48),
              const SizedBox(height: AppSizes.md),
              Text('Пока пусто', style: AppTextStyles.h3),
              const SizedBox(height: AppSizes.xs),
              Text(
                'Здесь появятся ваши сохранённые шаблоны монтажа',
                style: AppTextStyles.bodySecondary,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
