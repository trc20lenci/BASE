import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/canvas_transform.dart';
import '../../domain/entities/clip_type.dart';
import '../../domain/entities/editor_timeline_entity.dart';
import '../../domain/entities/media_overlay_entity.dart';
import '../../domain/entities/text_overlay_entity.dart';
import '../../domain/entities/timeline_clip_entity.dart';
import '../../domain/usecases/load_timeline_usecase.dart';
import '../../domain/usecases/save_timeline_usecase.dart';
import '../../domain/usecases/upload_clip_media_usecase.dart';
import 'editor_state.dart';
import 'timeline_di_providers.dart';

/// Параметры, необходимые контроллеру редактора для одного проекта.
class EditorControllerParams {
  final String projectId;
  final String ownerId;

  const EditorControllerParams({required this.projectId, required this.ownerId});

  @override
  bool operator ==(Object other) =>
      other is EditorControllerParams &&
      other.projectId == projectId &&
      other.ownerId == ownerId;

  @override
  int get hashCode => Object.hash(projectId, ownerId);
}

/// Вся бизнес-логика редактора: импорт медиа, обрезка/разделение клипов,
/// трансформация холста, текстовые слои, undo/redo, автосохранение.
///
/// Архитектурное решение: состояние редактора живёт в памяти (StateNotifier)
/// и сохраняется в бэкенд явно — после каждого изменения. Так UI остаётся
/// мгновенно отзывчивым (drag/resize на холсте не должны ждать сеть).
///
/// Undo/redo реализован как стек снимков EditorTimelineEntity (а не как
/// стек обратных операций) — это проще и надёжнее для MVP: любое
/// изменение таймлайна коммитится через [_commit], который сам кладёт
/// предыдущее состояние в undo-стек и чистит redo-стек.
class EditorController extends StateNotifier<EditorState> {
  final LoadTimelineUseCase _loadTimeline;
  final SaveTimelineUseCase _saveTimeline;
  final UploadClipMediaUseCase _uploadClipMedia;
  final EditorControllerParams _params;
  final _uuid = const Uuid();

  final List<EditorTimelineEntity> _undoStack = [];
  final List<EditorTimelineEntity> _redoStack = [];
  static const int _maxHistory = 50;

  EditorController({
    required LoadTimelineUseCase loadTimeline,
    required SaveTimelineUseCase saveTimeline,
    required UploadClipMediaUseCase uploadClipMedia,
    required EditorControllerParams params,
  })  : _loadTimeline = loadTimeline,
        _saveTimeline = saveTimeline,
        _uploadClipMedia = uploadClipMedia,
        _params = params,
        super(EditorState.initial(params.projectId)) {
    _init();
  }

  Future<void> _init() async {
    final timeline = await _loadTimeline(_params.projectId);
    state = state.copyWith(timeline: timeline, isLoading: false);
  }

  /// Единая точка применения любого изменения таймлайна: кладёт текущее
  /// состояние в undo-стек, чистит redo-стек (стандартное поведение
  /// undo/redo — новое действие "обнуляет" ветку redo), применяет новое
  /// состояние и сохраняет.
  void _commit(EditorTimelineEntity newTimeline) {
    _undoStack.add(state.timeline);
    if (_undoStack.length > _maxHistory) _undoStack.removeAt(0);
    _redoStack.clear();
    state = state.copyWith(timeline: newTimeline, canUndo: true, canRedo: false);
    _scheduleSave();
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    final previous = _undoStack.removeLast();
    _redoStack.add(state.timeline);
    state = state.copyWith(
      timeline: previous,
      canUndo: _undoStack.isNotEmpty,
      canRedo: true,
      clearSelection: true,
    );
    _scheduleSave();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    final next = _redoStack.removeLast();
    _undoStack.add(state.timeline);
    state = state.copyWith(
      timeline: next,
      canUndo: true,
      canRedo: _redoStack.isNotEmpty,
      clearSelection: true,
    );
    _scheduleSave();
  }

  // ---------------------------------------------------------------------
  // Импорт медиа
  // ---------------------------------------------------------------------

