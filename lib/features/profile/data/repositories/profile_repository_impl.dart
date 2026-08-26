import 'dart:io';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remote;

  ProfileRepositoryImpl(this._remote);

  @override
  Future<String> uploadAvatar({
    required String userId,
    required File imageFile,
  }) {
    return _remote.uploadAvatar(userId: userId, imageFile: imageFile);
  }

  @override
  Future<void> updateUsername({
    required String userId,
    required String username,
  }) {
    return _remote.updateUsername(userId: userId, username: username);
  }
}
