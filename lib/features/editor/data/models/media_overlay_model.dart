import '../../domain/entities/canvas_transform.dart';
import '../../domain/entities/clip_type.dart';
import '../../domain/entities/media_overlay_entity.dart';

class MediaOverlayModel extends MediaOverlayEntity {
  const MediaOverlayModel({
    required super.id,
    required super.type,
    super.localPath,
    super.remoteUrl,
    required super.order,
    super.transform,
    super.opacity,
  });

  factory MediaOverlayModel.fromEntity(MediaOverlayEntity e) {
    return MediaOverlayModel(
      id: e.id,
      type: e.type,
      localPath: e.localPath,
      remoteUrl: e.remoteUrl,
      order: e.order,
      transform: e.transform,
      opacity: e.opacity,
    );
  }

  factory MediaOverlayModel.fromMap(Map<String, dynamic> map) {
    return MediaOverlayModel(
      id: map['id'] as String,
      type: (map['type'] as String) == 'video' ? ClipType.video : ClipType.photo,
      remoteUrl: map['remoteUrl'] as String?,
      order: map['order'] as int,
      transform: map['transform'] != null
          ? CanvasTransform.fromMap(Map<String, dynamic>.from(map['transform'] as Map))
          : const CanvasTransform(scale: 0.5),
      opacity: (map['opacity'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type == ClipType.video ? 'video' : 'photo',
      'remoteUrl': remoteUrl,
      'order': order,
      'transform': transform.toMap(),
      'opacity': opacity,
    };
  }
}
