import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Usecase: вход по email и паролю.
///
/// Каждый usecase инкапсулирует один сценарий использования (Single
/// Responsibility) и не содержит ничего, кроме вызова репозитория —
/// вся бизнес-валидация полей делается на уровне presentation (форм),
/// а инфраструктурные ошибки Supabase транслируются репозиторием.
class SignInUseCase {
  final AuthRepository repository;

  const SignInUseCase(this.repository);

  Future<UserEntity> call({
    required String email,
    required String password,
  }) {
    return repository.signIn(email: email, password: password);
  }
}
