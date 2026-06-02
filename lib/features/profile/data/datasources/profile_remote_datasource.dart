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
        .eq('id', userId)
        .single();
    return ProfileModel.fromJson(response);
  }

  Future<void> updateNickname(String userId, String nickname) async {
    await client
        .from('profiles')
        .update({'nickname': nickname})
        .eq('id', userId);
  }

  Future<void> updateFullName(String userId, String? fullName) async {
    await client
        .from('profiles')
        .update({'full_name': fullName})
        .eq('id', userId);
  }

  Future<void> updateBio(String userId, String? bio) async {
    await client
        .from('profiles')
        .update({'bio': bio})
        .eq('id', userId);
  }

  Future<void> updateCountryCode(String userId, String? countryCode) async {
    await client
        .from('profiles')
        .update({'country_code': countryCode})
        .eq('id', userId);
  }

  Future<ProfileModel> updateProfile(String userId, Map<String, dynamic> data) async {
    // 🔥 Only update editable fields (exclude protected: title, display_id, created_at)
    final editableData = <String, dynamic>{};
    if (data.containsKey('nickname')) editableData['nickname'] = data['nickname'];
    if (data.containsKey('avatar_url')) editableData['avatar_url'] = data['avatar_url'];
    if (data.containsKey('full_name')) editableData['full_name'] = data['full_name'];
    if (data.containsKey('bio')) editableData['bio'] = data['bio'];
    if (data.containsKey('country_code')) editableData['country_code'] = data['country_code'];
    
    final response = await client
        .from('profiles')
        .update(editableData)
        .eq('id', userId)
        .select()
        .single();
    
    return ProfileModel.fromJson(response);
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
        .eq('id', userId);
  }
}