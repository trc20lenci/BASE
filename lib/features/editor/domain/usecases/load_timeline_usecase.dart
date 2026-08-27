import '../entities/editor_timeline_entity.dart';
import '../repositories/timeline_repository.dart';

/// Usecase: загрузка таймлайна проекта при входе в редактор.
class LoadTimelineUseCase {
  final TimelineRepository repository;

  const LoadTimelineUseCase(this.repository);

  Future<EditorTimelineEntity> call(String projectId) {
    return repository.loadTimeline(projectId);
  }
}
