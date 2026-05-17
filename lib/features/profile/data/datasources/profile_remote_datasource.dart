import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

class ProfileRemoteDatasource {
  final SupabaseClient client;

  // 🔥 Делаем client public для использования в репозитории
  SupabaseClient get supabase => client;

  ProfileRemoteDatasource(this.client);

  Future<ProfileModel> getProfile(String userId) async {
    final response = await client
        .from('profiles')
        .select()
        .eq('user_id', userId)
        .single();
    return ProfileModel.fromJson(response);
  }

  Future<void> updateNickname(String userId, String nickname) async {
    await client
        .from('profiles')
        .update({'nickname': nickname})
        .eq('user_id', userId);
  }

  Future<String> uploadAvatar(String userId, File file) async {
    final ext = path.extension(file.path);
    final fileName = 'avatars/$userId$ext';
    await client.storage
        .from('avatars')
        .upload(fileName, file, fileOptions: FileOptions(upsert: true));
    return client.storage.from('avatars').getPublicUrl(fileName);
  }

  // 🔥 Добавляем отдельный метод для обновления URL аватара
  Future<void> updateAvatarUrl(String userId, String avatarUrl) async {
    await client
        .from('profiles')
        .update({'avatar_url': avatarUrl})
        .eq('user_id', userId);
  }
}