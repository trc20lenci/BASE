import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Вкладка "Обучение" — гайды и уроки по монтажу. Пока пустая заглушка,
/// контент добавим позже.
class LearningTabPage extends StatelessWidget {
  const LearningTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Обучение')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.school_outlined, color: AppColors.textDisabled, size: 48),
              const SizedBox(height: AppSizes.md),
              Text('Пока пусто', style: AppTextStyles.h3),
              const SizedBox(height: AppSizes.xs),
              Text(
                'Уроки и гайды по монтажу добавим на следующем этапе',
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
