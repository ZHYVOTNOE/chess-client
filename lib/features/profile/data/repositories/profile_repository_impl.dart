import 'dart:io';
import '../datasources/profile_remote_datasource.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/entities/profile_user.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDatasource remote;

  ProfileRepositoryImpl(this.remote);

  @override
  Future<UserProfile> getProfile(String userId) async {
    final model = await remote.getProfile(userId);
    return model.toEntity();
  }

  @override
  Future<void> updateNickname(String userId, String nickname) =>
      remote.updateNickname(userId, nickname);

  @override
  Future<void> updateAvatar(String userId, File file) async {
    final url = await remote.uploadAvatar(userId, file);
    await remote.updateAvatarUrl(userId, url);
  }
}