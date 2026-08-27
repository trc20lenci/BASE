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

  const EditorState({
    required this.timeline,
    this.isLoading = true,
    this.isSaving = false,
    this.selectedType = SelectedElementType.none,
    this.selectedId,
    this.playheadClipIndex = 0,
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
  }) {
    return EditorState(
      timeline: timeline ?? this.timeline,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      selectedType: clearSelection ? SelectedElementType.none : (selectedType ?? this.selectedType),
      selectedId: clearSelection ? null : (selectedId ?? this.selectedId),
      playheadClipIndex: playheadClipIndex ?? this.playheadClipIndex,
    );
  }

  @override
  List<Object?> get props =>
      [timeline, isLoading, isSaving, selectedType, selectedId, playheadClipIndex];
}
