import '../repositories/auth_repository.dart';

/// Usecase: выход из аккаунта.
class SignOutUseCase {
  final AuthRepository repository;

  const SignOutUseCase(this.repository);

  Future<void> call() {
    return repository.signOut();
  }
}
