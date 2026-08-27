import 'dart:io';
import 'package:gal/gal.dart';

/// Usecase: сохранение готового MP4 в галерею устройства.
/// Обёрнут в usecase (а не вызывается напрямую из UI), чтобы presentation
/// не зависел от конкретного пакета `gal` — при необходимости замены
/// пакета меняется только этот файл.
class SaveVideoToGalleryUseCase {
  const SaveVideoToGalleryUseCase();

  Future<void> call(File videoFile) {
    return Gal.putVideo(videoFile.path, album: 'BASE');
  }
}