  /// Добавляет клип в конец таймлайна. Немедленно показывает локальный
  /// файл, параллельно запускает фоновую загрузку в Storage.
  Future<void> addMediaClip({
    required File file,
    required ClipType type,
    required int sourceDurationMs,
  }) async {
    final id = _uuid.v4();
    final clip = TimelineClipEntity(
      id: id,
      type: type,
      localPath: file.path,
      order: state.timeline.clips.length,
      sourceDurationMs: sourceDurationMs,
      trimStartMs: 0,
      trimEndMs: sourceDurationMs,
    );

    _commit(state.timeline.copyWith(clips: [...state.timeline.clips, clip]));

    // Фоновая загрузка — не блокирует UI и не участвует в undo/redo
    // (это чисто инфраструктурная синхронизация, не творческое решение
    // пользователя). По завершении обновляем клип remoteUrl'ом напрямую,
    // минуя _commit.
    try {
      final url = await _uploadClipMedia(
        ownerId: _params.ownerId,
        projectId: _params.projectId,
        clipId: id,
        type: type,
        file: file,
      );
      final stillExists = state.timeline.clips.any((c) => c.id == id);
      if (!stillExists) return;

      final updated = state.timeline.clips
          .map((c) => c.id == id ? c.copyWith(remoteUrl: url) : c)
          .toList();
      state = state.copyWith(timeline: state.timeline.copyWith(clips: updated));
      _scheduleSave();
    } catch (_) {
      // Загрузка не удалась — клип продолжает работать локально
      // (localPath), пользователь может продолжать монтаж офлайн.
    }
  }

  void removeClip(String clipId) {
    final remaining = state.timeline.clips.where((c) => c.id != clipId).toList();
    final reordered = [
      for (var i = 0; i < remaining.length; i++) remaining[i].copyWith(order: i),
    ];
    _commit(state.timeline.copyWith(clips: reordered));
    if (state.selectedId == clipId) {
      state = state.copyWith(clearSelection: true);
    }
  }

  void reorderClips(int oldIndex, int newIndex) {
    final clips = [...state.timeline.clips];
    if (newIndex > oldIndex) newIndex -= 1;
    final item = clips.removeAt(oldIndex);
    clips.insert(newIndex, item);

    final reordered = [
      for (var i = 0; i < clips.length; i++) clips[i].copyWith(order: i),
    ];

    _commit(state.timeline.copyWith(clips: reordered));
  }

  // ---------------------------------------------------------------------
  // Работа с видео: обрезка начала/конца, разделение, громкость, скорость
  // ---------------------------------------------------------------------

  void trimClipStart(String clipId, int newStartMs) {
    final updated = _mapClips(clipId, (c) {
      final clamped = newStartMs.clamp(0, c.trimEndMs - 200).toInt();
      return c.copyWith(trimStartMs: clamped);
    });
    _commit(state.timeline.copyWith(clips: updated));
  }

  void trimClipEnd(String clipId, int newEndMs) {
    final updated = _mapClips(clipId, (c) {
      final clamped = newEndMs.clamp(c.trimStartMs + 200, c.sourceDurationMs).toInt();
      return c.copyWith(trimEndMs: clamped);
    });
    _commit(state.timeline.copyWith(clips: updated));
  }

  /// Разделяет клип на два в точке [atMs] (миллисекунды от начала
  /// исходного файла). Второй клип получает новый ID и наследует
  /// трансформацию/громкость/скорость исходного.
  void splitClip(String clipId, int atMs) {
    final clips = state.timeline.clips;
    final index = clips.indexWhere((c) => c.id == clipId);
    if (index == -1) return;

    final original = clips[index];
    if (atMs <= original.trimStartMs + 100 || atMs >= original.trimEndMs - 100) {
      return; // точка разделения слишком близко к краю — игнорируем
    }

    final firstPart = original.copyWith(trimEndMs: atMs);
    final secondPart = TimelineClipEntity(
      id: _uuid.v4(),
      type: original.type,
      localPath: original.localPath,
      remoteUrl: original.remoteUrl,
      order: original.order + 1,
      sourceDurationMs: original.sourceDurationMs,
      trimStartMs: atMs,
      trimEndMs: original.trimEndMs,
      transform: original.transform,
      volume: original.volume,
      isMuted: original.isMuted,
      speed: original.speed,
    );

    final newClips = [...clips];
    newClips[index] = firstPart;
    newClips.insert(index + 1, secondPart);

    final reordered = [
      for (var i = 0; i < newClips.length; i++) newClips[i].copyWith(order: i),
    ];

    _commit(state.timeline.copyWith(clips: reordered));
  }

