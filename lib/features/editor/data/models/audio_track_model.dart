import '../../domain/entities/audio_track_entity.dart';

class AudioTrackModel extends AudioTrackEntity {
  const AudioTrackModel({
    required super.id,
    super.localPath,
    super.remoteUrl,
    required super.order,
    required super.fileName,
    required super.durationMs,
    super.volume,
  });

  factory AudioTrackModel.fromEntity(AudioTrackEntity e) {
    return AudioTrackModel(
      id: e.id,
      localPath: e.localPath,
      remoteUrl: e.remoteUrl,
      order: e.order,
      fileName: e.fileName,
      durationMs: e.durationMs,
      volume: e.volume,
    );
  }

  factory AudioTrackModel.fromMap(Map<String, dynamic> map) {
    return AudioTrackModel(
      id: map['id'] as String,
      remoteUrl: map['remoteUrl'] as String?,
      order: map['order'] as int,
      fileName: map['fileName'] as String? ?? 'audio.mp3',
      durationMs: map['durationMs'] as int? ?? 0,
      volume: (map['volume'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'remoteUrl': remoteUrl,
      'order': order,
      'fileName': fileName,
      'durationMs': durationMs,
      'volume': volume,
    };
  }
}
