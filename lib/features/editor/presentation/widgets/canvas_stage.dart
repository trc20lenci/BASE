import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../project/domain/entities/project_format.dart';
import '../../domain/entities/canvas_transform.dart';
import '../../domain/entities/clip_type.dart';
import '../../domain/entities/editor_text_style_constants.dart';
import '../../domain/entities/text_overlay_entity.dart';
import '../../domain/entities/timeline_clip_entity.dart';
import '../providers/editor_controller.dart';
import '../providers/editor_state.dart';

/// Окно предпросмотра ("холст"). Показывает результат монтажа в реальном
/// времени: текущий клип (фото/видео) + все текстовые слои поверх него.
///
/// Жесты на выбранном элементе (клип или текст) сразу обновляют
/// [CanvasTransform]/позицию через контроллер — "все изменения
/// отображаются сразу", как требует ТЗ.
class CanvasStage extends ConsumerStatefulWidget {
  final EditorControllerParams params;
  final ProjectFormat format;

  const CanvasStage({super.key, required this.params, required this.format});

  @override
  ConsumerState<CanvasStage> createState() => _CanvasStageState();
}

class _CanvasStageState extends ConsumerState<CanvasStage> {
  VideoPlayerController? _videoController;
  String? _videoControllerForClipId;

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _ensureVideoController(TimelineClipEntity? clip) {
    if (clip == null || clip.type != ClipType.video || clip.displayPath == null) {
      if (_videoController != null) {
        _videoController!.dispose();
        _videoController = null;
        _videoControllerForClipId = null;
      }
      return;
    }

    if (_videoControllerForClipId == clip.id) return; // уже инициализирован

    _videoController?.dispose();
    _videoControllerForClipId = clip.id;

    final path = clip.localPath;
    final controller = path != null
        ? VideoPlayerController.file(File(path))
        : VideoPlayerController.networkUrl(Uri.parse(clip.remoteUrl!));

    _videoController = controller
      ..initialize().then((_) {
        if (mounted) setState(() {});
        controller.setLooping(true);
        controller.play();
      });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorControllerProvider(widget.params));
    final controller = ref.read(editorControllerProvider(widget.params).notifier);

    final clips = state.timeline.clips;
    final currentClip =
        clips.isEmpty ? null : clips[state.playheadClipIndex.clamp(0, clips.length - 1)];

    _ensureVideoController(currentClip);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;
        final aspect = widget.format.aspectRatio;

        double canvasWidth = maxWidth;
        double canvasHeight = canvasWidth / aspect;
        if (canvasHeight > maxHeight) {
          canvasHeight = maxHeight;
          canvasWidth = canvasHeight * aspect;
        }

