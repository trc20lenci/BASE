import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../domain/entities/clip_type.dart';

/// Результат импорта одного файла — готов для передачи в
/// EditorController.addMediaClip.
class ImportedMedia {
  final File file;
  final ClipType type;
  final int durationMs;

  const ImportedMedia({required this.file, required this.type, required this.durationMs});
}

/// Инкапсулирует работу с image_picker и получение длительности видео
/// (через кратковременную инициализацию VideoPlayerController), чтобы
/// экран редактора не знал деталей платформенных API.
class MediaImportService {
  final _picker = ImagePicker();

  Future<ImportedMedia?> pickPhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked == null) return null;
    // Фото по умолчанию показывается 3 секунды на таймлайне — стандартное
    // поведение большинства мобильных видеоредакторов для статичных фото.
    return ImportedMedia(file: File(picked.path), type: ClipType.photo, durationMs: 3000);
  }

  Future<ImportedMedia?> pickVideo() async {
    final picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked == null) return null;

    final file = File(picked.path);
    final controller = VideoPlayerController.file(file);
    try {
      await controller.initialize();
      final durationMs = controller.value.duration.inMilliseconds;
      return ImportedMedia(file: file, type: ClipType.video, durationMs: durationMs);
    } finally {
      await controller.dispose();
    }
  }
}
