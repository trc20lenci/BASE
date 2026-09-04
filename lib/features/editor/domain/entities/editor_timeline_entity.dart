import 'package:equatable/equatable.dart';
import 'media_overlay_entity.dart';
import 'text_overlay_entity.dart';
import 'timeline_clip_entity.dart';

/// Полное состояние монтажа одного проекта: клипы таймлайна, текстовые
/// слои и наложения (picture-in-picture поверх видео). Это то, что
/// целиком сохраняется/загружается как один документ (см.
/// TimelineRemoteDataSource) — сознательно не храним это в самой строке
/// проекта на Home, чтобы список проектов оставался лёгким.
class EditorTimelineEntity extends Equatable {
  final String projectId;
  final List<TimelineClipEntity> clips;
  final List<TextOverlayEntity> textOverlays;
  final List<MediaOverlayEntity> overlays;

  const EditorTimelineEntity({
    required this.projectId,
    required this.clips,
    required this.textOverlays,
    this.overlays = const [],
  });

  factory EditorTimelineEntity.empty(String projectId) {
    return EditorTimelineEntity(projectId: projectId, clips: const [], textOverlays: const [], overlays: const []);
  }

  int get totalDurationMs => clips.fold(0, (sum, clip) => sum + clip.durationMs);

  EditorTimelineEntity copyWith({
    List<TimelineClipEntity>? clips,
    List<TextOverlayEntity>? textOverlays,
    List<MediaOverlayEntity>? overlays,
  }) {
    return EditorTimelineEntity(
      projectId: projectId,
      clips: clips ?? this.clips,
      textOverlays: textOverlays ?? this.textOverlays,
      overlays: overlays ?? this.overlays,
    );
  }

  @override
  List<Object?> get props => [projectId, clips, textOverlays, overlays];
}
