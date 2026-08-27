import '../entities/editor_timeline_entity.dart';
import '../repositories/timeline_repository.dart';

/// Usecase: сохранение таймлайна проекта (вызывается при выходе из
/// редактора и перед экспортом).
class SaveTimelineUseCase {
  final TimelineRepository repository;

  const SaveTimelineUseCase(this.repository);

  Future<void> call(EditorTimelineEntity timeline) {
    return repository.saveTimeline(timeline);
  }
}
