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

/// Окно предпросмотра ("холст") + встроенная строка воспроизведения
/// (play/pause и перемотка) для текущего клипа.
///
/// Жесты на выбранном элементе (клип или текст) сразу обновляют
/// [CanvasTransform]/позицию через контроллер — "все изменения
/// отображаются сразу", как требует ТЗ. Начало/конец жеста коммитятся в
/// undo/redo одним шагом через beginGesture/commitGesture.
///
/// Ограничение этой версии: воспроизведение и перемотка работают внутри
/// ОДНОГО выбранного клипа (от его trimStart до trimEnd), а не сквозным
/// проигрыванием всего проекта по всем клипам подряд — это отдельная,
/// более крупная задача (нужен плеер, переключающий источник между
/// клипами без "мигания" кадра), вынесена на следующий шаг.
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
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void dispose() {
    _videoController?.removeListener(_onVideoTick);
    _videoController?.dispose();
    super.dispose();
  }

  void _ensureVideoController(TimelineClipEntity? clip) {
    if (clip == null || clip.type != ClipType.video || clip.displayPath == null) {
      if (_videoController != null) {
        _videoController!.removeListener(_onVideoTick);
        _videoController!.dispose();
        _videoController = null;
        _videoControllerForClipId = null;
      }
      return;
    }

    if (_videoControllerForClipId == clip.id) {
      // Тот же клип — просто синхронизируем громкость/скорость, если
      // пользователь их поменял без пересоздания контроллера.
      final vc = _videoController;
      if (vc != null && vc.value.isInitialized) {
        vc.setVolume(clip.isMuted ? 0 : clip.volume);
        vc.setPlaybackSpeed(clip.speed <= 0 ? 1.0 : clip.speed);
      }
      return;
    }

    _videoController?.removeListener(_onVideoTick);
    _videoController?.dispose();
    _videoControllerForClipId = clip.id;

    final path = clip.localPath;
    final controller = path != null
        ? VideoPlayerController.file(File(path))
        : VideoPlayerController.networkUrl(Uri.parse(clip.remoteUrl!));

    _videoController = controller;
    controller.initialize().then((_) async {
      if (!mounted) return;
      await controller.setLooping(false);
      await controller.setVolume(clip.isMuted ? 0 : clip.volume);
      await controller.setPlaybackSpeed(clip.speed <= 0 ? 1.0 : clip.speed);
      await controller.seekTo(Duration(milliseconds: clip.trimStartMs));
      setState(() {
        _duration = Duration(milliseconds: clip.durationMs);
        _position = Duration.zero;
      });
      controller.addListener(_onVideoTick);
    });
  }

  void _onVideoTick() {
    final vc = _videoController;
    if (vc == null || !vc.value.isInitialized || !mounted) return;

    final clips = ref.read(editorControllerProvider(widget.params)).timeline.clips;
    TimelineClipEntity? clip;
    for (final c in clips) {
      if (c.id == _videoControllerForClipId) {
        clip = c;
        break;
      }
    }
    if (clip == null) return;

    final relativeMs = vc.value.position.inMilliseconds - clip.trimStartMs;
    setState(() => _position = Duration(milliseconds: relativeMs.clamp(0, clip!.durationMs)));

    // Не даём уйти за конец обрезанного диапазона клипа — останавливаемся
    // на границе trimEnd вместо зацикливания или ухода в необрезанный хвост.
    if (vc.value.position.inMilliseconds >= clip.trimEndMs && vc.value.isPlaying) {
      vc.pause();
      ref.read(editorControllerProvider(widget.params).notifier).setPlaying(false);
    }
  }

  void _syncPlayback(bool shouldPlay) {
    final vc = _videoController;
    if (vc == null || !vc.value.isInitialized) return;
    if (shouldPlay && !vc.value.isPlaying) {
      vc.play();
    } else if (!shouldPlay && vc.value.isPlaying) {
      vc.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorControllerProvider(widget.params));
    final controller = ref.read(editorControllerProvider(widget.params).notifier);

    final clips = state.timeline.clips;
    final currentClip =
        clips.isEmpty ? null : clips[state.playheadClipIndex.clamp(0, clips.length - 1)];

    _ensureVideoController(currentClip);
    if (currentClip?.type == ClipType.video) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncPlayback(state.isPlaying));
    }

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
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
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4)),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (currentClip != null)
                          _ClipLayer(
                            key: ValueKey(currentClip.id),
                            clip: currentClip,
                            videoController: currentClip.type == ClipType.video ? _videoController : null,
                            isSelected: state.selectedType == SelectedElementType.clip && state.selectedId == currentClip.id,
                            canvasSize: Size(canvasWidth, canvasHeight),
                            onTap: () => controller.selectClip(currentClip.id),
                            onGestureStart: controller.beginGesture,
                            onGestureEnd: controller.commitGesture,
                            onTransformChanged: (t) => controller.updateClipTransform(currentClip.id, t),
                          )
                        else
                          const Center(child: Icon(Icons.movie_creation_outlined, color: AppColors.textDisabled, size: 40)),
                        for (final overlay in state.timeline.textOverlays)
                          _TextLayer(
                            key: ValueKey(overlay.id),
                            overlay: overlay,
                            isSelected: state.selectedType == SelectedElementType.text && state.selectedId == overlay.id,
                            canvasSize: Size(canvasWidth, canvasHeight),
                            onTap: () => controller.selectText(overlay.id),
                            onGestureStart: controller.beginGesture,
                            onGestureEnd: controller.commitGesture,
                            onMoved: (dx, dy) => controller.updateText(overlay.id, dx: dx, dy: dy),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (currentClip != null) _ScrubBar(
          clip: currentClip,
          position: currentClip.type == ClipType.video ? _position : Duration.zero,
          duration: currentClip.type == ClipType.video
              ? _duration
              : Duration(milliseconds: currentClip.durationMs),
          isPlaying: state.isPlaying,
          onPlayPause: () => controller.setPlaying(!state.isPlaying),
          onSeek: (ms) {
            final vc = _videoController;
            if (vc == null) return;
            vc.seekTo(Duration(milliseconds: currentClip.trimStartMs + ms));
            setState(() => _position = Duration(milliseconds: ms));
          },
        ),
      ],
    );
  }
}

