import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../editor/domain/entities/editor_timeline_entity.dart';
import '../../data/services/unimplemented_export_engine.dart';
import '../../domain/entities/export_progress.dart';
import '../../domain/entities/export_quality.dart';
import '../../domain/repositories/video_export_engine.dart';
import '../../domain/usecases/render_video_usecase.dart';
import '../../domain/usecases/save_video_to_gallery_usecase.dart';

/// Точка подключения реального движка рендера — см. подробный комментарий
/// в VideoExportEngine. Замените UnimplementedExportEngine() на реальную
/// реализацию, когда движок будет готов; весь остальной код (usecases,
/// UI, сохранение в галерею) менять не придётся.
final videoExportEngineProvider = Provider<VideoExportEngine>((ref) {
  return const UnimplementedExportEngine();
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
    required ExportQuality quality,
  }) async {
    state = const ExportProgress(status: ExportStatus.rendering, progress: 0);
    try {
      final file = await _render(
        timeline: timeline,
        quality: quality,
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
