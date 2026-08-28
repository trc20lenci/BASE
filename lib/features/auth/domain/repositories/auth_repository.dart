import '../entities/user_entity.dart';

/// Контракт репозитория авторизации.
///
/// Domain-слой описывает ЧТО нужно приложению, а КАК это реализовано
/// (через Supabase Auth) знает только data-слой (см. AuthRepositoryImpl).
abstract class AuthRepository {
  Stream<UserEntity?> authStateChanges();

  UserEntity? get currentUser;

  Future<UserEntity> signIn({
    required String email,
    required String password,
  });

  Future<UserEntity> signUp({
    required String username,
    required String email,
    required String password,
  });

  Future<void> sendPasswordResetEmail({required String email});

  Future<void> signOut();
}
