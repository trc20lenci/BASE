import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Экран экспорта: выбор качества (720p/1080p) и сохранение MP4
/// в галерею устройства. Логика рендера видео подключается на этапе 7,
/// когда будет готова модель таймлайна из этапа 6.
class ExportPage extends StatefulWidget {
  final String projectId;

  const ExportPage({super.key, required this.projectId});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  String _quality = '1080p';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Экспорт')),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Качество видео', style: AppTextStyles.h3),
            const SizedBox(height: AppSizes.sm),
            Wrap(
              spacing: AppSizes.sm,
              children: ['720p', '1080p'].map((q) {
                final selected = q == _quality;
                return ChoiceChip(
                  label: Text(q),
                  selected: selected,
                  onSelected: (_) => setState(() => _quality = q),
                  backgroundColor: AppColors.surfaceElevated,
                  selectedColor: AppColors.accent,
                  labelStyle: AppTextStyles.body.copyWith(
                    color: selected ? Colors.white : AppColors.textPrimary,
                  ),
                  side: BorderSide.none,
                );
              }).toList(),
            ),
            const Spacer(),
            ElevatedButton(
              // Подключение реального рендера MP4 и сохранения через
              // пакет gal — этап 7 (Экспорт) по плану ТЗ.
              onPressed: null,
              child: Text('Экспортировать в $_quality (скоро)'),
            ),
          ],
        ),
      ),
    );
  }
}
