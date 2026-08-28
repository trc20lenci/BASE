import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;

  AuthRepositoryImpl(this._remote);

  @override
  Stream<UserEntity?> authStateChanges() {
    // Стримим только изменение факта авторизации (вошёл/вышел).
    // Полный профиль (username/avatarUrl) подтягивается отдельно через
    // таблицу profiles — так Splash не блокируется лишним ожиданием.
    return _remote.authStateChanges.asyncMap((sbUser) async {
      if (sbUser == null) return null;
      final model = await _remote.fetchProfileByUid(
        sbUser.id,
        fallbackEmail: sbUser.email ?? '',
      );
      return model ??
          UserModel(
            id: sbUser.id,
            username: '',
            email: sbUser.email ?? '',
            avatarUrl: '',
          );
    });
  }

  @override
  UserEntity? get currentUser {
    final sbUser = _remote.currentSupabaseUser;
    if (sbUser == null) return null;
    return UserEntity(
      id: sbUser.id,
      username: '',
      email: sbUser.email ?? '',
      avatarUrl: '',
    );
  }

  @override
  Future<UserEntity> signIn({
    required String email,
    required String password,
  }) {
    return _remote.signIn(email: email, password: password);
  }

  @override
  Future<UserEntity> signUp({
    required String username,
    required String email,
    required String password,
  }) {
    return _remote.signUp(username: username, email: email, password: password);
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) {
    return _remote.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> signOut() {
    return _remote.signOut();
  }
}
