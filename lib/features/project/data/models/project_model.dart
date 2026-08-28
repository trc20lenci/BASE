import '../../domain/entities/project_entity.dart';
import '../../domain/entities/project_format.dart';

/// Data-модель проекта — маппинг строки таблицы `projects` (PostgreSQL).
/// Postgres отдаёт timestamptz как ISO-8601 строку через клиент Supabase,
/// поэтому парсим через DateTime.parse (в отличие от Firestore Timestamp).
class ProjectModel extends ProjectEntity {
  const ProjectModel({
    required super.id,
    required super.ownerId,
    required super.title,
    required super.createdAt,
    required super.updatedAt,
    required super.format,
    super.thumbnailUrl,
  });

  factory ProjectModel.fromMap(Map<String, dynamic> map) {
    return ProjectModel(
      id: map['id'] as String,
      ownerId: map['owner_id'] as String,
      title: map['title'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      format: ProjectFormat.fromLabel(map['format'] as String),
      thumbnailUrl: map['thumbnail_url'] as String?,
    );
  }

  factory ProjectModel.fromEntity(ProjectEntity entity) {
    return ProjectModel(
      id: entity.id,
      ownerId: entity.ownerId,
      title: entity.title,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      format: entity.format,
      thumbnailUrl: entity.thumbnailUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'owner_id': ownerId,
      'title': title,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'format': format.label,
      'thumbnail_url': thumbnailUrl,
    };
  }
}
