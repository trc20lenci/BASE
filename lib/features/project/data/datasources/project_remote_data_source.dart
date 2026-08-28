import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:uuid/uuid.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../domain/entities/project_format.dart';
import '../models/project_model.dart';

class ProjectRemoteDataSource {
  final sb.SupabaseClient _client;
  final Uuid _uuid;

  ProjectRemoteDataSource({sb.SupabaseClient? client, Uuid? uuid})
      : _client = client ?? sb.Supabase.instance.client,
        _uuid = uuid ?? const Uuid();

  /// Живой список проектов пользователя через Supabase Realtime
  /// (`.stream()` подписывается на изменения таблицы через Postgres
  /// логическую репликацию — аналог Firestore snapshots, но поверх
  /// обычного PostgreSQL).
  Stream<List<ProjectModel>> watchUserProjects(String ownerId) {
    return _client
        .from(SupabaseConstants.projectsTable)
        .stream(primaryKey: ['id'])
        .eq('owner_id', ownerId)
        .order('updated_at', ascending: false)
        .map((rows) => rows.map(ProjectModel.fromMap).toList());
  }

  Future<ProjectModel> createProject({
    required String ownerId,
    required String title,
    required ProjectFormat format,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    final model = ProjectModel(
      id: id,
      ownerId: ownerId,
      title: title,
      createdAt: now,
      updatedAt: now,
      format: format,
    );

    await _client.from(SupabaseConstants.projectsTable).insert(model.toMap());
    return model;
  }

  Future<void> renameProject({
    required String projectId,
    required String newTitle,
  }) {
    return _client.from(SupabaseConstants.projectsTable).update({
      'title': newTitle,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', projectId);
  }

  Future<void> deleteProject(String projectId) {
    return _client.from(SupabaseConstants.projectsTable).delete().eq('id', projectId);
  }

  Future<ProjectModel> duplicateProject(ProjectModel source) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    final copy = ProjectModel(
      id: id,
      ownerId: source.ownerId,
      title: '${source.title} (копия)',
      createdAt: now,
      updatedAt: now,
      format: source.format,
      thumbnailUrl: source.thumbnailUrl,
    );

    await _client.from(SupabaseConstants.projectsTable).insert(copy.toMap());
    // Примечание: копирование содержимого таймлайна (медиафайлов в
    // Storage) — отдельная операция, см. TimelineRepository; на уровне
    // метаданных проекта дублируется только сама запись.
    return copy;
  }
}
