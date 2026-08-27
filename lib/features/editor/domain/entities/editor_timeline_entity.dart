import 'package:equatable/equatable.dart';
import 'text_overlay_entity.dart';
import 'timeline_clip_entity.dart';

/// Полное состояние монтажа одного проекта: клипы таймлайна + текстовые
/// слои. Это то, что целиком сохраняется/загружается как один документ
/// Firestore (projects/{id}/timeline/data) — сознательно не храним это
/// в самом документе проекта на Home, чтобы список проектов оставался
/// лёгким и быстро грузился без содержимого монтажа.
class EditorTimelineEntity extends Equatable {
  final String projectId;
  final List<TimelineClipEntity> clips;
  final List<TextOverlayEntity> textOverlays;

  const EditorTimelineEntity({
    required this.projectId,
    required this.clips,
    required this.textOverlays,
  });

  factory EditorTimelineEntity.empty(String projectId) {
    return EditorTimelineEntity(projectId: projectId, clips: const [], textOverlays: const []);
  }

  int get totalDurationMs =>
      clips.fold(0, (sum, clip) => sum + clip.durationMs);

  EditorTimelineEntity copyWith({
    List<TimelineClipEntity>? clips,
    List<TextOverlayEntity>? textOverlays,
  }) {
    return EditorTimelineEntity(
      projectId: projectId,
      clips: clips ?? this.clips,
      textOverlays: textOverlays ?? this.textOverlays,
    );
  }

  @override
  List<Object?> get props => [projectId, clips, textOverlays];
}
