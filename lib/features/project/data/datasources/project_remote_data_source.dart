import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../domain/entities/project_format.dart';
import '../models/project_model.dart';

class ProjectRemoteDataSource {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  ProjectRemoteDataSource({FirebaseFirestore? firestore, Uuid? uuid})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _uuid = uuid ?? const Uuid();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirebaseConstants.projectsCollection);

  Stream<List<ProjectModel>> watchUserProjects(String ownerId) {
    return _collection
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProjectModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<ProjectModel> createProject({
    required String ownerId,
    required String title,
    required ProjectFormat format,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    final model = ProjectModel(
      id: id,
      ownerId: ownerId,
      title: title,
      createdAt: now,
      updatedAt: now,
      format: format,
    );

    await _collection.doc(id).set(model.toMap());
    return model;
  }

  Future<void> renameProject({
    required String projectId,
    required String newTitle,
  }) {
    return _collection.doc(projectId).update({
      'title': newTitle,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> deleteProject(String projectId) {
    return _collection.doc(projectId).delete();
  }

  Future<ProjectModel> duplicateProject(ProjectModel source) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    final copy = ProjectModel(
      id: id,
      ownerId: source.ownerId,
      title: '${source.title} (копия)',
      createdAt: now,
      updatedAt: now,
      format: source.format,
      thumbnailUrl: source.thumbnailUrl,
    );

    await _collection.doc(id).set(copy.toMap());
    // Примечание: копирование содержимого таймлайна (медиафайлов в
    // Storage) будет добавлено вместе с реализацией редактора (этап 6),
    // когда появится структура хранения клипов проекта.
    return copy;
  }
}
