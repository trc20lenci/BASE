/// Единая точка правды для названий таблиц PostgreSQL (Supabase Database)
/// и путей Supabase Storage.
///
/// Вынесено отдельно, чтобы datasources не оперировали "магическими
/// строками" россыпью по всему коду. Соответствующая SQL-схема — в
/// `supabase/schema.sql` в корне репозитория.
class SupabaseConstants {
  SupabaseConstants._();

  // PostgreSQL-таблицы
  static const String profilesTable = 'profiles';
  static const String projectsTable = 'projects';
  static const String projectTimelinesTable = 'project_timelines';

  // Storage-бакеты
  static const String avatarsBucket = 'avatars';
  static const String projectMediaBucket = 'project-media';
  static const String exportsBucket = 'exports';

  // Пути внутри бакетов
  static String avatarPath(String userId) => '$userId.jpg';

  static String projectMediaPath(String ownerId, String projectId, String fileName) =>
      '$ownerId/$projectId/$fileName';

  static String exportPath(String ownerId, String projectId) =>
      '$ownerId/$projectId.mp4';

  // Дефолтный аватар — локальный ассет приложения, а не файл в Storage,
  // грузится сразу, пока пользователь не загрузит свой.
  static const String defaultAvatarAsset = 'assets/images/default_avatar.png';
}
