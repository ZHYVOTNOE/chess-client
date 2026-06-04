import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

class ProfileRemoteDatasource {
  final SupabaseClient _supabase;

  // 🔥 ИСПРАВЛЕНО: убрана опечатка 'z'
  ProfileRemoteDatasource(this._supabase);

  Future<ProfileModel> getProfile(String userId) async {
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return ProfileModel.fromJson(response);
  }

  Future<void> updateNickname(String userId, String nickname) async {
    await _supabase
        .from('profiles')
        .update({'nickname': nickname})
        .eq('id', userId);
  }

  Future<void> updateFullName(String userId, String? fullName) async {
    await _supabase
        .from('profiles')
        .update({'full_name': fullName})
        .eq('id', userId);
  }

  Future<void> updateBio(String userId, String? bio) async {
    await _supabase
        .from('profiles')
        .update({'bio': bio})
        .eq('id', userId);
  }

  Future<void> updateCountryCode(String userId, String? countryCode) async {
    await _supabase
        .from('profiles')
        .update({'country_code': countryCode})
        .eq('id', userId);
  }

  Future<ProfileModel> updateProfile(String userId, Map<String, dynamic> data) async {
    final editableData = <String, dynamic>{};
    if (data.containsKey('nickname')) {
      editableData['nickname'] = (data['nickname'] as String).trim();
    }
    if (data.containsKey('avatar_url')) editableData['avatar_url'] = data['avatar_url'];
    if (data.containsKey('full_name')) editableData['full_name'] = data['full_name'];
    if (data.containsKey('bio')) editableData['bio'] = data['bio'];
    if (data.containsKey('country_code')) editableData['country_code'] = data['country_code'];

    try {
      final response = await _supabase
          .from('profiles')
          .update(editableData)
          .eq('id', userId)
          .select()
          .single();

      return ProfileModel.fromJson(response);
    } catch (e) {
      // 🔥 Обработка ошибки уникальности
      if (e is PostgrestException && e.code == '23505') {
        throw NicknameAlreadyTakenException();
      }
      rethrow;
    }
  }

  Future<String> uploadAvatar(String userId, File file) async {
    try {
      // 🔥 ИСПРАВЛЕНО: используем path.extension для надежного определения расширения
      final ext = path.extension(file.path).toLowerCase();
      if (ext.isEmpty) {
        throw Exception('Файл не имеет расширения');
      }

      final fileName = 'avatar$ext'; // avatar.png, avatar.jpg и т.д.
      final filePath = '$userId/$fileName';

      // Загружаем в Storage с upsert: true
      await _supabase.storage
          .from('avatars')
          .upload(filePath, file, fileOptions: const FileOptions(upsert: true));

      // Получаем Public URL
      final publicUrl = _supabase.storage.from('avatars').getPublicUrl(filePath);

      // Добавляем таймстемп для обхода кеша Flutter
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final urlWithCacheBust = '$publicUrl?v=$timestamp';

      debugPrint('📸 Avatar uploaded: $urlWithCacheBust');

      return urlWithCacheBust;
    } catch (e) {
      debugPrint('❌ Avatar upload error: $e');
      throw Exception('Ошибка загрузки аватара: $e');
    }
  }

  // 🔥 ИСПРАВЛЕНО: client → _supabase
  Future<void> updateAvatarUrl(String userId, String avatarUrl) async {
    debugPrint('📝 Updating avatar_url in profiles table for user $userId: $avatarUrl');
    await _supabase
        .from('profiles')
        .update({'avatar_url': avatarUrl})
        .eq('id', userId);
    debugPrint('✅ Avatar URL updated successfully in profiles table');
  }

  Future<bool> isNicknameAvailable(String nickname, String currentUserId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id')
          .eq('nickname', nickname.trim())
          .neq('id', currentUserId)
          .maybeSingle();

      return response == null;
    } catch (e) {
      debugPrint('❌ Error checking nickname availability: $e');
      throw Exception('Ошибка проверки доступности никнейма: $e');
    }
  }
}

class NicknameAlreadyTakenException implements Exception {
  @override
  String toString() => 'Этот никнейм уже занят';
}