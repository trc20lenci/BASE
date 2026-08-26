import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../../../core/constants/firebase_constants.dart';
import '../models/user_model.dart';

/// Единственное место в приложении, которое напрямую обращается к
/// firebase_auth и cloud_firestore для операций авторизации.
///
/// Repository (data-слой) зависит от этого класса, а не наоборот — это
/// позволяет замокать источник данных в тестах.
class AuthRemoteDataSource {
  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRemoteDataSource({
    fb.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? fb.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<fb.User?> get authStateChanges => _auth.authStateChanges();

  fb.User? get currentFirebaseUser => _auth.currentUser;

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _fetchUserDocument(credential.user!.uid);
  }

  Future<UserModel> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    // 1. Создаём пользователя в Firebase Authentication.
    //    Firebase сам генерирует уникальный UID — используем его как
    //    "уникальный ID пользователя" из ТЗ.
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;

    // 2. Сохраняем профиль в Firestore.
    final model = UserModel(
      id: uid,
      username: username,
      email: email,
      avatarUrl: FirebaseConstants.defaultAvatarAsset,
    );

    await _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(uid)
        .set(model.toMap());

    return model;
  }

  Future<void> sendPasswordResetEmail({required String email}) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() {
    return _auth.signOut();
  }

  Future<UserModel> _fetchUserDocument(String uid) async {
    final doc = await _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(uid)
        .get();

    if (!doc.exists) {
      throw StateError(
        'Документ пользователя не найден в Firestore для uid=$uid',
      );
    }

    return UserModel.fromMap({...doc.data()!, 'id': uid});
  }

  Future<UserModel?> fetchUserByUid(String uid) async {
    final doc = await _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(uid)
        .get();
    if (!doc.exists) return null;
    return UserModel.fromMap({...doc.data()!, 'id': uid});
  }
}
