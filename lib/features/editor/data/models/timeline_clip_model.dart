import '../../domain/entities/canvas_transform.dart';
import '../../domain/entities/clip_type.dart';
import '../../domain/entities/timeline_clip_entity.dart';

class TimelineClipModel extends TimelineClipEntity {
  const TimelineClipModel({
    required super.id,
    required super.type,
    super.localPath,
    super.remoteUrl,
    required super.order,
    required super.sourceDurationMs,
    required super.trimStartMs,
    required super.trimEndMs,
    super.transform,
    super.keyframes,
    super.volume,
    super.isMuted,
    super.speed,
  });

  factory TimelineClipModel.fromEntity(TimelineClipEntity e) {
    return TimelineClipModel(
      id: e.id,
      type: e.type,
      localPath: e.localPath,
      remoteUrl: e.remoteUrl,
      order: e.order,
      sourceDurationMs: e.sourceDurationMs,
      trimStartMs: e.trimStartMs,
      trimEndMs: e.trimEndMs,
      transform: e.transform,
      keyframes: e.keyframes,
      volume: e.volume,
      isMuted: e.isMuted,
      speed: e.speed,
    );
  }

  factory TimelineClipModel.fromMap(Map<String, dynamic> map) {
    return TimelineClipModel(
      id: map['id'] as String,
      type: (map['type'] as String) == 'video' ? ClipType.video : ClipType.photo,
      remoteUrl: map['remoteUrl'] as String?,
      order: map['order'] as int,
      sourceDurationMs: map['sourceDurationMs'] as int,
      trimStartMs: map['trimStartMs'] as int,
      trimEndMs: map['trimEndMs'] as int,
      transform: map['transform'] != null
          ? CanvasTransform.fromMap(Map<String, dynamic>.from(map['transform'] as Map))
          : CanvasTransform.identity,
      keyframes: (map['keyframes'] as List?)
              ?.map((k) => KeyframeEntity.fromMap(Map<String, dynamic>.from(k as Map)))
              .toList() ??
          const [],
      volume: (map['volume'] as num?)?.toDouble() ?? 1.0,
      isMuted: map['isMuted'] as bool? ?? false,
      speed: (map['speed'] as num?)?.toDouble() ?? 1.0,
    );
  }

  /// В Firestore сохраняем только remoteUrl — localPath валиден лишь на
  /// устройстве, где был сделан импорт, и не переживает переустановку.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type == ClipType.video ? 'video' : 'photo',
      'remoteUrl': remoteUrl,
      'order': order,
      'sourceDurationMs': sourceDurationMs,
      'trimStartMs': trimStartMs,
      'trimEndMs': trimEndMs,
      'transform': transform.toMap(),
      'keyframes': keyframes.map((k) => k.toMap()).toList(),
      'volume': volume,
      'isMuted': isMuted,
      'speed': speed,
    };
  }
}
