import '../repositories/project_repository.dart';

/// Usecase: удаление проекта.
class DeleteProjectUseCase {
  final ProjectRepository repository;

  const DeleteProjectUseCase(this.repository);

  Future<void> call(String projectId) {
    return repository.deleteProject(projectId);
  }
}
