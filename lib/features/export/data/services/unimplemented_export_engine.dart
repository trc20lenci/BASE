import 'dart:io';
import '../../../editor/domain/entities/editor_timeline_entity.dart';
import '../../../project/domain/entities/project_format.dart';
import '../../domain/entities/export_settings.dart';
import '../../domain/repositories/video_export_engine.dart';

/// Реализация "по умолчанию" — на случай, если понадобится временно
/// отключить FfmpegExportEngine (например, для сборки без нативных
/// FFmpeg-библиотек). Явно сообщает причину вместо падения с невнятной
/// ошибкой глубоко в стеке.
class UnimplementedExportEngine implements VideoExportEngine {
  const UnimplementedExportEngine();

  @override
  Future<File> render({
    required EditorTimelineEntity timeline,
    required ProjectFormat format,
    required ExportSettings settings,
    required void Function(double progress) onProgress,
  }) {
    throw UnimplementedError(
      'Движок рендера видео отключён. Подставьте FfmpegExportEngine() в '
      'videoExportEngineProvider (lib/features/export/presentation/providers/'
      'export_providers.dart).',
    );
  }
}
