import 'dart:io';
import '../entities/clip_type.dart';
import '../repositories/timeline_repository.dart';

/// Usecase: фоновая загрузка импортированного медиафайла в Storage.
class UploadClipMediaUseCase {
  final TimelineRepository repository;

  const UploadClipMediaUseCase(this.repository);

  Future<String> call({
    required String ownerId,
    required String projectId,
    required String clipId,
    required ClipType type,
    required File file,
  }) {
    return repository.uploadClipMedia(
      ownerId: ownerId,
      projectId: projectId,
      clipId: clipId,
      type: type,
      file: file,
    );
  }
}
