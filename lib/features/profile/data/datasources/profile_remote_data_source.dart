import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../core/constants/firebase_constants.dart';

/// Работа с профилем на уровне Firebase: обновление username и
/// загрузка/смена аватара в Firebase Storage.
class ProfileRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  ProfileRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  /// Загружает файл аватара в Storage по пути avatars/{userId}.jpg,
  /// затем сохраняет полученный downloadUrl в документ пользователя
  /// в Firestore, и возвращает этот URL.
  Future<String> uploadAvatar({
    required String userId,
    required File imageFile,
  }) async {
    final ref = _storage.ref(FirebaseConstants.avatarPath(userId));
    await ref.putFile(imageFile);
    final downloadUrl = await ref.getDownloadURL();

    await _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(userId)
        .update({'avatarUrl': downloadUrl});

    return downloadUrl;
  }

  Future<void> updateUsername({
    required String userId,
    required String username,
  }) {
    return _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(userId)
        .update({'username': username});
  }
}
