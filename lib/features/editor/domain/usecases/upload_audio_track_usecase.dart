import 'dart:io';
import '../repositories/timeline_repository.dart';

/// Usecase: фоновая загрузка пользовательского аудиофайла в Storage.
class UploadAudioTrackUseCase {
  final TimelineRepository repository;

  const UploadAudioTrackUseCase(this.repository);

  Future<String> call({
    required String ownerId,
    required String projectId,
    required String trackId,
    required String extension,
    required File file,
  }) {
    return repository.uploadAudioTrack(
      ownerId: ownerId,
      projectId: projectId,
      trackId: trackId,
      extension: extension,
      file: file,
    );
  }
}