        return Center(
          child: GestureDetector(
            onTap: controller.clearSelection,
            child: Container(
              width: canvasWidth,
              height: canvasHeight,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (currentClip != null)
                    _ClipLayer(
                      key: ValueKey(currentClip.id),
                      clip: currentClip,
                      videoController:
                          currentClip.type == ClipType.video ? _videoController : null,
                      isSelected: state.selectedType == SelectedElementType.clip &&
                          state.selectedId == currentClip.id,
                      canvasSize: Size(canvasWidth, canvasHeight),
                      onTap: () => controller.selectClip(currentClip.id),
                      onTransformChanged: (t) =>
                          controller.updateClipTransform(currentClip.id, t),
                    )
                  else
                    const Center(
                      child: Icon(Icons.movie_creation_outlined,
                          color: AppColors.textDisabled, size: 40),
                    ),
                  for (final overlay in state.timeline.textOverlays)
                    _TextLayer(
                      key: ValueKey(overlay.id),
                      overlay: overlay,
                      isSelected: state.selectedType == SelectedElementType.text &&
                          state.selectedId == overlay.id,
                      canvasSize: Size(canvasWidth, canvasHeight),
                      onTap: () => controller.selectText(overlay.id),
                      onMoved: (dx, dy) =>
                          controller.updateText(overlay.id, dx: dx, dy: dy),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Слой клипа (фото/видео) с поддержкой перемещения/масштаба/поворота
/// одним жестом (стандарт мобильных редакторов: 1 палец — перемещение,
/// 2 пальца — одновременно масштаб + поворот) и кадрированием через
/// ClipRect по CanvasTransform.crop*.
class _ClipLayer extends StatefulWidget {
  final TimelineClipEntity clip;
  final VideoPlayerController? videoController;
  final bool isSelected;
  final Size canvasSize;
  final VoidCallback onTap;
  final ValueChanged<CanvasTransform> onTransformChanged;

  const _ClipLayer({
    super.key,
    required this.clip,
    required this.videoController,
    required this.isSelected,
    required this.canvasSize,
    required this.onTap,
    required this.onTransformChanged,
  });

  @override
  State<_ClipLayer> createState() => _ClipLayerState();
}

class _ClipLayerState extends State<_ClipLayer> {
  late double _startScale;
  late double _startRotation;
  late Offset _startOffset;

  void _onScaleStart(ScaleStartDetails details) {
    widget.onTap();
    final t = widget.clip.transform;
    _startScale = t.scale;
    _startRotation = t.rotation;
    _startOffset = Offset(t.dx, t.dy);
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final t = widget.clip.transform;
    final newTransform = t.copyWith(
      scale: (_startScale * details.scale).clamp(0.2, 5.0),
      rotation: _startRotation + details.rotation,
      dx: _startOffset.dx + details.focalPointDelta.dx,
      dy: _startOffset.dy + details.focalPointDelta.dy,
    );
    widget.onTransformChanged(newTransform);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.clip.transform;
    final cropWidth = (t.cropRight - t.cropLeft).clamp(0.05, 1.0);
    final cropHeight = (t.cropBottom - t.cropTop).clamp(0.05, 1.0);

    Widget media;
    if (widget.clip.type == ClipType.video) {
      final vc = widget.videoController;
      media = (vc != null && vc.value.isInitialized)
          ? AspectRatio(aspectRatio: vc.value.aspectRatio, child: VideoPlayer(vc))
          : const ColoredBox(color: Colors.black12);
    } else {
      final path = widget.clip.localPath;
      media = path != null
          ? Image.file(File(path), fit: BoxFit.cover)
          : (widget.clip.remoteUrl != null
              ? Image.network(widget.clip.remoteUrl!, fit: BoxFit.cover)
              : const ColoredBox(color: Colors.black12));
    }

    // Кадрирование: увеличиваем и смещаем изображение так, чтобы был
    // виден только выбранный прямоугольник cropLeft..cropBottom.
    final cropped = ClipRect(
      child: Transform.scale(
        scale: 1 / cropWidth,
        child: FractionalTranslation(
          translation: Offset(-t.cropLeft / cropWidth, -t.cropTop / cropHeight),
          child: media,
        ),
      ),
    );

    return GestureDetector(
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..translateByDouble(t.dx, t.dy, 0, 1)
          ..rotateZ(t.rotation)
          ..scaleByDouble(t.scale, t.scale, t.scale, 1),
        child: Stack(
          fit: StackFit.expand,
          children: [
            cropped,
            if (widget.isSelected)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.accent, width: 2),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TextLayer extends StatefulWidget {
  final TextOverlayEntity overlay;
  final bool isSelected;
  final Size canvasSize;
  final VoidCallback onTap;
  final void Function(double dx, double dy) onMoved;

  const _TextLayer({
    super.key,
    required this.overlay,
    required this.isSelected,
    required this.canvasSize,
    required this.onTap,
    required this.onMoved,
  });

  @override
  State<_TextLayer> createState() => _TextLayerState();
}

class _TextLayerState extends State<_TextLayer> {
  late Offset _dragStart;
  Offset _accumulatedDelta = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final o = widget.overlay;

    return Positioned(
      left: widget.canvasSize.width / 2 + o.dx - 150,
      top: widget.canvasSize.height / 2 + o.dy - 20,
      width: 300,
      child: GestureDetector(
        onTap: widget.onTap,
        onPanStart: (_) {
          widget.onTap();
          _dragStart = Offset(o.dx, o.dy);
          _accumulatedDelta = Offset.zero;
        },
        onPanUpdate: (details) {
          _accumulatedDelta += details.delta;
          widget.onMoved(
            _dragStart.dx + _accumulatedDelta.dx,
            _dragStart.dy + _accumulatedDelta.dy,
          );
        },
        child: Container(
          alignment: Alignment.center,
          decoration: widget.isSelected
              ? BoxDecoration(border: Border.all(color: AppColors.accent, width: 1.5))
              : null,
          padding: const EdgeInsets.all(4),
          child: Text(
            o.text,
            textAlign: TextAlign.center,
            style: EditorTextStyleConstants.style(fontSize: o.fontSize, color: o.color),
          ),
        ),
      ),
    );
  }
}
