import '../entities/project_entity.dart';
import '../entities/project_format.dart';

/// Контракт работы с проектами. Реализация — в data/repositories,
/// использует Firestore (коллекция projects, где каждый документ
/// принадлежит владельцу через ownerId).
abstract class ProjectRepository {
  /// Живой поток списка проектов текущего пользователя, отсортированный
  /// по дате изменения (последние изменённые — выше). Используется на
  /// Home, чтобы список обновлялся сразу после создания/удаления.
  Stream<List<ProjectEntity>> watchUserProjects(String ownerId);

  Future<ProjectEntity> createProject({
    required String ownerId,
    required String title,
    required ProjectFormat format,
  });

  Future<void> renameProject({
    required String projectId,
    required String newTitle,
  });

  Future<void> deleteProject(String projectId);

  Future<ProjectEntity> duplicateProject(ProjectEntity source);
}
