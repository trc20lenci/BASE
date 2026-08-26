import '../entities/project_entity.dart';
import '../repositories/project_repository.dart';

/// Usecase: подписка на список проектов пользователя (для Home).
class WatchProjectsUseCase {
  final ProjectRepository repository;

  const WatchProjectsUseCase(this.repository);

  Stream<List<ProjectEntity>> call(String ownerId) {
    return repository.watchUserProjects(ownerId);
  }
}