class _ScrubBar extends StatelessWidget {
  final TimelineClipEntity clip;
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final ValueChanged<int> onSeek;

  const _ScrubBar({
    required this.clip,
    required this.position,
    required this.duration,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onSeek,
  });

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = clip.type == ClipType.video;
    final maxMs = duration.inMilliseconds.clamp(1, 1 << 31).toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: isVideo ? onPlayPause : null,
            icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: isVideo ? Colors.white : Colors.white24),
          ),
          Text(_fmt(position), style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Expanded(
            child: isVideo
                ? SliderTheme(
                    data: SliderTheme.of(context).copyWith(trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6)),
                    child: Slider(
                      min: 0,
                      max: maxMs,
                      value: position.inMilliseconds.clamp(0, maxMs.toInt()).toDouble(),
                      activeColor: AppColors.accent,
                      inactiveColor: Colors.white24,
                      onChanged: (v) => onSeek(v.round()),
                    ),
                  )
                : const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: LinearProgressIndicator(value: 1, color: Colors.white24, backgroundColor: Colors.white10),
                  ),
          ),
          Text(_fmt(duration), style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }
}

/// Слой клипа (фото/видео) с поддержкой перемещения/масштаба/поворота
/// одним жестом (1 палец — перемещение, 2 пальца — масштаб + поворот) и
/// кадрированием через ClipRect по CanvasTransform.crop*.
class _ClipLayer extends StatefulWidget {
  final TimelineClipEntity clip;
  final VideoPlayerController? videoController;
  final bool isSelected;
  final Size canvasSize;
  final VoidCallback onTap;
  final VoidCallback onGestureStart;
  final VoidCallback onGestureEnd;
  final ValueChanged<CanvasTransform> onTransformChanged;

  const _ClipLayer({
    super.key,
    required this.clip,
    required this.videoController,
    required this.isSelected,
    required this.canvasSize,
    required this.onTap,
    required this.onGestureStart,
    required this.onGestureEnd,
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
    widget.onGestureStart();
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
      onScaleEnd: (_) => widget.onGestureEnd(),
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
                  child: Container(decoration: BoxDecoration(border: Border.all(color: AppColors.accent, width: 2))),
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
  final VoidCallback onGestureStart;
  final VoidCallback onGestureEnd;
  final void Function(double dx, double dy) onMoved;

  const _TextLayer({
    super.key,
    required this.overlay,
    required this.isSelected,
    required this.canvasSize,
    required this.onTap,
    required this.onGestureStart,
    required this.onGestureEnd,
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
          widget.onGestureStart();
          _dragStart = Offset(o.dx, o.dy);
          _accumulatedDelta = Offset.zero;
        },
        onPanUpdate: (details) {
          _accumulatedDelta += details.delta;
          widget.onMoved(_dragStart.dx + _accumulatedDelta.dx, _dragStart.dy + _accumulatedDelta.dy);
        },
        onPanEnd: (_) => widget.onGestureEnd(),
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
