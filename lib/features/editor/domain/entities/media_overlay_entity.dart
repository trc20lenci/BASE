import 'package:equatable/equatable.dart';
import 'canvas_transform.dart';
import 'clip_type.dart';

/// Слой наложения (picture-in-picture) — фото или видео, отображается
/// ПОВЕРХ основного клипа на холсте (в отличие от обычного клипа
/// таймлайна, наложение не занимает своё время на дорожке, а
/// накладывается одновременно с текущим показываемым клипом).
///
/// Порядок [order] определяет, какое наложение рисуется выше (последнее
/// в списке — самое верхнее), если их несколько.
class MediaOverlayEntity extends Equatable {
  final String id;
  final ClipType type;
  final String? localPath;
  final String? remoteUrl;
  final int order;
  final CanvasTransform transform;

  /// Прозрачность наложения (0.0..1.0) — часто используется, чтобы
  /// приглушить наложенный слой относительно основного видео.
  final double opacity;

  const MediaOverlayEntity({
    required this.id,
    required this.type,
    this.localPath,
    this.remoteUrl,
    required this.order,
    this.transform = const CanvasTransform(scale: 0.5),
    this.opacity = 1.0,
  });

  String? get displayPath => localPath ?? remoteUrl;

  bool get isUploaded => remoteUrl != null;

  MediaOverlayEntity copyWith({
    String? localPath,
    String? remoteUrl,
    int? order,
    CanvasTransform? transform,
    double? opacity,
  }) {
    return MediaOverlayEntity(
      id: id,
      type: type,
      localPath: localPath ?? this.localPath,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      order: order ?? this.order,
      transform: transform ?? this.transform,
      opacity: opacity ?? this.opacity,
    );
  }

  @override
  List<Object?> get props => [id, type, localPath, remoteUrl, order, transform, opacity];
}
