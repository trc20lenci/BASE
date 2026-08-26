import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/base_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../project/domain/entities/project_entity.dart';
import '../../../project/presentation/providers/project_providers.dart';
import '../widgets/project_card.dart';

/// Главный экран: аватар, имя пользователя, список проектов и кнопка
/// "Создать проект". Действия карточки (переименовать/удалить/
/// дублировать) обрабатываются здесь через диалоги подтверждения.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    ProjectEntity project,
    ProjectCardAction action,
  ) async {
    switch (action) {
      case ProjectCardAction.open:
        context.push('${RouteNames.editor}/${project.id}');
        break;

      case ProjectCardAction.rename:
        final controller = TextEditingController(text: project.title);
        final newTitle = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surfaceElevated,
            title: const Text('Переименовать проект'),
            content: TextField(controller: controller, autofocus: true),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                child: const Text('Сохранить'),
              ),
            ],
          ),
        );
        if (newTitle != null && newTitle.isNotEmpty && newTitle != project.title) {
          await ref.read(renameProjectUseCaseProvider).call(
                projectId: project.id,
                newTitle: newTitle,
              );
        }
        break;

      case ProjectCardAction.delete:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surfaceElevated,
            title: const Text('Удалить проект?'),
            content: Text('«${project.title}» будет удалён без возможности восстановления.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Удалить', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await ref.read(deleteProjectUseCaseProvider).call(project.id);
        }
        break;

      case ProjectCardAction.duplicate:
        await ref.read(duplicateProjectUseCaseProvider).call(project);
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);
    final projectsState = ref.watch(userProjectsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.lg, AppSizes.md, AppSizes.lg, AppSizes.sm),
              child: Row(
                children: [
                  authState.when(
                    data: (user) => BaseAvatar(
                      avatarUrl: user?.avatarUrl ?? '',
                      size: AppSizes.avatarSizeSmall,
                      onTap: () => context.push(RouteNames.profile),
                    ),
                    loading: () => const SizedBox(
                        width: AppSizes.avatarSizeSmall, height: AppSizes.avatarSizeSmall),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: authState.when(
                      data: (user) => Text(
                        user?.username.isNotEmpty == true
                            ? user!.username
                            : (user?.email ?? ''),
                        style: AppTextStyles.h3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.push(RouteNames.profile),
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ],
              ),
            ),
            Expanded(
              child: projectsState.when(
                data: (projects) {
                  if (projects.isEmpty) {
                    return _EmptyState(
                      onCreate: () => context.push(RouteNames.createProject),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                        AppSizes.lg, AppSizes.sm, AppSizes.lg, AppSizes.xxl),
                    itemCount: projects.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
                    itemBuilder: (context, index) {
                      final project = projects[index];
                      return ProjectCard(
                        project: project,
                        onAction: (action) => _handleAction(context, ref, project, action),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Ошибка загрузки проектов: $e')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.createProject),
        icon: const Icon(Icons.add),
        label: const Text('Создать проект'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.video_library_outlined,
                color: AppColors.textDisabled, size: 48),
            const SizedBox(height: AppSizes.md),
            Text('Пока нет проектов', style: AppTextStyles.h3),
            const SizedBox(height: AppSizes.xs),
            Text(
              'Создайте первый проект, чтобы начать монтаж',
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.lg),
            ElevatedButton(onPressed: onCreate, child: const Text('Создать проект')),
          ],
        ),
      ),
    );
  }
}
