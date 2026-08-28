import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Usecase: регистрация нового пользователя.
///
/// Согласно ТЗ при регистрации создаётся уникальный ID пользователя и
/// данные сохраняются в Supabase — это делает AuthRepositoryImpl
/// (создаёт пользователя в Supabase Auth и строку в таблице profiles).
class SignUpUseCase {
  final AuthRepository repository;

  const SignUpUseCase(this.repository);

  Future<UserEntity> call({
    required String username,
    required String email,
    required String password,
  }) {
    return repository.signUp(username: username, email: email, password: password);
  }
}
