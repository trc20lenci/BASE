import '../repositories/project_repository.dart';

/// Usecase: переименование проекта.
class RenameProjectUseCase {
  final ProjectRepository repository;

  const RenameProjectUseCase(this.repository);

  Future<void> call({
    required String projectId,
    required String newTitle,
  }) {
    return repository.renameProject(projectId: projectId, newTitle: newTitle);
  }
}
