import 'dart:io';
import '../entities/clip_type.dart';
import '../entities/editor_timeline_entity.dart';

abstract class TimelineRepository {
  Future<EditorTimelineEntity> loadTimeline(String projectId);

  Future<void> saveTimeline(EditorTimelineEntity timeline);

  /// Загружает медиафайл в Supabase Storage и возвращает его публичный URL.
  /// [ownerId] и [projectId] определяют путь хранения
  /// (см. SupabaseConstants.projectMediaPath).
  Future<String> uploadClipMedia({
    required String ownerId,
    required String projectId,
    required String clipId,
    required ClipType type,
    required File file,
  });

  /// Загружает пользовательский аудиофайл (наложенный звук/музыка) и
  /// возвращает публичный URL.
  Future<String> uploadAudioTrack({
    required String ownerId,
    required String projectId,
    required String trackId,
    required String extension,
    required File file,
  });
}
