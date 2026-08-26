/// Единая точка правды для названий коллекций Firestore и путей Storage.
///
/// Вынесено отдельно, чтобы при подключении Firebase (этап 4 ТЗ) и при
/// работе с проектами (этап 5) datasources не оперировали "магическими
/// строками" россыпью по всему коду.
class FirebaseConstants {
  FirebaseConstants._();

  // Firestore
  static const String usersCollection = 'users';
  static const String projectsCollection = 'projects';

  // Storage
  static String avatarPath(String userId) => 'avatars/$userId.jpg';
  static String projectExportPath(String userId, String projectId) =>
      'exports/$userId/$projectId.mp4';
  static String projectMediaFolder(String userId, String projectId) =>
      'projects/$userId/$projectId/media';

  // Дефолтный аватар (ассет приложения, а не Storage —
  // грузится локально, пока пользователь не загрузит свой)
  static const String defaultAvatarAsset = 'assets/images/default_avatar.png';
}
