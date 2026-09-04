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
import '../widgets/edit_tools_sheet.dart';
import '../widgets/text_editor_panel.dart';
import '../widgets/timeline_track.dart';
import '../widgets/trim_panel.dart';

/// Экран редактора — верстка повторяет референсный макет: тёмная шапка
/// (закрыть / поиск / AI UHD / Экспорт), окно предпросмотра со встроенной
/// перемоткой/play-pause (см. CanvasStage), таймлайн, нижний тулбар.
class EditorPage extends ConsumerStatefulWidget {
  final String projectId;

  const EditorPage({super.key, required this.projectId});

  @override
  ConsumerState<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends ConsumerState<EditorPage> {
  final _mediaImport = MediaImportService();
  bool _isImporting = false;

  void _soon() => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Скоро')));

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
      final media = choice == ClipType.photo ? await _mediaImport.pickPhoto() : await _mediaImport.pickVideo();
      if (media == null) return;

      await ref.read(editorControllerProvider(params).notifier).addMediaClip(
            file: media.file,
            type: media.type,
            sourceDurationMs: media.durationMs,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Не удалось импортировать файл: $e')));
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  void _openEditTools(BuildContext context, EditorControllerParams params, String clipId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer(
          builder: (ctx, ref, _) {
            final state = ref.watch(editorControllerProvider(params));
            final clip = state.timeline.clips.firstWhereOrNull((c) => c.id == clipId);
            if (clip == null) return const SizedBox.shrink();

            final controller = ref.read(editorControllerProvider(params).notifier);
            return EditToolsSheet(
              clip: clip,
              onSplit: controller.splitSelectedClipAtPlayhead,
              onVolumeChanged: (v) => controller.setClipVolume(clipId, v),
              onDelete: () => controller.removeClip(clipId),
              onSpeedChanged: (s) => controller.setClipSpeed(clipId, s),
              onSoon: _soon,
              onClose: () => Navigator.pop(ctx),
            );
          },
        );
      },
    );
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
            final clip = state.timeline.clips.firstWhereOrNull((c) => c.id == clipId);
            if (clip == null) return const SizedBox.shrink();

            final controller = ref.read(editorControllerProvider(params).notifier);
            return TrimPanel(
              clip: clip,
              onTrimStart: (ms) => controller.trimClipStart(clipId, ms),
              onTrimEnd: (ms) => controller.trimClipEnd(clipId, ms),
              onSplit: () {
                controller.splitSelectedClipAtPlayhead();
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
            final overlay = state.timeline.textOverlays.firstWhereOrNull((t) => t.id == textId);
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
    final clip = state.timeline.clips.firstWhereOrNull((c) => c.id == clipId);
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
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
    }

    final params = EditorControllerParams(projectId: widget.projectId, ownerId: userId);
    final state = ref.watch(editorControllerProvider(params));
    final controller = ref.read(editorControllerProvider(params).notifier);

    final projects = ref.watch(userProjectsProvider).value ?? [];
    final project = projects.firstWhereOrNull((p) => p.id == widget.projectId);
    final format = project?.format ?? ProjectFormat.ratio9x16;

    if (state.isLoading) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
    }

    final clips = state.timeline.clips;
    final currentClip = clips.isEmpty ? null : clips[state.playheadClipIndex.clamp(0, clips.length - 1)];
    final selectedClip = state.selectedType == SelectedElementType.clip
        ? state.timeline.clips.firstWhereOrNull((c) => c.id == state.selectedId)
        : null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              isSaving: state.isSaving,
              hasClips: clips.isNotEmpty,
              onClose: () => context.go(RouteNames.home),
              onSoon: _soon,
              onExport: () => context.push('${RouteNames.export}/${widget.projectId}'),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: CanvasStage(params: params, format: format),
              ),
            ),
            _PlaybackRow(
              canUndo: state.canUndo,
              canRedo: state.canRedo,
              onUndo: controller.undo,
              onRedo: controller.redo,
              onSoon: _soon,
              currentClipMuted: currentClip?.isMuted ?? false,
              hasVideoClip: currentClip?.type == ClipType.video,
              onToggleMute: currentClip == null ? null : () => controller.toggleClipMute(currentClip.id),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              decoration: BoxDecoration(color: const Color(0xFF141414), borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
              child: Column(
                children: [
                  SizedBox(
                    height: AppSizes.timelineHeight,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _isImporting
                              ? const Center(child: CircularProgressIndicator())
                              : TimelineTrack(
                                  clips: clips,
                                  selectedClipId: selectedClip?.id,
                                  playheadClipIndex: state.playheadClipIndex,
                                  onSelectClip: (id) {
                                    controller.selectClip(id);
                                    final index = clips.indexWhere((c) => c.id == id);
                                    if (index != -1) controller.setPlayheadClipIndex(index);
                                  },
                                  onDeleteClip: controller.removeClip,
                                  onReorder: controller.reorderClips,
                                ),
                        ),
                        _AddClipButton(onTap: () => _handleAddMedia(params)),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.music_note_outlined, color: AppColors.textSecondary, size: 20),
                    title: const Text('Добавить аудио', style: TextStyle(color: AppColors.textSecondary)),
                    subtitle: const Text('Скоро — своя дорожка со звуком', style: TextStyle(fontSize: 11)),
                    onTap: _soon,
                  ),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.title, color: AppColors.textSecondary, size: 20),
                    title: const Text('Добавить текст', style: TextStyle(color: AppColors.textSecondary)),
                    onTap: controller.addText,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            _BottomToolbar(
              onEdit: selectedClip == null ? _soon : () => _openEditTools(context, params, selectedClip.id),
              onCrop: selectedClip == null ? _soon : () => _openCropTool(params, selectedClip.id),
              onTrim: selectedClip == null || selectedClip.type != ClipType.video
                  ? _soon
                  : () => _openTrimPanel(context, params, selectedClip.id),
              onText: () {
                if (state.selectedType == SelectedElementType.text && state.selectedId != null) {
                  _openTextPanel(context, params, state.selectedId!);
                } else {
                  controller.addText();
                  final newId = ref.read(editorControllerProvider(params)).selectedId;
                  if (newId != null) _openTextPanel(context, params, newId);
                }
              },
              onEffects: _soon,
              onOverlay: _soon,
              onSubtitles: _soon,
              onGenerate: _soon,
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final bool isSaving;
  final bool hasClips;
  final VoidCallback onClose;
  final VoidCallback onSoon;
  final VoidCallback onExport;

  const _TopBar({
    required this.isSaving,
    required this.hasClips,
    required this.onClose,
    required this.onSoon,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: AppSizes.xs),
      child: Row(
        children: [
          IconButton(onPressed: onClose, icon: const Icon(Icons.close, color: Colors.white)),
          IconButton(onPressed: onSoon, icon: const Icon(Icons.search, color: Colors.white70)),
          if (isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.sm),
              child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54)),
            ),
          const Spacer(),
          TextButton(
            onPressed: onSoon,
            style: TextButton.styleFrom(backgroundColor: const Color(0xFF232323)),
            child: const Text('AI UHD', style: TextStyle(color: Colors.white70)),
          ),
          const SizedBox(width: AppSizes.xs),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: hasClips ? AppColors.accent : AppColors.textDisabled, minimumSize: const Size(0, 36)),
            onPressed: hasClips ? onExport : null,
            child: const Text('Экспорт'),
          ),
        ],
      ),
    );
  }
}

