import 'dart:io';
import '../repositories/profile_repository.dart';

/// Usecase: загрузка/смена аватара пользователя.
/// Возвращает публичный URL из Supabase Storage.
class UploadAvatarUseCase {
  final ProfileRepository repository;

  const UploadAvatarUseCase(this.repository);

  Future<String> call({
    required String userId,
    required File imageFile,
  }) {
    return repository.uploadAvatar(userId: userId, imageFile: imageFile);
  }
}
