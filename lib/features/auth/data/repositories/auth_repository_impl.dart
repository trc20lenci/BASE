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
    // ProfileRepository — так Splash не блокируется ожиданием Firestore.
    return _remote.authStateChanges.asyncMap((fbUser) async {
      if (fbUser == null) return null;
      final model = await _remote.fetchUserByUid(fbUser.uid);
      return model ??
          UserModel(
            id: fbUser.uid,
            username: fbUser.displayName ?? '',
            email: fbUser.email ?? '',
            avatarUrl: '',
          );
    });
  }

  @override
  UserEntity? get currentUser {
    final fbUser = _remote.currentFirebaseUser;
    if (fbUser == null) return null;
    return UserEntity(
      id: fbUser.uid,
      username: fbUser.displayName ?? '',
      email: fbUser.email ?? '',
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
