import '../entities/project_entity.dart';
import '../repositories/project_repository.dart';

/// Usecase: дублирование проекта (создаёт копию метаданных;
/// копирование содержимого таймлайна — часть этапа "Редактор").
class DuplicateProjectUseCase {
  final ProjectRepository repository;

  const DuplicateProjectUseCase(this.repository);

  Future<ProjectEntity> call(ProjectEntity source) {
    return repository.duplicateProject(source);
  }
}
