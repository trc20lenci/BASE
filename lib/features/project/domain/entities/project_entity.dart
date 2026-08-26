import 'package:equatable/equatable.dart';
import 'project_format.dart';

/// Проект видео. Согласно ТЗ хранит:
/// ID, название, дату создания, дату изменения, формат.
///
/// Содержимое таймлайна (клипы/фото/текст) — отдельная сущность
/// (см. features/editor), т.к. её жизненный цикл и способ хранения
/// (потенциально большой JSON) отличаются от лёгких метаданных проекта,
/// которые показываются списком на Home.
class ProjectEntity extends Equatable {
  final String id;
  final String ownerId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ProjectFormat format;
  final String? thumbnailUrl;

  const ProjectEntity({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.format,
    this.thumbnailUrl,
  });

  ProjectEntity copyWith({
    String? title,
    DateTime? updatedAt,
    String? thumbnailUrl,
  }) {
    return ProjectEntity(
      id: id,
      ownerId: ownerId,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      format: format,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    );
  }

  @override
  List<Object?> get props =>
      [id, ownerId, title, createdAt, updatedAt, format, thumbnailUrl];
}
