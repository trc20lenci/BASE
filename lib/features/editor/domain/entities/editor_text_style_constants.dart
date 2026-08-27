import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// По ТЗ инструмент "Текст" на первом этапе использует ровно один
/// встроенный шрифт — дополнительные шрифты сознательно не добавляются.
/// Используем подключаемый шрифт через google_fonts (кэшируется локально
/// при первом использовании), чтобы не требовать вручную класть .ttf в
/// assets. Если у продукта уже есть фирменный шрифт-файл — заменить эту
/// функцию на TextStyle(fontFamily: 'BaseSans').
class EditorTextStyleConstants {
  EditorTextStyleConstants._();

  static TextStyle style({required double fontSize, required Color color}) {
    return GoogleFonts.montserrat(
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.w600,
    );
  }

  /// Палитра цветов инструмента "Текст" — простые свотчи вместо
  /// полноценного color-picker'а: ТЗ описывает только "изменение цвета
  /// текста" без требования произвольного HEX-ввода.
  static const List<Color> colorSwatches = [
    Color(0xFFFFFFFF),
    Color(0xFF000000),
    Color(0xFFFF5C5C),
    Color(0xFF5B8CFF),
    Color(0xFF4CD97B),
    Color(0xFFFFD54C),
    Color(0xFFFF8AD8),
  ];
}
