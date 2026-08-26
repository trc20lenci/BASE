import '../../domain/entities/project_entity.dart';
import '../../domain/entities/project_format.dart';
import '../../domain/repositories/project_repository.dart';
import '../datasources/project_remote_data_source.dart';
import '../models/project_model.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final ProjectRemoteDataSource _remote;

  ProjectRepositoryImpl(this._remote);

  @override
  Stream<List<ProjectEntity>> watchUserProjects(String ownerId) {
    return _remote.watchUserProjects(ownerId);
  }

  @override
  Future<ProjectEntity> createProject({
    required String ownerId,
    required String title,
    required ProjectFormat format,
  }) {
    return _remote.createProject(ownerId: ownerId, title: title, format: format);
  }

  @override
  Future<void> renameProject({
    required String projectId,
    required String newTitle,
  }) {
    return _remote.renameProject(projectId: projectId, newTitle: newTitle);
  }

  @override
  Future<void> deleteProject(String projectId) {
    return _remote.deleteProject(projectId);
  }

  @override
  Future<ProjectEntity> duplicateProject(ProjectEntity source) {
    return _remote.duplicateProject(ProjectModel.fromEntity(source));
  }
}
