import 'dart:io';
import '../../../editor/domain/entities/editor_timeline_entity.dart';
import '../../../project/domain/entities/project_format.dart';
import '../entities/export_settings.dart';

/// Абстракция движка рендера итогового MP4 из таймлайна проекта.
///
/// Конкретная реализация — [FfmpegExportEngine]
/// (lib/features/export/data/services/ffmpeg_export_engine.dart),
/// построенная на пакете `ffmpeg_kit_flutter_new_video`. Контракт
/// остаётся отдельным интерфейсом, чтобы при необходимости сменить
/// движок (другой форк ffmpeg-kit, нативный MediaCodec/AVFoundation-
/// пайплайн) не пришлось трогать usecases/UI — только реализацию.
abstract class VideoExportEngine {
  /// Рендерит таймлайн в единый MP4-файл согласно [settings].
  /// [format] — формат проекта (16:9/9:16/1:1/4:5), нужен для расчёта
  /// итогового разрешения кадра, т.к. [ExportQuality] хранит только
  /// "уровень" разрешения (720p/1080p/...), а не конкретные ширину/высоту
  /// для конкретной ориентации проекта.
  /// [onProgress] вызывается с значением 0..1 по ходу рендера.
  Future<File> render({
    required EditorTimelineEntity timeline,
    required ProjectFormat format,
    required ExportSettings settings,
    required void Function(double progress) onProgress,
  });
}
