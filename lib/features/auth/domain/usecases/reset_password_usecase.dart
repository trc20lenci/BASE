import '../repositories/auth_repository.dart';

/// Usecase: восстановление пароля через email.
class ResetPasswordUseCase {
  final AuthRepository repository;

  const ResetPasswordUseCase(this.repository);

  Future<void> call({required String email}) {
    return repository.sendPasswordResetEmail(email: email);
  }
}
