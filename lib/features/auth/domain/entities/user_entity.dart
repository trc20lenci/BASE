import 'package:equatable/equatable.dart';

/// Доменная сущность пользователя.
///
/// Архитектурное решение: слой domain не знает о Firebase вообще — ни о
/// firebase_auth.User, ни о Firestore DocumentSnapshot. Это позволяет
/// впоследствии сменить бэкенд без переписывания usecases и UI.
class UserEntity extends Equatable {
  final String id; // уникальный ID пользователя (совпадает с Firebase UID)
  final String username;
  final String email;
  final String avatarUrl;

  const UserEntity({
    required this.id,
    required this.username,
    required this.email,
    required this.avatarUrl,
  });

  UserEntity copyWith({
    String? username,
    String? email,
    String? avatarUrl,
  }) {
    return UserEntity(
      id: id,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  List<Object?> get props => [id, username, email, avatarUrl];
}
