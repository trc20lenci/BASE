import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/project_entity.dart';
import '../../domain/entities/project_format.dart';

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

  factory ProjectModel.fromMap(String id, Map<String, dynamic> map) {
    return ProjectModel(
      id: id,
      ownerId: map['ownerId'] as String,
      title: map['title'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      format: ProjectFormat.fromLabel(map['format'] as String),
      thumbnailUrl: map['thumbnailUrl'] as String?,
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
      'ownerId': ownerId,
      'title': title,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'format': format.label,
      'thumbnailUrl': thumbnailUrl,
    };
  }
}
