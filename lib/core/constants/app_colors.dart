import 'package:flutter/material.dart';

/// Палитра BASE.
///
/// Приложение работает только в тёмной теме — согласно ТЗ интерфейс должен
/// выглядеть как профессиональный видеоредактор, а не учебный проект,
/// поэтому мы не поддерживаем светлую тему на этом этапе.
class AppColors {
  AppColors._();

  // Фоновые слои (от самого глубокого к самому верхнему)
  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF141414);
  static const Color surfaceElevated = Color(0xFF1E1E1E);
  static const Color surfaceHighlight = Color(0xFF2A2A2A);

  // Акцент — используем нейтральный "электрический" акцент,
  // который хорошо читается поверх видео-превью.
  static const Color accent = Color(0xFF5B8CFF);
  static const Color accentPressed = Color(0xFF4A73D9);

  // Текст
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFA0A0A0);
  static const Color textDisabled = Color(0xFF5C5C5C);

  // Статусы
  static const Color error = Color(0xFFFF5C5C);
  static const Color success = Color(0xFF4CD97B);

  // Таймлайн / редактор
  static const Color timelineTrack = Color(0xFF1C1C1C);
  static const Color timelineClipVideo = Color(0xFF2E3A55);
  static const Color timelineClipPhoto = Color(0xFF3A2E55);
  static const Color timelinePlayhead = Color(0xFFFFFFFF);

  static const Color divider = Color(0xFF262626);
  static const Color overlay = Color(0x99000000);
}
