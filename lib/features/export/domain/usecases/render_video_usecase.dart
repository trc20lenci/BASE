import 'dart:io';
import '../../../editor/domain/entities/editor_timeline_entity.dart';
import '../../../project/domain/entities/project_format.dart';
import '../entities/export_settings.dart';
import '../repositories/video_export_engine.dart';

class RenderVideoUseCase {
  final VideoExportEngine engine;

  const RenderVideoUseCase(this.engine);

  Future<File> call({
    required EditorTimelineEntity timeline,
    required ProjectFormat format,
    required ExportSettings settings,
    required void Function(double progress) onProgress,
  }) {
    return engine.render(timeline: timeline, format: format, settings: settings, onProgress: onProgress);
  }
}
