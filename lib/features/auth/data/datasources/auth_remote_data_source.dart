import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../../core/constants/supabase_constants.dart';
import '../models/user_model.dart';

/// Единственное место в приложении, которое напрямую обращается к
/// Supabase Auth и таблице `profiles` для операций авторизации.
///
/// Архитектурная заметка: Supabase Auth хранит только учётные данные
/// (email/пароль/UID), а "профильные" поля из ТЗ (имя пользователя,
/// аватар) хранятся отдельной строкой в таблице `profiles`, где
/// `profiles.id` — это тот же UUID, что и `auth.users.id`. Это стандартный
/// паттерн Supabase (в отличие от Firebase, где кастомные поля обычно
/// сразу пишут в Firestore-документ пользователя).
class AuthRemoteDataSource {
  final sb.SupabaseClient _client;

  AuthRemoteDataSource({sb.SupabaseClient? client})
      : _client = client ?? sb.Supabase.instance.client;

  /// Стрим состояния авторизации Supabase (события signedIn/signedOut/
  /// tokenRefreshed и т.д.), преобразованный в поток "текущий пользователь".
  Stream<sb.User?> get authStateChanges =>
      _client.auth.onAuthStateChange.map((event) => event.session?.user);

  sb.User? get currentSupabaseUser => _client.auth.currentUser;

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = response.user;
    if (user == null) {
      throw const sb.AuthException('Не удалось выполнить вход.');
    }
    return _fetchProfile(user.id, fallbackEmail: user.email ?? email);
  }

  Future<UserModel> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    // 1. Создаём пользователя в Supabase Auth. Supabase сам генерирует
    //    уникальный UUID — используем его как "уникальный ID
    //    пользователя" из ТЗ.
    final response = await _client.auth.signUp(email: email, password: password);
    final user = response.user;
    if (user == null) {
      throw const sb.AuthException('Не удалось зарегистрироваться.');
    }

    // 2. Сохраняем профиль в таблице profiles.
    //    upsert (а не insert) — потому что БД-триггер handle_new_user()
    //    (см. supabase/schema.sql) тоже создаёт пустую строку профиля
    //    сразу при появлении записи в auth.users как защитная сетка;
    //    здесь мы досоздаём/дополняем её реальным username.
    final model = UserModel(
      id: user.id,
      username: username,
      email: email,
      avatarUrl: SupabaseConstants.defaultAvatarAsset,
    );

    await _client.from(SupabaseConstants.profilesTable).upsert(model.toMap());

    return model;
  }

  Future<void> sendPasswordResetEmail({required String email}) {
    return _client.auth.resetPasswordForEmail(email);
  }

  Future<void> signOut() {
    return _client.auth.signOut();
  }

  Future<UserModel> _fetchProfile(String uid, {required String fallbackEmail}) async {
    final row = await _client
        .from(SupabaseConstants.profilesTable)
        .select()
        .eq('id', uid)
        .maybeSingle();

    if (row == null) {
      throw StateError('Профиль не найден в таблице profiles для id=$uid');
    }

    return UserModel.fromMap({...row, 'email': fallbackEmail});
  }

  Future<UserModel?> fetchProfileByUid(String uid, {String fallbackEmail = ''}) async {
    final row = await _client
        .from(SupabaseConstants.profilesTable)
        .select()
        .eq('id', uid)
        .maybeSingle();
    if (row == null) return null;
    return UserModel.fromMap({...row, 'email': fallbackEmail});
  }
}
