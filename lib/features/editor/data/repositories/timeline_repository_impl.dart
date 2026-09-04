import 'dart:io';
import '../../domain/entities/clip_type.dart';
import '../../domain/entities/editor_timeline_entity.dart';
import '../../domain/repositories/timeline_repository.dart';
import '../datasources/timeline_remote_data_source.dart';
import '../models/media_overlay_model.dart';
import '../models/text_overlay_model.dart';
import '../models/timeline_clip_model.dart';

class TimelineRepositoryImpl implements TimelineRepository {
  final TimelineRemoteDataSource _remote;

  TimelineRepositoryImpl(this._remote);

  @override
  Future<EditorTimelineEntity> loadTimeline(String projectId) async {
    final data = await _remote.loadTimeline(projectId);
    if (data == null) {
      return EditorTimelineEntity.empty(projectId);
    }

    final clipsRaw = (data['clips'] as List?) ?? [];
    // Ключи в Postgres — snake_case (см. TimelineRemoteDataSource.saveTimeline).
    final textsRaw = (data['text_overlays'] as List?) ?? [];
    final overlaysRaw = (data['overlays'] as List?) ?? [];

    return EditorTimelineEntity(
      projectId: projectId,
      clips: clipsRaw
          .map((c) => TimelineClipModel.fromMap(Map<String, dynamic>.from(c as Map)))
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order)),
      textOverlays: textsRaw
          .map((t) => TextOverlayModel.fromMap(Map<String, dynamic>.from(t as Map)))
          .toList(),
      overlays: overlaysRaw
          .map((o) => MediaOverlayModel.fromMap(Map<String, dynamic>.from(o as Map)))
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order)),
    );
  }

  @override
  Future<void> saveTimeline(EditorTimelineEntity timeline) {
    return _remote.saveTimeline(
      projectId: timeline.projectId,
      clips: timeline.clips.map((c) => TimelineClipModel.fromEntity(c)).toList(),
      textOverlays: timeline.textOverlays.map((t) => TextOverlayModel.fromEntity(t)).toList(),
      overlays: timeline.overlays.map((o) => MediaOverlayModel.fromEntity(o)).toList(),
    );
  }

  @override
  Future<String> uploadClipMedia({
    required String ownerId,
    required String projectId,
    required String clipId,
    required ClipType type,
    required File file,
  }) {
    return _remote.uploadClipMedia(
      ownerId: ownerId,
      projectId: projectId,
      clipId: clipId,
      type: type,
      file: file,
    );
  }
}
