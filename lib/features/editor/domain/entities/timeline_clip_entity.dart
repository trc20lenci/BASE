import 'package:equatable/equatable.dart';
import 'canvas_transform.dart';
import 'clip_type.dart';

/// Клип на таймлайне — фото или видео.
///
/// [localPath] заполняется сразу при импорте (для мгновенного превью),
/// [remoteUrl] — после фоновой загрузки файла в Supabase Storage (нужен,
/// чтобы таймлайн переживал переустановку приложения / открытие с другого
/// устройства). При сохранении таймлайна используется именно [remoteUrl]
/// — см. TimelineRemoteDataSource.
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

  /// Список ключевых кадров ("ромбиков") для плавной анимации масштаба/
  /// позиции внутри клипа. Пустой список — клип статичен (обычное
  /// поведение). См. KeyframeEntity.
  final List<KeyframeEntity> keyframes;

  /// Громкость собственной звуковой дорожки клипа (0.0..1.0).
  final double volume;

  /// Звук клипа выключен полностью (быстрый тумблер, независимый от volume,
  /// чтобы можно было временно заглушить, не теряя настроенную громкость).
  final bool isMuted;

  /// Множитель скорости воспроизведения (0.5x, 1x, 1.5x, 2x и т.д.).
  final double speed;

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
    this.keyframes = const [],
    this.volume = 1.0,
    this.isMuted = false,
    this.speed = 1.0,
  });

  /// Длительность клипа на таймлайне после обрезки (без учёта speed —
  /// это длительность исходного материала, используемая для позиции на
  /// таймлайне; фактическое время воспроизведения = durationMs / speed).
  int get durationMs => trimEndMs - trimStartMs;

  /// Путь для немедленного отображения — предпочитаем локальный файл,
  /// т.к. он не требует сети.
  String? get displayPath => localPath ?? remoteUrl;

  bool get isUploaded => remoteUrl != null;

  bool get hasKeyframes => keyframes.length >= 2;

  TimelineClipEntity copyWith({
    String? localPath,
    String? remoteUrl,
    int? order,
    int? trimStartMs,
    int? trimEndMs,
    CanvasTransform? transform,
    List<KeyframeEntity>? keyframes,
    double? volume,
    bool? isMuted,
    double? speed,
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
      keyframes: keyframes ?? this.keyframes,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      speed: speed ?? this.speed,
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
        keyframes,
        volume,
        isMuted,
        speed,
      ];
}

/// Ключевой кадр ("ромбик") — точка на таймлайне клипа со своим
/// CanvasTransform. Между двумя соседними ключевыми кадрами трансформация
/// плавно интерполируется (сейчас — линейно; пресеты плавности/графики
/// ускорения, как в референсе, это отдельный следующий шаг — см. пометку
/// в EditorController.addKeyframe).
class KeyframeEntity extends Equatable {
  /// Позиция внутри клипа в мс (относительно trimStartMs).
  final int positionMs;
  final CanvasTransform transform;

  const KeyframeEntity({required this.positionMs, required this.transform});

  KeyframeEntity copyWith({int? positionMs, CanvasTransform? transform}) {
    return KeyframeEntity(
      positionMs: positionMs ?? this.positionMs,
      transform: transform ?? this.transform,
    );
  }

  Map<String, dynamic> toMap() => {'positionMs': positionMs, 'transform': transform.toMap()};

  factory KeyframeEntity.fromMap(Map<String, dynamic> map) => KeyframeEntity(
        positionMs: map['positionMs'] as int,
        transform: CanvasTransform.fromMap(Map<String, dynamic>.from(map['transform'] as Map)),
      );

  @override
  List<Object?> get props => [positionMs, transform];
}