  /// Разделяет выбранный клип ровно там, где сейчас стоит плейхед
  /// предпросмотра (реальное "разделение по позиции", а не только
  /// "пополам").
  void splitSelectedClipAtPlayhead() {
    final clipId = state.selectedId;
    if (clipId == null || state.selectedType != SelectedElementType.clip) return;
    final clip = state.timeline.clips.firstWhere((c) => c.id == clipId, orElse: () => state.timeline.clips.first);
    final atMs = clip.trimStartMs + state.playheadPositionMs;
    splitClip(clipId, atMs);
  }

  void setClipVolume(String clipId, double volume) {
    final updated = _mapClips(clipId, (c) => c.copyWith(volume: volume.clamp(0.0, 1.0)));
    _commit(state.timeline.copyWith(clips: updated));
  }

  void toggleClipMute(String clipId) {
    final clip = state.timeline.clips.firstWhere((c) => c.id == clipId, orElse: () => state.timeline.clips.first);
    final updated = _mapClips(clipId, (c) => c.copyWith(isMuted: !clip.isMuted));
    _commit(state.timeline.copyWith(clips: updated));
  }

  void setClipSpeed(String clipId, double speed) {
    final updated = _mapClips(clipId, (c) => c.copyWith(speed: speed));
    _commit(state.timeline.copyWith(clips: updated));
  }

  // ---------------------------------------------------------------------
  // Холст: перемещение, масштаб, поворот, кадрирование (фото и видео)
  // ---------------------------------------------------------------------

  /// Обновление трансформации холста НЕ коммитится в undo/redo на каждый
  /// кадр жеста (иначе один свайп создал бы сотни шагов истории) — только
  /// напрямую в state. Снимок "до жеста" фиксируется в [beginGesture],
  /// а сам шаг истории добавляется в [commitGesture] по завершении жеста.
  void updateClipTransform(String clipId, CanvasTransform transform) {
    final updated = _mapClips(clipId, (c) => c.copyWith(transform: transform));
    state = state.copyWith(timeline: state.timeline.copyWith(clips: updated));
  }

  EditorTimelineEntity? _gestureStartTimeline;

  /// Вызывается в начале любого перетаскивания на холсте (трансформация
  /// клипа, перемещение текста) — запоминает состояние "до", чтобы потом
  /// положить его в undo-стек одним шагом, а не на каждый пиксель.
  void beginGesture() {
    _gestureStartTimeline ??= state.timeline;
  }

  /// Вызывается по завершении перетаскивания — фиксирует один шаг истории.
  void commitGesture() {
    final start = _gestureStartTimeline;
    _gestureStartTimeline = null;
    if (start == null || start == state.timeline) return; // ничего не изменилось

    _undoStack.add(start);
    if (_undoStack.length > _maxHistory) _undoStack.removeAt(0);
    _redoStack.clear();
    state = state.copyWith(canUndo: true, canRedo: false);
    _scheduleSave();
  }

  // ---------------------------------------------------------------------
  // Наложения (picture-in-picture поверх видео)
  // ---------------------------------------------------------------------

  /// Добавляет фото/видео как наложение поверх текущего клипа — в
  /// отличие от addMediaClip, НЕ занимает своё время на дорожке,
  /// показывается одновременно с уже идущим клипом (см. MediaOverlayEntity).
  Future<void> addOverlay({required File file, required ClipType type}) async {
    final id = _uuid.v4();
    final overlay = MediaOverlayEntity(
      id: id,
      type: type,
      localPath: file.path,
      order: state.timeline.overlays.length,
    );

    _commit(state.timeline.copyWith(overlays: [...state.timeline.overlays, overlay]));
    state = state.copyWith(selectedType: SelectedElementType.overlay, selectedId: id);

    try {
      final url = await _uploadClipMedia(
        ownerId: _params.ownerId,
        projectId: _params.projectId,
        clipId: id,
        type: type,
        file: file,
      );
      final stillExists = state.timeline.overlays.any((o) => o.id == id);
      if (!stillExists) return;

      final updated =
          state.timeline.overlays.map((o) => o.id == id ? o.copyWith(remoteUrl: url) : o).toList();
      state = state.copyWith(timeline: state.timeline.copyWith(overlays: updated));
      _scheduleSave();
    } catch (_) {
      // Загрузка не удалась — наложение продолжает работать локально.
    }
  }

