import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/routing/route_names.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../project/domain/entities/project_format.dart';
import '../../../project/presentation/providers/project_providers.dart';
import '../../domain/entities/clip_type.dart';
import '../providers/editor_controller.dart';
import '../providers/editor_state.dart';
import '../services/media_import_service.dart';
import '../widgets/canvas_stage.dart';
import '../widgets/crop_tool.dart';
import '../widgets/editor_toolbar.dart';
import '../widgets/text_editor_panel.dart';
import '../widgets/timeline_track.dart';
import '../widgets/trim_panel.dart';

/// Экран редактора — собирает воедино холст предпросмотра, таймлайн и
/// панель инструментов. Вся бизнес-логика вынесена в EditorController;
/// этот виджет отвечает только за композицию UI и открытие панелей
/// (обрезка/текст/кадрирование) в ответ на действия пользователя.
class EditorPage extends ConsumerStatefulWidget {
  final String projectId;

  const EditorPage({super.key, required this.projectId});

  @override
  ConsumerState<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends ConsumerState<EditorPage> {
  final _mediaImport = MediaImportService();
  bool _isImporting = false;

  Future<void> _handleAddMedia(EditorControllerParams params) async {
    final choice = await showModalBottomSheet<ClipType>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Фото из галереи'),
              onTap: () => Navigator.pop(ctx, ClipType.photo),
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: const Text('Видео из галереи'),
              onTap: () => Navigator.pop(ctx, ClipType.video),
            ),
          ],
        ),
      ),
    );
    if (choice == null) return;

    setState(() => _isImporting = true);
    try {
      final media = choice == ClipType.photo
          ? await _mediaImport.pickPhoto()
          : await _mediaImport.pickVideo();
      if (media == null) return;

      await ref.read(editorControllerProvider(params).notifier).addMediaClip(
            file: media.file,
            type: media.type,
            sourceDurationMs: media.durationMs,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Не удалось импортировать файл: $e')));
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  void _openTrimPanel(BuildContext context, EditorControllerParams params, String clipId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Consumer(
          builder: (ctx, ref, _) {
            final state = ref.watch(editorControllerProvider(params));
            final clip = state.timeline.clips.where((c) => c.id == clipId).firstOrNull;
            if (clip == null) return const SizedBox.shrink();

            final controller = ref.read(editorControllerProvider(params).notifier);
            return TrimPanel(
              clip: clip,
              onTrimStart: (ms) => controller.trimClipStart(clipId, ms),
              onTrimEnd: (ms) => controller.trimClipEnd(clipId, ms),
              onSplit: () {
                final midpoint = (clip.trimStartMs + clip.trimEndMs) ~/ 2;
                controller.splitClip(clipId, midpoint);
                Navigator.pop(ctx);
              },
              onClose: () => Navigator.pop(ctx),
            );
          },
        );
      },
    );
  }

  void _openTextPanel(BuildContext context, EditorControllerParams params, String textId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Consumer(
          builder: (ctx, ref, _) {
            final state = ref.watch(editorControllerProvider(params));
            final overlay = state.timeline.textOverlays.where((t) => t.id == textId).firstOrNull;
            if (overlay == null) return const SizedBox.shrink();

            final controller = ref.read(editorControllerProvider(params).notifier);
            return TextEditorPanel(
              overlay: overlay,
              onChanged: ({text, fontSize, color}) =>
                  controller.updateText(textId, text: text, fontSize: fontSize, color: color),
              onDelete: () {
                controller.deleteText(textId);
                Navigator.pop(ctx);
              },
              onClose: () => Navigator.pop(ctx),
            );
          },
        );
      },
    );
  }

  Future<void> _openCropTool(EditorControllerParams params, String clipId) async {
    final state = ref.read(editorControllerProvider(params));
    final clip = state.timeline.clips.where((c) => c.id == clipId).firstOrNull;
    if (clip == null) return;

    final result = await CropTool.show(context, clip);
    if (result != null) {
      ref.read(editorControllerProvider(params).notifier).updateClipTransform(clipId, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateChangesProvider);
    final userId = authState.value?.id;

    if (userId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final params = EditorControllerParams(projectId: widget.projectId, ownerId: userId);
    final state = ref.watch(editorControllerProvider(params));
    final controller = ref.read(editorControllerProvider(params).notifier);

    // Формат проекта нужен холсту для соотношения сторон — берём из уже
    // загруженного списка проектов на Home (не делаем отдельный запрос).
    final projects = ref.watch(userProjectsProvider).value ?? [];
    final project = projects.where((p) => p.id == widget.projectId).firstOrNull;
    final format = project?.format ?? ProjectFormat.ratio9x16;

    if (state.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final selectedClip = state.selectedType == SelectedElementType.clip
        ? state.timeline.clips.where((c) => c.id == state.selectedId).firstOrNull
        : null;
    final isVideoSelected = selectedClip?.type == ClipType.video;
    final isClipSelected = selectedClip != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(project?.title ?? 'Редактор'),
        actions: [
          if (state.isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.md),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          TextButton(
            onPressed: state.timeline.clips.isEmpty
                ? null
                : () => context.push('${RouteNames.export}/${widget.projectId}'),
            child: const Text('Экспорт'),
          ),
          const SizedBox(width: AppSizes.sm),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: CanvasStage(params: params, format: format),
            ),
          ),
          Container(
            height: AppSizes.timelineHeight,
            margin: const EdgeInsets.symmetric(horizontal: AppSizes.md),
            decoration: BoxDecoration(
              color: AppColors.timelineTrack,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: _isImporting
                ? const Center(child: CircularProgressIndicator())
                : TimelineTrack(
                    clips: state.timeline.clips,
                    selectedClipId: selectedClip?.id,
                    playheadClipIndex: state.playheadClipIndex,
                    onSelectClip: (id) {
                      controller.selectClip(id);
                      final index = state.timeline.clips.indexWhere((c) => c.id == id);
                      if (index != -1) controller.setPlayheadClipIndex(index);
                    },
                    onDeleteClip: controller.removeClip,
                    onReorder: controller.reorderClips,
                  ),
          ),
          const SizedBox(height: AppSizes.sm),
          EditorToolbar(
            actions: [
              ToolbarAction(
                icon: Icons.add_photo_alternate_outlined,
                label: 'Добавить',
                onTap: () => _handleAddMedia(params),
              ),
              ToolbarAction(
                icon: Icons.content_cut,
                label: 'Обрезка',
                onTap: isVideoSelected
                    ? () => _openTrimPanel(context, params, selectedClip.id)
                    : null,
              ),
              ToolbarAction(
                icon: Icons.crop,
                label: 'Кадрирование',
                onTap: isClipSelected ? () => _openCropTool(params, selectedClip.id) : null,
              ),
              ToolbarAction(
                icon: Icons.text_fields,
                label: 'Текст',
                onTap: controller.addText,
              ),
              ToolbarAction(
                icon: Icons.edit_outlined,
                label: 'Изменить текст',
                onTap: state.selectedType == SelectedElementType.text
                    ? () => _openTextPanel(context, params, state.selectedId!)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
