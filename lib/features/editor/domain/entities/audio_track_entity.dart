import 'package:equatable/equatable.dart';

/// Собственная звуковая дорожка проекта (наложенная музыка/звук поверх
/// видео, отдельно от звука самих клипов — см. TimelineClipEntity.volume/
/// isMuted для звука клипа).
///
/// Ограничение этой версии (см. итоговое сообщение в чате): дорожка
/// сохраняется, отображается на таймлайне и её громкость реально
/// регулируется, но синхронное проигрывание вместе с видео в
/// предпросмотре и микширование в финальный экспорт ещё не подключены —
/// реальное микширование происходит на этапе рендера в
/// VideoExportEngine, который сам пока не реализован (см. README).
class AudioTrackEntity extends Equatable {
  final String id;
  final String? localPath;
  final String? remoteUrl;
  final int order;
  final String fileName;
  final int durationMs;
  final double volume;

  const AudioTrackEntity({
    required this.id,
    this.localPath,
    this.remoteUrl,
    required this.order,
    required this.fileName,
    required this.durationMs,
    this.volume = 1.0,
  });

  String? get displayPath => localPath ?? remoteUrl;

  bool get isUploaded => remoteUrl != null;

  AudioTrackEntity copyWith({
    String? localPath,
    String? remoteUrl,
    int? order,
    double? volume,
  }) {
    return AudioTrackEntity(
      id: id,
      localPath: localPath ?? this.localPath,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      order: order ?? this.order,
      fileName: fileName,
      durationMs: durationMs,
      volume: volume ?? this.volume,
    );
  }

  @override
  List<Object?> get props => [id, localPath, remoteUrl, order, fileName, durationMs, volume];
}
