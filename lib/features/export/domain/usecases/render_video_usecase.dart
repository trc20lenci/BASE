import 'dart:io';
import '../../../editor/domain/entities/editor_timeline_entity.dart';
import '../entities/export_settings.dart';
import '../repositories/video_export_engine.dart';

class RenderVideoUseCase {
  final VideoExportEngine engine;

  const RenderVideoUseCase(this.engine);

  Future<File> call({
    required EditorTimelineEntity timeline,
    required ExportSettings settings,
    required void Function(double progress) onProgress,
  }) {
    return engine.render(timeline: timeline, settings: settings, onProgress: onProgress);
  }
}
