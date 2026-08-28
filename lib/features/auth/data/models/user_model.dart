import '../../domain/entities/user_entity.dart';
import '../../../../core/constants/supabase_constants.dart';

/// Data-модель пользователя.
///
/// Отвечает за (де)сериализацию строки таблицы `profiles` (PostgreSQL).
/// Domain-слой никогда не видит Map<String, dynamic> — только UserEntity.
///
/// Важно: email хранится в Supabase Auth (`auth.users`), а НЕ в таблице
/// `profiles` — это стандартная практика Supabase (auth-схема отделена
/// от публичных таблиц). Поэтому [fromMap] ожидает, что вызывающий код
/// (AuthRemoteDataSource) подмешает email из sb.User в переданную map.
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.username,
    required super.email,
    required super.avatarUrl,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      username: map['username'] as String? ?? '',
      email: map['email'] as String? ?? '',
      avatarUrl: map['avatar_url'] as String? ?? SupabaseConstants.defaultAvatarAsset,
    );
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      username: entity.username,
      email: entity.email,
      avatarUrl: entity.avatarUrl,
    );
  }

  /// Только поля таблицы `profiles` — email туда намеренно не пишется.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'avatar_url': avatarUrl,
    };
  }
}