  void removeOverlay(String overlayId) {
    final updated = state.timeline.overlays.where((o) => o.id != overlayId).toList();
    _commit(state.timeline.copyWith(overlays: updated));
    if (state.selectedId == overlayId) {
      state = state.copyWith(clearSelection: true);
    }
  }

  /// Трансформация наложения тоже идёт через begin/commitGesture (см.
  /// CanvasStage) — здесь только применяем изменение без лишних шагов
  /// истории на каждый кадр жеста.
  void updateOverlayTransform(String overlayId, CanvasTransform transform) {
    final updated = state.timeline.overlays
        .map((o) => o.id == overlayId ? o.copyWith(transform: transform) : o)
        .toList();
    state = state.copyWith(timeline: state.timeline.copyWith(overlays: updated));
  }

  void selectOverlay(String overlayId) {
    state = state.copyWith(selectedType: SelectedElementType.overlay, selectedId: overlayId);
  }

  // ---------------------------------------------------------------------
  // Текст
  // ---------------------------------------------------------------------

  void addText() {
    final overlay = TextOverlayEntity(id: _uuid.v4(), text: 'Текст');
    _commit(state.timeline.copyWith(textOverlays: [...state.timeline.textOverlays, overlay]));
    state = state.copyWith(selectedType: SelectedElementType.text, selectedId: overlay.id);
  }

  void updateText(
    String textId, {
    String? text,
    double? fontSize,
    Color? color,
    double? dx,
    double? dy,
  }) {
    final updated = state.timeline.textOverlays.map((t) {
      if (t.id != textId) return t;
      return t.copyWith(text: text, fontSize: fontSize, color: color, dx: dx, dy: dy);
    }).toList();
    // Перетаскивание текста по холсту коммитится через beginGesture/
    // commitGesture (см. CanvasStage) — здесь только применяем изменение.
    state = state.copyWith(timeline: state.timeline.copyWith(textOverlays: updated));
    _scheduleSave();
  }

  void deleteText(String textId) {
    final updated = state.timeline.textOverlays.where((t) => t.id != textId).toList();
    _commit(state.timeline.copyWith(textOverlays: updated));
    if (state.selectedId == textId) {
      state = state.copyWith(clearSelection: true);
    }
  }

  // ---------------------------------------------------------------------
  // Выбор элемента на холсте
  // ---------------------------------------------------------------------

  void selectClip(String clipId) {
    state = state.copyWith(selectedType: SelectedElementType.clip, selectedId: clipId);
  }

  void selectText(String textId) {
    state = state.copyWith(selectedType: SelectedElementType.text, selectedId: textId);
  }

  void clearSelection() {
    state = state.copyWith(clearSelection: true);
  }

  void setPlayheadClipIndex(int index) {
    if (index < 0 || index >= state.timeline.clips.length) return;
    state = state.copyWith(playheadClipIndex: index, playheadPositionMs: 0);
  }

  void setPlayheadPositionMs(int ms) {
    state = state.copyWith(playheadPositionMs: ms);
  }

  void setPlaying(bool playing) {
    state = state.copyWith(isPlaying: playing);
  }

  // ---------------------------------------------------------------------
  // Сохранение
  // ---------------------------------------------------------------------

  Future<void> _scheduleSave() async {
    state = state.copyWith(isSaving: true);
    try {
      await _saveTimeline(state.timeline);
    } finally {
      if (mounted) state = state.copyWith(isSaving: false);
    }
  }

  Future<void> saveNow() => _scheduleSave();

  List<TimelineClipEntity> _mapClips(
    String clipId,
    TimelineClipEntity Function(TimelineClipEntity) update,
  ) {
    return state.timeline.clips.map((c) => c.id == clipId ? update(c) : c).toList();
  }
}

final editorControllerProvider = StateNotifierProvider.family<EditorController, EditorState,
    EditorControllerParams>((ref, params) {
  return EditorController(
    loadTimeline: ref.watch(loadTimelineUseCaseProvider),
    saveTimeline: ref.watch(saveTimelineUseCaseProvider),
    uploadClipMedia: ref.watch(uploadClipMediaUseCaseProvider),
    params: params,
  );
});
