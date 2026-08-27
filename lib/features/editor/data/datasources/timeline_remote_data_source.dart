import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../domain/entities/clip_type.dart';
import '../models/text_overlay_model.dart';
import '../models/timeline_clip_model.dart';

/// Таймлайн проекта хранится ОТДЕЛЬНЫМ документом
/// projects/{projectId}/timeline/data (а не полем в самом документе
/// проекта), потому что:
/// 1. Список проектов на Home читает только лёгкие метаданные (title,
///    format, даты) и не должен подтягивать потенциально большой массив
///    клипов и текстовых слоёв.
/// 2. Обновления таймлайна (частые, при каждом изменении в редакторе) не
///    должны триггерить лишние перерисовки списка проектов на Home,
///    который слушает projects-коллекцию через watchUserProjects.
class TimelineRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  TimelineRemoteDataSource({FirebaseFirestore? firestore, FirebaseStorage? storage})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  DocumentReference<Map<String, dynamic>> _timelineDoc(String projectId) {
    return _firestore
        .collection(FirebaseConstants.projectsCollection)
        .doc(projectId)
        .collection('timeline')
        .doc('data');
  }

  Future<Map<String, dynamic>?> loadTimeline(String projectId) async {
    final doc = await _timelineDoc(projectId).get();
    return doc.data();
  }

  Future<void> saveTimeline({
    required String projectId,
    required List<TimelineClipModel> clips,
    required List<TextOverlayModel> textOverlays,
  }) async {
    await _timelineDoc(projectId).set({
      'clips': clips.map((c) => c.toMap()).toList(),
      'textOverlays': textOverlays.map((t) => t.toMap()).toList(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    // Обновляем updatedAt самого проекта, чтобы Home корректно сортировал
    // "недавно изменённые" проекты даже если менялось только содержимое
    // таймлайна, а не название.
    await _firestore
        .collection(FirebaseConstants.projectsCollection)
        .doc(projectId)
        .update({'updatedAt': Timestamp.fromDate(DateTime.now())});
  }

  Future<String> uploadClipMedia({
    required String ownerId,
    required String projectId,
    required String clipId,
    required ClipType type,
    required File file,
  }) async {
    final extension = type == ClipType.video ? 'mp4' : 'jpg';
    final path = '${FirebaseConstants.projectMediaFolder(ownerId, projectId)}/$clipId.$extension';
    final ref = _storage.ref(path);
    await ref.putFile(file);
    return ref.getDownloadURL();
  }
}
