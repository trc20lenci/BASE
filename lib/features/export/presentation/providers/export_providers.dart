import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../editor/domain/entities/editor_timeline_entity.dart';
import '../../../project/domain/entities/project_format.dart';
import '../../data/services/ffmpeg_export_engine.dart';
import '../../domain/entities/export_progress.dart';
import '../../domain/entities/export_settings.dart';
import '../../domain/repositories/video_export_engine.dart';
import '../../domain/usecases/render_video_usecase.dart';
import '../../domain/usecases/save_video_to_gallery_usecase.dart';

/// Точка подключения движка рендера. По умолчанию — FfmpegExportEngine
/// (см. комментарий в самом файле про выбор ffmpeg_kit_flutter_new_video
/// и его ограничения). При необходимости временно отключить рендер —
/// замените на UnimplementedExportEngine().
final videoExportEngineProvider = Provider<VideoExportEngine>((ref) {
  return const FfmpegExportEngine();
});

final renderVideoUseCaseProvider = Provider<RenderVideoUseCase>((ref) {
  return RenderVideoUseCase(ref.watch(videoExportEngineProvider));
});

final saveVideoToGalleryUseCaseProvider = Provider<SaveVideoToGalleryUseCase>((ref) {
  return const SaveVideoToGalleryUseCase();
});

class ExportController extends StateNotifier<ExportProgress> {
  final RenderVideoUseCase _render;
  final SaveVideoToGalleryUseCase _saveToGallery;

  ExportController(this._render, this._saveToGallery) : super(const ExportProgress());

  Future<void> exportAndSave({
    required EditorTimelineEntity timeline,
    required ProjectFormat format,
    required ExportSettings settings,
  }) async {
    state = const ExportProgress(status: ExportStatus.rendering, progress: 0);
    try {
      final file = await _render(
        timeline: timeline,
        format: format,
        settings: settings,
        onProgress: (p) => state = state.copyWith(progress: p),
      );

      state = state.copyWith(status: ExportStatus.savingToGallery, resultFile: file);
      await _saveToGallery(file);

      state = state.copyWith(status: ExportStatus.done, progress: 1);
    } catch (e) {
      state = state.copyWith(status: ExportStatus.error, errorMessage: e.toString());
    }
  }

  void reset() => state = const ExportProgress();
}

final exportControllerProvider =
    StateNotifierProvider.autoDispose<ExportController, ExportProgress>((ref) {
  return ExportController(
    ref.watch(renderVideoUseCaseProvider),
    ref.watch(saveVideoToGalleryUseCaseProvider),
  );
});
