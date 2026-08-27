import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/clip_type.dart';
import '../../domain/entities/timeline_clip_entity.dart';

/// Дорожка таймлайна: поддерживает фото и видео, перемещение элементов
/// (drag & drop через ReorderableListView) и удаление (свайп/долгое
/// нажатие -> кнопка корзины).
class TimelineTrack extends StatelessWidget {
  final List<TimelineClipEntity> clips;
  final String? selectedClipId;
  final int playheadClipIndex;
  final ValueChanged<String> onSelectClip;
  final ValueChanged<String> onDeleteClip;
  final void Function(int oldIndex, int newIndex) onReorder;

  const TimelineTrack({
    super.key,
    required this.clips,
    required this.selectedClipId,
    required this.playheadClipIndex,
    required this.onSelectClip,
    required this.onDeleteClip,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    if (clips.isEmpty) {
      return Center(
        child: Text(
          'Добавьте фото или видео, чтобы начать монтаж',
          style: AppTextStyles.caption,
        ),
      );
    }

    return ReorderableListView.builder(
      scrollDirection: Axis.horizontal,
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: AppSizes.sm),
      itemCount: clips.length,
      onReorder: onReorder,
      itemBuilder: (context, index) {
        final clip = clips[index];
        return ReorderableDragStartListener(
          key: ValueKey(clip.id),
          index: index,
          child: Padding(
            padding: const EdgeInsets.only(right: AppSizes.xs),
            child: _ClipThumb(
              clip: clip,
              isSelected: clip.id == selectedClipId,
              isOnPlayhead: index == playheadClipIndex,
              onTap: () => onSelectClip(clip.id),
              onDelete: () => onDeleteClip(clip.id),
            ),
          ),
        );
      },
    );
  }
}

class _ClipThumb extends StatelessWidget {
  final TimelineClipEntity clip;
  final bool isSelected;
  final bool isOnPlayhead;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ClipThumb({
    required this.clip,
    required this.isSelected,
    required this.isOnPlayhead,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Ширина блока пропорциональна длительности клипа — так пользователь
    // видит относительную длину клипов на таймлайне, как в проф. редакторах.
    final width = (clip.durationMs / 200).clamp(56, 220).toDouble();

    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _confirmDelete(context),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: clip.type == ClipType.video
              ? AppColors.timelineClipVideo
              : AppColors.timelineClipPhoto,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          border: Border.all(
            color: isSelected
                ? AppColors.accent
                : (isOnPlayhead ? AppColors.textSecondary : Colors.transparent),
            width: isSelected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (clip.type == ClipType.photo && clip.localPath != null)
              Image.file(File(clip.localPath!), fit: BoxFit.cover, opacity: const AlwaysStoppedAnimation(0.6))
            else
              Center(
                child: Icon(
                  clip.type == ClipType.video ? Icons.videocam_outlined : Icons.image_outlined,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
            Positioned(
              left: 4,
              bottom: 4,
              child: Text(
                '${(clip.durationMs / 1000).toStringAsFixed(1)}с',
                style: AppTextStyles.caption.copyWith(color: Colors.white),
              ),
            ),
            if (!clip.isUploaded)
              const Positioned(
                right: 4,
                top: 4,
                child: Icon(Icons.cloud_upload_outlined, size: 14, color: Colors.white70),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Удалить клип?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) onDelete();
  }
}
