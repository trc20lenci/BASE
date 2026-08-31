import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/routing/route_names.dart';
import '../../../project/domain/entities/project_entity.dart';
import '../../../project/presentation/providers/project_providers.dart';
import '../widgets/project_card.dart';

/// Вкладка "Проекты" — главный экран приложения. Верстка повторяет
/// референсный макет: поиск, приветственный баннер, статус-таббар,
/// "Папки", секция "Проекты" со списком.
class ProjectsTabPage extends ConsumerStatefulWidget {
  const ProjectsTabPage({super.key});

  @override
  ConsumerState<ProjectsTabPage> createState() => _ProjectsTabPageState();
}

class _ProjectsTabPageState extends ConsumerState<ProjectsTabPage> {
  final _searchController = TextEditingController();
  bool _bannerDismissed = false;
  bool _isGridView = false;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleAction(ProjectEntity project, ProjectCardAction action) async {
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
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                child: const Text('Сохранить'),
              ),
            ],
          ),
        );
        if (newTitle != null && newTitle.isNotEmpty && newTitle != project.title) {
          await ref.read(renameProjectUseCaseProvider).call(projectId: project.id, newTitle: newTitle);
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
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
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
  Widget build(BuildContext context) {
    final projectsState = ref.watch(userProjectsProvider);

    return Scaffold(
      body: SafeArea(
        child: projectsState.when(
          data: (allProjects) {
            final projects = _query.isEmpty
                ? allProjects
                : allProjects
                    .where((p) => p.title.toLowerCase().contains(_query.toLowerCase()))
                    .toList();

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSizes.lg, AppSizes.md, AppSizes.lg, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Проекты', style: AppTextStyles.h1),
                            const Spacer(),
                            IconButton(
                              onPressed: () => _showSoon(context),
                              icon: const Icon(Icons.more_horiz),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.sm),
                        _SearchField(controller: _searchController, onChanged: (v) => setState(() => _query = v)),
                        if (!_bannerDismissed) ...[
                          const SizedBox(height: AppSizes.md),
                          _GettingStartedBanner(onClose: () => setState(() => _bannerDismissed = true)),
                        ],
                        const SizedBox(height: AppSizes.lg),
                        _StatusTabs(projectCount: allProjects.length),
                        const SizedBox(height: AppSizes.lg),
                        Text('Папки', style: AppTextStyles.h3),
                        const SizedBox(height: AppSizes.sm),
                        Row(
                          children: [
                            Expanded(
                              child: _FolderCard(
                                title: 'По умолчанию',
                                count: allProjects.length,
                                icon: Icons.layers_outlined,
                              ),
                            ),
                            const SizedBox(width: AppSizes.sm),
                            Expanded(
                              child: _FolderCard(
                                title: 'Импортировано',
                                count: 0,
                                icon: Icons.file_download_outlined,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.lg),
                        Row(
                          children: [
                            Text('Проекты (${projects.length})', style: AppTextStyles.h3),
                            const Spacer(),
                            TextButton(onPressed: () => _showSoon(context), child: const Text('Изменить')),
                            IconButton(
                              onPressed: () => setState(() => _isGridView = !_isGridView),
                              icon: Icon(_isGridView ? Icons.view_list_outlined : Icons.grid_view_outlined),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (projects.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(onCreate: () => context.push(RouteNames.createProject)),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(AppSizes.lg, AppSizes.sm, AppSizes.lg, 0),
                    sliver: SliverToBoxAdapter(
                      child: Text('ПОСЛЕДНИЕ 30 ДНЕЙ', style: AppTextStyles.caption),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(AppSizes.lg, AppSizes.sm, AppSizes.lg, 100),
                    sliver: _isGridView
                        ? SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: AppSizes.sm,
                              crossAxisSpacing: AppSizes.sm,
                              childAspectRatio: 0.85,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => ProjectCard(
                                project: projects[index],
                                isGrid: true,
                                onAction: (action) => _handleAction(projects[index], action),
                              ),
                              childCount: projects.length,
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => Padding(
                                padding: const EdgeInsets.only(bottom: AppSizes.sm),
                                child: ProjectCard(
                                  project: projects[index],
                                  onAction: (action) => _handleAction(projects[index], action),
                                ),
                              ),
                              childCount: projects.length,
                            ),
                          ),
                  ),
                ],
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Ошибка загрузки проектов: $e')),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(RouteNames.createProject),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Скоро')));
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: AppTextStyles.body,
      decoration: InputDecoration(
        hintText: 'Поиск',
        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd), borderSide: BorderSide.none),
      ),
    );
  }
}

class _GettingStartedBanner extends StatelessWidget {
  final VoidCallback onClose;

  const _GettingStartedBanner({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2B5CE0), Color(0xFF5B8CFF)]),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.movie_filter_outlined, color: Colors.white, size: 28),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Быстрый старт', style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                Text('Краткий гайд, чтобы начать', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.accent),
            onPressed: onClose,
            child: const Text('Понятно'),
          ),
          IconButton(onPressed: onClose, icon: const Icon(Icons.close, color: Colors.white70, size: 18)),
        ],
      ),
    );
  }
}

class _StatusTabs extends StatelessWidget {
  final int projectCount;

  const _StatusTabs({required this.projectCount});

  @override
  Widget build(BuildContext context) {
    final tabs = [
      ('Проект $projectCount', true),
      ('Работает 0', false),
      ('Шаблоны 0', false),
      ('Бит-клипы 0', false),
    ];
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSizes.lg),
        itemBuilder: (context, index) {
          final (label, active) = tabs[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.body.copyWith(
                  color: active ? AppColors.textPrimary : AppColors.textDisabled,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
              const SizedBox(height: 4),
              if (active) Container(width: 20, height: 3, color: AppColors.textPrimary),
            ],
          );
        },
      ),
    );
  }
}

class _FolderCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;

  const _FolderCard({required this.title, required this.count, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accent, size: 28),
          const SizedBox(height: AppSizes.sm),
          Text(title, style: AppTextStyles.body, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('$count Элементы', style: AppTextStyles.caption),
        ],
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
            const Icon(Icons.video_library_outlined, color: AppColors.textDisabled, size: 48),
            const SizedBox(height: AppSizes.md),
            Text('Пока нет проектов', style: AppTextStyles.h3),
            const SizedBox(height: AppSizes.xs),
            Text('Создайте первый проект, чтобы начать монтаж', style: AppTextStyles.bodySecondary, textAlign: TextAlign.center),
            const SizedBox(height: AppSizes.lg),
            ElevatedButton(onPressed: onCreate, child: const Text('Создать проект')),
          ],
        ),
      ),
    );
  }
}
