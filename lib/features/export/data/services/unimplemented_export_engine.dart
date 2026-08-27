import 'dart:io';
import '../../../editor/domain/entities/editor_timeline_entity.dart';
import '../../domain/entities/export_quality.dart';
import '../../domain/repositories/video_export_engine.dart';

/// Реализация "по умолчанию": явно сообщает, что нативный движок рендера
/// ещё не подключён, вместо того чтобы падать невнятной ошибкой глубоко
/// в стеке вызовов. Замените на реальную реализацию (см. комментарий в
/// VideoExportEngine) когда будет выбрана библиотека кодирования видео.
class UnimplementedExportEngine implements VideoExportEngine {
  const UnimplementedExportEngine();

  @override
  Future<File> render({
    required EditorTimelineEntity timeline,
    required ExportQuality quality,
    required void Function(double progress) onProgress,
  }) {
    throw UnimplementedError(
      'Движок рендера видео ещё не подключён. См. комментарий в '
      'VideoExportEngine — нужно реализовать этот интерфейс конкретной '
      'библиотекой кодирования (актуальный форк ffmpeg-kit или нативный '
      'MediaCodec/AVFoundation-пайплайн) и подставить в '
      'videoExportEngineProvider.',
    );
  }
}
