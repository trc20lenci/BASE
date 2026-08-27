import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';

class ToolbarAction {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const ToolbarAction({required this.icon, required this.label, required this.onTap});
}

/// Горизонтальная панель инструментов редактора. Неактивные инструменты
/// (onTap == null, например "Обрезка" без выбранного видео-клипа)
/// показываются приглушённым цветом, но не скрываются — так пользователь
/// видит весь набор возможностей редактора.
class EditorToolbar extends StatelessWidget {
  final List<ToolbarAction> actions;

  const EditorToolbar({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.bottomToolbarHeight,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
        children: actions.map((a) {
          final enabled = a.onTap != null;
          return InkWell(
            onTap: a.onTap,
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: AppSizes.xs),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    a.icon,
                    color: enabled ? AppColors.textPrimary : AppColors.textDisabled,
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    a.label,
                    style: AppTextStyles.caption.copyWith(
                      color: enabled ? AppColors.textSecondary : AppColors.textDisabled,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
