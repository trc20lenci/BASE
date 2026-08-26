import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../project/domain/entities/project_entity.dart';

enum ProjectCardAction { open, rename, delete, duplicate }

/// Карточка проекта в списке на Home.
/// Даёт доступ к переименованию/удалению/дублированию через меню (long
/// press или иконку "..."), а тап по карточке открывает редактор.
class ProjectCard extends StatelessWidget {
  final ProjectEntity project;
  final ValueChanged<ProjectCardAction> onAction;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy, HH:mm');

    return InkWell(
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      onTap: () => onAction(ProjectCardAction.open),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            AspectRatio(
              aspectRatio: project.format.aspectRatio,
              child: Container(
                width: 56,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: const Icon(Icons.movie_outlined,
                    color: AppColors.textDisabled, size: 20),
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title,
                    style: AppTextStyles.body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${project.format.label} · Изменён ${dateFormat.format(project.updatedAt)}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            PopupMenuButton<ProjectCardAction>(
              icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
              color: AppColors.surfaceElevated,
              onSelected: onAction,
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: ProjectCardAction.rename,
                  child: Text('Переименовать'),
                ),
                PopupMenuItem(
                  value: ProjectCardAction.duplicate,
                  child: Text('Дублировать'),
                ),
                PopupMenuItem(
                  value: ProjectCardAction.delete,
                  child: Text('Удалить'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
