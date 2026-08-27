import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/timeline_clip_entity.dart';

/// Панель обрезки выбранного клипа: RangeSlider двигает trimStart/trimEnd
/// внутри исходного файла, кнопка "Разделить" режет клип в текущей
/// середине выбранного диапазона (см. комментарий в EditorController.splitClip
/// про упрощённую модель точки разделения на этом этапе MVP).
class TrimPanel extends StatelessWidget {
  final TimelineClipEntity clip;
  final void Function(int startMs) onTrimStart;
  final void Function(int endMs) onTrimEnd;
  final VoidCallback onSplit;
  final VoidCallback onClose;

  const TrimPanel({
    super.key,
    required this.clip,
    required this.onTrimStart,
    required this.onTrimEnd,
    required this.onSplit,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final maxMs = clip.sourceDurationMs.toDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSizes.md, AppSizes.md, AppSizes.md, AppSizes.lg),
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Обрезка клипа', style: AppTextStyles.h3)),
              IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            '${(clip.trimStartMs / 1000).toStringAsFixed(1)}с — '
            '${(clip.trimEndMs / 1000).toStringAsFixed(1)}с '
            '(итого ${(clip.durationMs / 1000).toStringAsFixed(1)}с)',
            style: AppTextStyles.bodySecondary,
          ),
          RangeSlider(
            min: 0,
            max: maxMs,
            values: RangeValues(
              clip.trimStartMs.toDouble().clamp(0, maxMs),
              clip.trimEndMs.toDouble().clamp(0, maxMs),
            ),
            activeColor: AppColors.accent,
            inactiveColor: AppColors.divider,
            onChanged: (values) {
              onTrimStart(values.start.round());
              onTrimEnd(values.end.round());
            },
          ),
          const SizedBox(height: AppSizes.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSplit,
                  icon: const Icon(Icons.call_split, size: 18),
                  label: const Text('Разделить пополам'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
