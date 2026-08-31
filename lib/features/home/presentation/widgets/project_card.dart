import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../project/domain/entities/project_entity.dart';

enum ProjectCardAction { open, rename, delete, duplicate }

/// Карточка проекта. Поддерживает список (по умолчанию) и сетку
/// ([isGrid]) — как в референсном макете, где есть переключатель вида.
class ProjectCard extends StatelessWidget {
  final ProjectEntity project;
  final ValueChanged<ProjectCardAction> onAction;
  final bool isGrid;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onAction,
    this.isGrid = false,
  });

  @override
  Widget build(BuildContext context) {
    return isGrid ? _buildGrid() : _buildList();
  }

  Widget _buildList() {
    final dateFormat = DateFormat('dd MMM', 'ru');

    return InkWell(
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      onTap: () => onAction(ProjectCardAction.open),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
        child: Row(
          children: [
            _Thumb(project: project, width: 64, height: 64),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(project.title, style: AppTextStyles.body, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.folder, size: 14, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text('По умолчанию', style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
            ),
            Text(dateFormat.format(project.updatedAt), style: AppTextStyles.caption),
            PopupMenuButton<ProjectCardAction>(
              icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
              color: AppColors.surfaceElevated,
              onSelected: onAction,
              itemBuilder: (_) => const [
                PopupMenuItem(value: ProjectCardAction.rename, child: Text('Переименовать')),
                PopupMenuItem(value: ProjectCardAction.duplicate, child: Text('Дублировать')),
                PopupMenuItem(value: ProjectCardAction.delete, child: Text('Удалить')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      onTap: () => onAction(ProjectCardAction.open),
      onLongPress: () => onAction(ProjectCardAction.delete),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _Thumb(project: project, width: double.infinity, height: double.infinity)),
          const SizedBox(height: AppSizes.xs),
          Text(project.title, style: AppTextStyles.body, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final ProjectEntity project;
  final double width;
  final double height;

  const _Thumb({required this.project, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: Stack(
        children: [
          const Center(child: Icon(Icons.movie_outlined, color: AppColors.textDisabled, size: 22)),
          Positioned(
            left: 6,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
              child: Text(project.format.label, style: AppTextStyles.caption.copyWith(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
