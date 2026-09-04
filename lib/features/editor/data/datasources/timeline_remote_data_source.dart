import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../../core/constants/supabase_constants.dart';
import '../../domain/entities/clip_type.dart';
import '../models/audio_track_model.dart';
import '../models/media_overlay_model.dart';
import '../models/text_overlay_model.dart';
import '../models/timeline_clip_model.dart';

/// Таймлайн проекта хранится ОТДЕЛЬНОЙ таблицей `project_timelines`
/// (project_id PK, clips jsonb, text_overlays jsonb) — а не колонками в
/// самой таблице `projects` — потому что:
/// 1. Список проектов на Home читает только лёгкие метаданные (title,
///    format, даты) и не должен подтягивать потенциально большой JSON
///    с клипами и текстовыми слоями.
/// 2. Частые обновления таймлайна (при каждом изменении в редакторе) не
///    должны триггерить лишние перерисовки списка проектов на Home,
///    который слушает таблицу `projects` через watchUserProjects.
class TimelineRemoteDataSource {
  final sb.SupabaseClient _client;

  TimelineRemoteDataSource({sb.SupabaseClient? client})
      : _client = client ?? sb.Supabase.instance.client;

  Future<Map<String, dynamic>?> loadTimeline(String projectId) async {
    return _client
        .from(SupabaseConstants.projectTimelinesTable)
        .select()
        .eq('project_id', projectId)
        .maybeSingle();
  }

  Future<void> saveTimeline({
    required String projectId,
    required List<TimelineClipModel> clips,
    required List<TextOverlayModel> textOverlays,
    required List<MediaOverlayModel> overlays,
    required List<AudioTrackModel> audioTracks,
  }) async {
    final now = DateTime.now().toIso8601String();

    await _client.from(SupabaseConstants.projectTimelinesTable).upsert({
      'project_id': projectId,
      'clips': clips.map((c) => c.toMap()).toList(),
      'text_overlays': textOverlays.map((t) => t.toMap()).toList(),
      'overlays': overlays.map((o) => o.toMap()).toList(),
      'audio_tracks': audioTracks.map((a) => a.toMap()).toList(),
      'updated_at': now,
    });

    // Обновляем updated_at самого проекта, чтобы Home корректно сортировал
    // "недавно изменённые" проекты даже если менялось только содержимое
    // таймлайна, а не название.
    await _client
        .from(SupabaseConstants.projectsTable)
        .update({'updated_at': now})
        .eq('id', projectId);
  }

  /// Загружает медиафайл клипа в бакет `project-media` и возвращает
  /// публичный URL.
  ///
  /// Архитектурная заметка: бакет намеренно публичный (как и
  /// `avatars`/`exports`) — пути включают ownerId/projectId/clipId и
  /// непредсказуемы для перебора, что соответствует модели безопасности
  /// Firebase Storage по умолчанию (публичный, но "неугадываемый" URL).
  /// Если для проекта нужна более строгая приватность — переключите
  /// бакет на private в Supabase Dashboard и замените getPublicUrl на
  /// createSignedUrl(path, expiresIn) с нужным сроком действия.
  Future<String> uploadClipMedia({
    required String ownerId,
    required String projectId,
    required String clipId,
    required ClipType type,
    required File file,
  }) async {
    final extension = type == ClipType.video ? 'mp4' : 'jpg';
    final fileName = '$clipId.$extension';
    final path = SupabaseConstants.projectMediaPath(ownerId, projectId, fileName);

    await _client.storage.from(SupabaseConstants.projectMediaBucket).upload(
          path,
          file,
          fileOptions: const sb.FileOptions(upsert: true),
        );

    return _client.storage.from(SupabaseConstants.projectMediaBucket).getPublicUrl(path);
  }

  /// Загружает аудиофайл (пользовательская дорожка) в тот же бакет
  /// `project-media`, что и медиа клипов — путь включает расширение
  /// исходного файла, чтобы плееры могли определить формат.
  Future<String> uploadAudioTrack({
    required String ownerId,
    required String projectId,
    required String trackId,
    required String extension,
    required File file,
  }) async {
    final fileName = '$trackId.$extension';
    final path = SupabaseConstants.projectMediaPath(ownerId, projectId, fileName);

    await _client.storage.from(SupabaseConstants.projectMediaBucket).upload(
          path,
          file,
          fileOptions: const sb.FileOptions(upsert: true),
        );

    return _client.storage.from(SupabaseConstants.projectMediaBucket).getPublicUrl(path);
  }
}
