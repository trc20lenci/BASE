import 'dart:io';

/// Контракт репозитория профиля. Отдельно от AuthRepository, потому что
/// профиль (аватар, username) — это отдельная зона ответственности,
/// которая может меняться независимо от сессии авторизации.
abstract class ProfileRepository {
  Future<String> uploadAvatar({
    required String userId,
    required File imageFile,
  });

  Future<void> updateUsername({
    required String userId,
    required String username,
  });
}
