import 'dart:io';
import '../entities/clip_type.dart';
import '../entities/editor_timeline_entity.dart';

abstract class TimelineRepository {
  Future<EditorTimelineEntity> loadTimeline(String projectId);

  Future<void> saveTimeline(EditorTimelineEntity timeline);

  /// Загружает медиафайл в Firebase Storage и возвращает его downloadUrl.
  /// [ownerId] и [projectId] определяют путь хранения
  /// (см. FirebaseConstants.projectMediaFolder).
  Future<String> uploadClipMedia({
    required String ownerId,
    required String projectId,
    required String clipId,
    required ClipType type,
    required File file,
  });
}
