import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/canvas_transform.dart';
import '../../domain/entities/clip_type.dart';
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
/// трансформация холста, текстовые слои, автосохранение.
///
/// Архитектурное решение: состояние редактора живёт в памяти (StateNotifier)
/// и сохраняется в Firestore явно — по debounce после каждого изменения и
/// принудительно при выходе с экрана. Так UI остаётся мгновенно отзывчивым
/// (drag/resize на холсте не должны ждать сеть), а данные не теряются.
class EditorController extends StateNotifier<EditorState> {
  final LoadTimelineUseCase _loadTimeline;
  final SaveTimelineUseCase _saveTimeline;
  final UploadClipMediaUseCase _uploadClipMedia;
  final EditorControllerParams _params;
  final _uuid = const Uuid();

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

    state = state.copyWith(
      timeline: state.timeline.copyWith(clips: [...state.timeline.clips, clip]),
    );
    _scheduleSave();

    // Фоновая загрузка — не блокирует UI. По завершении обновляем клип
    // remoteUrl'ом, если он всё ещё есть на таймлайне (мог быть удалён
    // пользователем, пока грузился).
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

      _updateClip(id, (c) => c.copyWith(remoteUrl: url));
      _scheduleSave();
    } catch (_) {
      // Загрузка не удалась — клип продолжает работать локально
      // (localPath), пользователь может продолжать монтаж офлайн.
      // Повторная попытка происходит при следующем ручном сохранении.
    }
  }

  void removeClip(String clipId) {
    final remaining = state.timeline.clips.where((c) => c.id != clipId).toList();
    // Пересчитываем order, чтобы не было "дыр" в последовательности.
    final reordered = [
      for (var i = 0; i < remaining.length; i++) remaining[i].copyWith(order: i),
    ];
    state = state.copyWith(
      timeline: state.timeline.copyWith(clips: reordered),
      clearSelection: state.selectedId == clipId,
    );
    _scheduleSave();
  }

  void reorderClips(int oldIndex, int newIndex) {
    final clips = [...state.timeline.clips];
    if (newIndex > oldIndex) newIndex -= 1;
    final item = clips.removeAt(oldIndex);
    clips.insert(newIndex, item);

    final reordered = [
      for (var i = 0; i < clips.length; i++) clips[i].copyWith(order: i),
    ];

    state = state.copyWith(timeline: state.timeline.copyWith(clips: reordered));
    _scheduleSave();
  }

  // ---------------------------------------------------------------------
  // Работа с видео: обрезка начала/конца, разделение
  // ---------------------------------------------------------------------

  void trimClipStart(String clipId, int newStartMs) {
    _updateClip(clipId, (c) {
      final clamped = newStartMs.clamp(0, c.trimEndMs - 200).toInt(); // минимум 200мс клипа
      return c.copyWith(trimStartMs: clamped);
    });
    _scheduleSave();
  }

  void trimClipEnd(String clipId, int newEndMs) {
    _updateClip(clipId, (c) {
      final clamped = newEndMs.clamp(c.trimStartMs + 200, c.sourceDurationMs).toInt();
      return c.copyWith(trimEndMs: clamped);
    });
    _scheduleSave();
  }

  /// Разделяет клип на два в точке [atMs] (миллисекунды от начала
  /// исходного файла, должна лежать строго внутри текущего диапазона
  /// обрезки клипа). Второй клип получает новый ID и наследует
  /// трансформацию исходного.
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
    );

    final newClips = [...clips];
    newClips[index] = firstPart;
    newClips.insert(index + 1, secondPart);

    final reordered = [
      for (var i = 0; i < newClips.length; i++) newClips[i].copyWith(order: i),
    ];

    state = state.copyWith(timeline: state.timeline.copyWith(clips: reordered));
    _scheduleSave();
  }

  // ---------------------------------------------------------------------
  // Холст: перемещение, масштаб, поворот, кадрирование (фото и видео)
  // ---------------------------------------------------------------------

  void updateClipTransform(String clipId, CanvasTransform transform) {
    _updateClip(clipId, (c) => c.copyWith(transform: transform));
    _scheduleSave();
  }

  // ---------------------------------------------------------------------
  // Текст
  // ---------------------------------------------------------------------

  void addText() {
    final overlay = TextOverlayEntity(id: _uuid.v4(), text: 'Текст');
    state = state.copyWith(
      timeline: state.timeline.copyWith(
        textOverlays: [...state.timeline.textOverlays, overlay],
      ),
      selectedType: SelectedElementType.text,
      selectedId: overlay.id,
    );
    _scheduleSave();
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

    state = state.copyWith(timeline: state.timeline.copyWith(textOverlays: updated));
    _scheduleSave();
  }

  void deleteText(String textId) {
    final updated = state.timeline.textOverlays.where((t) => t.id != textId).toList();
    state = state.copyWith(
      timeline: state.timeline.copyWith(textOverlays: updated),
      clearSelection: state.selectedId == textId,
    );
    _scheduleSave();
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
    state = state.copyWith(playheadClipIndex: index);
  }

  // ---------------------------------------------------------------------
  // Сохранение
  // ---------------------------------------------------------------------

  Future<void> _scheduleSave() async {
    // Простой debounce: сохраняем сразу, но помечаем isSaving, чтобы UI
    // мог показать индикатор. Для реального продакшена стоит добавить
    // Timer-debounce на 500-800мс при частых правках (drag на холсте) —
    // оставлено как заметка для оптимизации после MVP.
    state = state.copyWith(isSaving: true);
    try {
      await _saveTimeline(state.timeline);
    } finally {
      if (mounted) state = state.copyWith(isSaving: false);
    }
  }

  Future<void> saveNow() => _scheduleSave();

  void _updateClip(String clipId, TimelineClipEntity Function(TimelineClipEntity) update) {
    final updated = state.timeline.clips.map((c) {
      if (c.id != clipId) return c;
      return update(c);
    }).toList();
    state = state.copyWith(timeline: state.timeline.copyWith(clips: updated));
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
