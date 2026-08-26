import '../entities/project_entity.dart';
import '../entities/project_format.dart';
import '../repositories/project_repository.dart';

/// Usecase: создание нового проекта с выбранным форматом.
class CreateProjectUseCase {
  final ProjectRepository repository;

  const CreateProjectUseCase(this.repository);

  Future<ProjectEntity> call({
    required String ownerId,
    required String title,
    required ProjectFormat format,
  }) {
    return repository.createProject(ownerId: ownerId, title: title, format: format);
  }
}
