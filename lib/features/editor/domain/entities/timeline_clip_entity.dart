import 'package:equatable/equatable.dart';
import 'canvas_transform.dart';
import 'clip_type.dart';

/// Клип на таймлайне — фото или видео.
///
/// [localPath] заполняется сразу при импорте (для мгновенного превью),
/// [remoteUrl] — после фоновой загрузки файла в Supabase Storage (нужен,
/// чтобы таймлайн переживал переустановку приложения / открытие с другого
/// устройства). При сохранении таймлайна в Firestore используется именно
/// [remoteUrl] — см. TimelineRemoteDataSource.
class TimelineClipEntity extends Equatable {
  final String id;
  final ClipType type;
  final String? localPath;
  final String? remoteUrl;

  /// Порядок клипа на таймлайне (0, 1, 2, ...).
  final int order;

  /// Полная длительность исходного файла в миллисекундах.
  /// Для фото — фиксированная длительность показа (по умолчанию 3000ms).
  final int sourceDurationMs;

  /// Точка начала обрезки внутри исходного файла (мс от начала).
  final int trimStartMs;

  /// Точка конца обрезки внутри исходного файла (мс от начала).
  final int trimEndMs;

  final CanvasTransform transform;

  const TimelineClipEntity({
    required this.id,
    required this.type,
    this.localPath,
    this.remoteUrl,
    required this.order,
    required this.sourceDurationMs,
    required this.trimStartMs,
    required this.trimEndMs,
    this.transform = CanvasTransform.identity,
  });

  /// Длительность клипа на таймлайне после обрезки.
  int get durationMs => trimEndMs - trimStartMs;

  /// Путь для немедленного отображения — предпочитаем локальный файл,
  /// т.к. он не требует сети.
  String? get displayPath => localPath ?? remoteUrl;

  bool get isUploaded => remoteUrl != null;

  TimelineClipEntity copyWith({
    String? localPath,
    String? remoteUrl,
    int? order,
    int? trimStartMs,
    int? trimEndMs,
    CanvasTransform? transform,
  }) {
    return TimelineClipEntity(
      id: id,
      type: type,
      localPath: localPath ?? this.localPath,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      order: order ?? this.order,
      sourceDurationMs: sourceDurationMs,
      trimStartMs: trimStartMs ?? this.trimStartMs,
      trimEndMs: trimEndMs ?? this.trimEndMs,
      transform: transform ?? this.transform,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        localPath,
        remoteUrl,
        order,
        sourceDurationMs,
        trimStartMs,
        trimEndMs,
        transform,
      ];
}
