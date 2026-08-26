import '../repositories/profile_repository.dart';

/// Usecase: обновление имени пользователя.
class UpdateUsernameUseCase {
  final ProfileRepository repository;

  const UpdateUsernameUseCase(this.repository);

  Future<void> call({
    required String userId,
    required String username,
  }) {
    return repository.updateUsername(userId: userId, username: username);
  }
}
