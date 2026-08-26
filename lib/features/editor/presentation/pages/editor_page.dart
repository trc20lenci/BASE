import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Экран редактора.
///
/// ВАЖНО: это структурная заготовка под редактор (окно предпросмотра +
/// таймлайн + панель инструментов), созданная на этапе "Экраны и
/// навигация". Полная логика — импорт медиа, обрезка/разделение клипов,
/// работа с холстом, текст — реализуется на этапе 6 ("редактор") и
/// этапе 7 ("экспорт") по плану ТЗ, отдельными последующими коммитами,
/// чтобы не сокращать и не пропускать архитектурные решения по каждому
/// инструменту.
class EditorPage extends StatelessWidget {
  final String projectId;

  const EditorPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактор'),
        actions: [
          TextButton(
            onPressed: null, // подключается на этапе "Экспорт"
            child: Text('Экспорт', style: AppTextStyles.body.copyWith(color: AppColors.textDisabled)),
          ),
          const SizedBox(width: AppSizes.sm),
        ],
      ),
      body: Column(
        children: [
          // Окно предпросмотра
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(color: AppColors.divider),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.movie_creation_outlined,
                        color: AppColors.textDisabled, size: 40),
                    const SizedBox(height: AppSizes.sm),
                    Text('Окно предпросмотра', style: AppTextStyles.bodySecondary),
                    Text('Проект: $projectId', style: AppTextStyles.caption),
                  ],
                ),
              ),
            ),
          ),
          // Таймлайн
          Container(
            height: AppSizes.timelineHeight,
            margin: const EdgeInsets.symmetric(horizontal: AppSizes.md),
            padding: const EdgeInsets.all(AppSizes.sm),
            decoration: BoxDecoration(
              color: AppColors.timelineTrack,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Center(
              child: Text(
                'Таймлайн (добавление фото/видео) — этап 6',
                style: AppTextStyles.caption,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          // Панель инструментов
          SizedBox(
            height: AppSizes.bottomToolbarHeight,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              children: const [
                _ToolButton(icon: Icons.add_photo_alternate_outlined, label: 'Добавить'),
                _ToolButton(icon: Icons.content_cut, label: 'Обрезка'),
                _ToolButton(icon: Icons.call_split, label: 'Разделить'),
                _ToolButton(icon: Icons.text_fields, label: 'Текст'),
                _ToolButton(icon: Icons.crop, label: 'Кадрирование'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ToolButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.textDisabled, size: 22),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
