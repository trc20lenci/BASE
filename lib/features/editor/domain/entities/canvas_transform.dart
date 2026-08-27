import 'package:equatable/equatable.dart';

/// Трансформация элемента на холсте.
///
/// Одна сущность покрывает три требования ТЗ для работы с холстом
/// (перемещение/масштабирование/поворот — [dx], [dy], [scale], [rotation])
/// и отдельно "Кадрирование" для фото — через нормализованный
/// прямоугольник [cropLeft]..[cropBottom] в диапазоне 0..1 от исходного
/// изображения. Крop и transform хранятся раздельно, потому что это
/// разные операции в ТЗ и должны редактироваться независимо: сброс
/// масштаба не должен сбрасывать кадрирование и наоборот.
class CanvasTransform extends Equatable {
  final double scale;
  final double rotation; // радианы
  final double dx; // смещение центра относительно центра холста, в px
  final double dy;

  final double cropLeft; // 0..1
  final double cropTop;
  final double cropRight; // 0..1, > cropLeft
  final double cropBottom; // 0..1, > cropTop

  const CanvasTransform({
    this.scale = 1.0,
    this.rotation = 0.0,
    this.dx = 0.0,
    this.dy = 0.0,
    this.cropLeft = 0.0,
    this.cropTop = 0.0,
    this.cropRight = 1.0,
    this.cropBottom = 1.0,
  });

  static const identity = CanvasTransform();

  CanvasTransform copyWith({
    double? scale,
    double? rotation,
    double? dx,
    double? dy,
    double? cropLeft,
    double? cropTop,
    double? cropRight,
    double? cropBottom,
  }) {
    return CanvasTransform(
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      dx: dx ?? this.dx,
      dy: dy ?? this.dy,
      cropLeft: cropLeft ?? this.cropLeft,
      cropTop: cropTop ?? this.cropTop,
      cropRight: cropRight ?? this.cropRight,
      cropBottom: cropBottom ?? this.cropBottom,
    );
  }

  Map<String, dynamic> toMap() => {
        'scale': scale,
        'rotation': rotation,
        'dx': dx,
        'dy': dy,
        'cropLeft': cropLeft,
        'cropTop': cropTop,
        'cropRight': cropRight,
        'cropBottom': cropBottom,
      };

  factory CanvasTransform.fromMap(Map<String, dynamic> map) {
    return CanvasTransform(
      scale: (map['scale'] as num?)?.toDouble() ?? 1.0,
      rotation: (map['rotation'] as num?)?.toDouble() ?? 0.0,
      dx: (map['dx'] as num?)?.toDouble() ?? 0.0,
      dy: (map['dy'] as num?)?.toDouble() ?? 0.0,
      cropLeft: (map['cropLeft'] as num?)?.toDouble() ?? 0.0,
      cropTop: (map['cropTop'] as num?)?.toDouble() ?? 0.0,
      cropRight: (map['cropRight'] as num?)?.toDouble() ?? 1.0,
      cropBottom: (map['cropBottom'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  List<Object?> get props =>
      [scale, rotation, dx, dy, cropLeft, cropTop, cropRight, cropBottom];
}
