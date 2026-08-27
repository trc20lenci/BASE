import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/editor_text_style_constants.dart';
import '../../domain/entities/text_overlay_entity.dart';

/// Панель редактирования текста: содержимое, размер, цвет.
/// Перемещение текста происходит прямо на холсте (drag), поэтому здесь
/// не дублируется.
class TextEditorPanel extends StatefulWidget {
  final TextOverlayEntity overlay;
  final void Function({String? text, double? fontSize, Color? color}) onChanged;
  final VoidCallback onDelete;
  final VoidCallback onClose;

  const TextEditorPanel({
    super.key,
    required this.overlay,
    required this.onChanged,
    required this.onDelete,
    required this.onClose,
  });

  @override
  State<TextEditorPanel> createState() => _TextEditorPanelState();
}

class _TextEditorPanelState extends State<TextEditorPanel> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.overlay.text);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.overlay;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSizes.md,
        AppSizes.md,
        AppSizes.md,
        AppSizes.lg + MediaQuery.of(context).viewInsets.bottom,
      ),
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
              Expanded(child: Text('Текст', style: AppTextStyles.h3)),
              IconButton(
                onPressed: widget.onDelete,
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
              ),
              IconButton(onPressed: widget.onClose, icon: const Icon(Icons.check)),
            ],
          ),
          TextField(
            controller: _controller,
            autofocus: true,
            style: AppTextStyles.body,
            decoration: const InputDecoration(hintText: 'Введите текст'),
            onChanged: (value) => widget.onChanged(text: value),
          ),
          const SizedBox(height: AppSizes.md),
          Text('Размер', style: AppTextStyles.bodySecondary),
          Slider(
            min: 12,
            max: 72,
            value: o.fontSize.clamp(12, 72),
            activeColor: AppColors.accent,
            onChanged: (value) => widget.onChanged(fontSize: value),
          ),
          const SizedBox(height: AppSizes.xs),
          Text('Цвет', style: AppTextStyles.bodySecondary),
          const SizedBox(height: AppSizes.sm),
          Wrap(
            spacing: AppSizes.sm,
            children: EditorTextStyleConstants.colorSwatches.map((color) {
              final isSelected = color.value == o.color.value;
              return GestureDetector(
                onTap: () => widget.onChanged(color: color),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.accent : AppColors.divider,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