/// Строка над таймлайном: полноэкранный режим (заглушка), undo/redo
/// (реальные, зависят от истории EditorController) и быстрый тумблер
/// звука текущего клипа (реальный — заменил собой декоративные
/// "Обложка"/"ИИ-обработка" из прошлой версии).
class _PlaybackRow extends StatelessWidget {
  final bool canUndo;
  final bool canRedo;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onSoon;
  final bool currentClipMuted;
  final bool hasVideoClip;
  final VoidCallback? onToggleMute;

  const _PlaybackRow({
    required this.canUndo,
    required this.canRedo,
    required this.onUndo,
    required this.onRedo,
    required this.onSoon,
    required this.currentClipMuted,
    required this.hasVideoClip,
    required this.onToggleMute,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.xs),
      child: Row(
        children: [
          IconButton(onPressed: onSoon, icon: const Icon(Icons.fullscreen, color: Colors.white70, size: 20)),
          IconButton(
            onPressed: hasVideoClip ? onToggleMute : null,
            icon: Icon(
              currentClipMuted ? Icons.volume_off : Icons.volume_up,
              color: hasVideoClip ? Colors.white70 : Colors.white24,
              size: 20,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: canUndo ? onUndo : null,
            icon: Icon(Icons.undo, color: canUndo ? Colors.white : Colors.white24, size: 20),
          ),
          IconButton(
            onPressed: canRedo ? onRedo : null,
            icon: Icon(Icons.redo, color: canRedo ? Colors.white : Colors.white24, size: 20),
          ),
        ],
      ),
    );
  }
}

class _AddClipButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddClipButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.xs),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        child: Container(
          width: 40,
          decoration: BoxDecoration(color: const Color(0xFF232323), borderRadius: BorderRadius.circular(AppSizes.radiusSm)),
          child: const Icon(Icons.add, color: Colors.white70),
        ),
      ),
    );
  }
}

class _BottomToolbar extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onCrop;
  final VoidCallback onTrim;
  final VoidCallback onText;
  final VoidCallback onEffects;
  final VoidCallback onOverlay;
  final VoidCallback onSubtitles;
  final VoidCallback onGenerate;

  const _BottomToolbar({
    required this.onEdit,
    required this.onCrop,
    required this.onTrim,
    required this.onText,
    required this.onEffects,
    required this.onOverlay,
    required this.onSubtitles,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (icon: Icons.content_cut, label: 'Изменить', onTap: onEdit),
      (icon: Icons.crop, label: 'Кадрирование', onTap: onCrop),
      (icon: Icons.timelapse, label: 'Обрезка', onTap: onTrim),
      (icon: Icons.title, label: 'Текст', onTap: onText),
      (icon: Icons.auto_awesome_outlined, label: 'Эффекты', onTap: onEffects),
      (icon: Icons.image_outlined, label: 'Наложение', onTap: onOverlay),
      (icon: Icons.subtitles_outlined, label: 'Субтитры', onTap: onSubtitles),
      (icon: Icons.smart_toy_outlined, label: 'Ген. медиа', onTap: onGenerate),
    ];

    return SizedBox(
      height: AppSizes.bottomToolbarHeight,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
        children: items
            .map((item) => InkWell(
                  onTap: item.onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: AppSizes.xs),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(item.icon, color: Colors.white70, size: 22),
                        const SizedBox(height: 4),
                        Text(item.label, style: const TextStyle(fontSize: 11, color: Colors.white54)),
                      ],
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
