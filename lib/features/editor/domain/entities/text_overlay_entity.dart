import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Текстовый слой на холсте. По ТЗ на первом этапе — только добавление
/// текста, один встроенный шрифт (не хранится здесь — применяется
/// глобально из EditorTextStyleConstants), размер, цвет, перемещение.
class TextOverlayEntity extends Equatable {
  final String id;
  final String text;
  final double fontSize;
  final Color color;

  /// Позиция центра текста относительно центра холста, в px.
  final double dx;
  final double dy;

  const TextOverlayEntity({
    required this.id,
    required this.text,
    this.fontSize = 28,
    this.color = Colors.white,
    this.dx = 0,
    this.dy = 0,
  });

  TextOverlayEntity copyWith({
    String? text,
    double? fontSize,
    Color? color,
    double? dx,
    double? dy,
  }) {
    return TextOverlayEntity(
      id: id,
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
      dx: dx ?? this.dx,
      dy: dy ?? this.dy,
    );
  }

  @override
  List<Object?> get props => [id, text, fontSize, color, dx, dy];
}
