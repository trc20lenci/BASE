import 'package:flutter/material.dart';
import '../../domain/entities/text_overlay_entity.dart';

class TextOverlayModel extends TextOverlayEntity {
  const TextOverlayModel({
    required super.id,
    required super.text,
    super.fontSize,
    super.color,
    super.dx,
    super.dy,
  });

  factory TextOverlayModel.fromEntity(TextOverlayEntity e) {
    return TextOverlayModel(
      id: e.id,
      text: e.text,
      fontSize: e.fontSize,
      color: e.color,
      dx: e.dx,
      dy: e.dy,
    );
  }

  factory TextOverlayModel.fromMap(Map<String, dynamic> map) {
    return TextOverlayModel(
      id: map['id'] as String,
      text: map['text'] as String,
      fontSize: (map['fontSize'] as num).toDouble(),
      color: Color(map['color'] as int),
      dx: (map['dx'] as num).toDouble(),
      dy: (map['dy'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'fontSize': fontSize,
      'color': color.value,
      'dx': dx,
      'dy': dy,
    };
  }
}
