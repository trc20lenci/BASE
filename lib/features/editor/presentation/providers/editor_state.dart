import 'package:equatable/equatable.dart';
import '../../domain/entities/editor_timeline_entity.dart';

/// Что именно сейчас выбрано на холсте — влияет на то, какая панель
/// инструментов активна (трансформация клипа или трансформация текста).
enum SelectedElementType { none, clip, text }

class EditorState extends Equatable {
  final EditorTimelineEntity timeline;
  final bool isLoading;
  final bool isSaving;

  final SelectedElementType selectedType;
  final String? selectedId;

  /// Индекс клипа, который сейчас показывается в окне предпросмотра
  /// (соответствует позиции плейхеда на таймлайне).
  final int playheadClipIndex;

  /// Позиция плейхеда внутри текущего клипа, в мс от начала обрезанного
  /// диапазона (используется для перемотки и разделения по факту, а не
  /// только "пополам").
  final int playheadPositionMs;

  final bool isPlaying;

  final bool canUndo;
  final bool canRedo;

  const EditorState({
    required this.timeline,
    this.isLoading = true,
    this.isSaving = false,
    this.selectedType = SelectedElementType.none,
    this.selectedId,
    this.playheadClipIndex = 0,
    this.playheadPositionMs = 0,
    this.isPlaying = false,
    this.canUndo = false,
    this.canRedo = false,
  });

  factory EditorState.initial(String projectId) {
    return EditorState(timeline: EditorTimelineEntity.empty(projectId));
  }

  EditorState copyWith({
    EditorTimelineEntity? timeline,
    bool? isLoading,
    bool? isSaving,
    SelectedElementType? selectedType,
    String? selectedId,
    bool clearSelection = false,
    int? playheadClipIndex,
    int? playheadPositionMs,
    bool? isPlaying,
    bool? canUndo,
    bool? canRedo,
  }) {
    return EditorState(
      timeline: timeline ?? this.timeline,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      selectedType: clearSelection ? SelectedElementType.none : (selectedType ?? this.selectedType),
      selectedId: clearSelection ? null : (selectedId ?? this.selectedId),
      playheadClipIndex: playheadClipIndex ?? this.playheadClipIndex,
      playheadPositionMs: playheadPositionMs ?? this.playheadPositionMs,
      isPlaying: isPlaying ?? this.isPlaying,
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
    );
  }

  @override
  List<Object?> get props => [
        timeline,
        isLoading,
        isSaving,
        selectedType,
        selectedId,
        playheadClipIndex,
        playheadPositionMs,
        isPlaying,
        canUndo,
        canRedo,
      ];
}
