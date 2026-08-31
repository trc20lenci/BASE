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
import '../widgets/text_editor_panel.dart';
import '../widgets/timeline_track.dart';
import '../widgets/trim_panel.dart';

/// Экран редактора — верстка повторяет референсный макет: тёмная шапка
/// (закрыть / поиск / промо-плашка / качество / Экспорт), окно
/// предпросмотра, таймлайн с колонкой быстрых иконок слева и дорожками
/// аудио/текста, нижний тулбар инструментов.
///
/// Функционал (движок редактирования — EditorController/CanvasStage) не
/// менялся, переработана только "обвязка" — расположение элементов и
/// набор иконок, чтобы совпадать с макетом.
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

  void _openEditTools(BuildContext context, EditorControllerParams params, String clipId, bool isVideo) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isVideo)
                ListTile(
                  leading: const Icon(Icons.content_cut),
                  title: const Text('Обрезка / разделение'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openTrimPanel(context, params, clipId);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.crop),
                title: const Text('Кадрирование'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _openCropTool(params, clipId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('Удалить клип', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(editorControllerProvider(params).notifier).removeClip(clipId);
                },
              ),
            ],
          ),
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
              hasClips: state.timeline.clips.isNotEmpty,
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
            _PlaybackRow(onSoon: _soon),
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
                        _QuickTimelineIcons(onSoon: _soon),
                        Expanded(
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
                        _AddClipButton(onTap: () => _handleAddMedia(params)),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.music_note_outlined, color: AppColors.textSecondary, size: 20),
                    title: const Text('Добавить аудио', style: TextStyle(color: AppColors.textSecondary)),
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
              onEdit: selectedClip == null
                  ? _soon
                  : () => _openEditTools(context, params, selectedClip.id, selectedClip.type == ClipType.video),
              onSound: _soon,
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

class _PlaybackRow extends StatelessWidget {
  final VoidCallback onSoon;

  const _PlaybackRow({required this.onSoon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.xs),
      child: Row(
        children: [
          IconButton(onPressed: onSoon, icon: const Icon(Icons.fullscreen, color: Colors.white70, size: 20)),
          const Spacer(),
          IconButton(onPressed: onSoon, icon: const Icon(Icons.play_arrow, color: Colors.white, size: 28)),
          const Spacer(),
          IconButton(onPressed: onSoon, icon: const Icon(Icons.undo, color: Colors.white70, size: 20)),
          IconButton(onPressed: onSoon, icon: const Icon(Icons.redo, color: Colors.white70, size: 20)),
        ],
      ),
    );
  }
}

class _QuickTimelineIcons extends StatelessWidget {
  final VoidCallback onSoon;

  const _QuickTimelineIcons({required this.onSoon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
      decoration: const BoxDecoration(border: Border(right: BorderSide(color: AppColors.divider))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _MiniIcon(icon: Icons.volume_off_outlined, label: 'Звук клипа', onTap: onSoon),
          _MiniIcon(icon: Icons.auto_fix_high, label: 'ИИ-обрезка', onTap: onSoon),
          _MiniIcon(icon: Icons.edit_note, label: 'Обложка', onTap: onSoon),
        ],
      ),
    );
  }
}

class _MiniIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MiniIcon({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white54, size: 16),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 8, color: Colors.white38), textAlign: TextAlign.center),
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
  final VoidCallback onSound;
  final VoidCallback onText;
  final VoidCallback onEffects;
  final VoidCallback onOverlay;
  final VoidCallback onSubtitles;
  final VoidCallback onGenerate;

  const _BottomToolbar({
    required this.onEdit,
    required this.onSound,
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
      (icon: Icons.music_note_outlined, label: 'Звук', onTap: onSound),
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
