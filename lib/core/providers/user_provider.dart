// lib/core/providers/user_provider.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/profile/domain/entities/profile_user.dart';
import '../../features/profile/domain/entities/profile_user_impl.dart';

class UserProvider extends ChangeNotifier {
  UserProfile? _profile;
  String? _localNickname;
  File? _localAvatar;
  Map<String, Map<String, int>> _ratings = {}; // {mode: {variant: rating}}

  // 🔥 Геттеры
  String? get userId => _profile?.userId ?? Supabase.instance.client.auth.currentUser?.id;

  String get nickname => _localNickname ?? _profile?.nickname ?? _defaultNickname;

  String? get avatarUrl => _profile?.avatarUrl;
  File? get avatarFile => _localAvatar;

  // 🔥 Форматированный ID: 9 цифр с ведущими нулями
  String get formattedUserId {
    // 🔥 1. Берём числовой id из профиля (из таблицы profiles)
    final profileId = _profile?.id;

    if (profileId != null && profileId.isNotEmpty) {
      // Удаляем всё, кроме цифр (на случай если придёт строка)
      final numeric = profileId.replaceAll(RegExp(r'\D'), '');

      if (numeric.isNotEmpty) {
        // 🔥 Форматируем до 10 цифр: обрезаем лишнее или добавляем нули
        if (numeric.length > 10) {
          return numeric.substring(0, 10);
        } else {
          return numeric.padLeft(10, '0');
        }
      }
    }

    // 🔥 Фолбэк: если профиля нет — возвращаем заглушку
    return '0000000000';
  }

  // 🔥 Дефолтный никнейм: User + ID
  String get _defaultNickname => 'User$formattedUserId';

  Map<String, Map<String, int>> get ratings => _ratings;

  // 🔥 Получение рейтинга для режима
  int? getRating(String mode) {
    return _ratings[mode]?['standard'] ?? _ratings[mode]?.values.first;
  }

  // 🔥 Обновление профиля с сервера
  Future<void> loadProfile() async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return;

    try {
      // 🔥 Загружаем профиль из Supabase
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('user_id', currentUserId)
          .maybeSingle();

      if (response != null) {
        _profile = UserProfileImpl(
          // 🔥 id — числовой из БД (1071675721)
          id: response['id']?.toString() ?? '',

          // userId — UUID из Auth (a1b2c3d4-...) — оставляем для внутренних нужд
          userId: response['user_id']?.toString() ?? Supabase.instance.client.auth.currentUser?.id ?? '',

          nickname: response['nickname'] ?? _defaultNickname,
          avatarUrl: response['avatar_url'],
          joinedAt: response['created_at'] != null
              ? DateTime.parse(response['created_at'])
              : DateTime.now(),
        );

        print('🔍 [loadProfile] response[\'id\']: ${response['id']} (type: ${response['id']?.runtimeType})');
        print('🔍 [loadProfile] _profile?.id: ${_profile?.id}');
        print('🔍 [loadProfile] formattedUserId: ${formattedUserId}');

        // 🔥 Загружаем рейтинги (если есть таблица ratings)
        final ratingsData = await Supabase.instance.client
            .from('ratings')
            .select()
            .eq('user_id', currentUserId);

        _ratings = _parseRatings(ratingsData);
      } else {
        // 🔥 Профиль не найден — создаём дефолтный
        _profile = UserProfileImpl(
          id: '',
          userId: currentUserId,
          nickname: _defaultNickname,
          avatarUrl: null,
          joinedAt: DateTime.now(),
        );
      }

      notifyListeners();
    } catch (e) {
      // Обработка ошибки
      notifyListeners();
    }
  }

  // 🔥 Парсинг рейтингов из Supabase
  Map<String, Map<String, int>> _parseRatings(List<dynamic> data) {
    final result = <String, Map<String, int>>{};
    for (final item in data) {
      final mode = item['mode'] as String? ?? 'blitz';
      final variant = item['variant'] as String? ?? 'standard';
      final rating = item['rating'] as int? ?? 1500;

      result.putIfAbsent(mode, () => {})[variant] = rating;
    }
    return result;
  }

  // 🔥 Установка никнейма (с сохранением на сервер)
  // lib/core/providers/user_provider.dart
  // lib/core/providers/user_provider.dart
  Future<bool> setNickname(String value) async {
    try {
      final currentUserId = userId;
      if (currentUserId == null) return false;

      print('🔍 [setNickname] Start: old=${_profile?.nickname}, new=$value');

      // 🔥 1. Обновляем локально (для мгновенного отклика)
      _localNickname = value;
      notifyListeners();

      // 🔥 2. Отправляем на сервер + получаем обновлённые данные
      final response = await Supabase.instance.client
          .from('profiles')
          .update({'nickname': value})
          .eq('user_id', currentUserId)
          .select() // 🔥 Возвращаем обновлённую запись
          .maybeSingle();

      print('🔍 [setNickname] Supabase response: $response');

      // 🔥 3. Если ответ есть — обновляем профиль из сервера
      if (response != null) {
        _profile = UserProfileImpl(
          id: response['id']?.toString() ?? _profile?.id ?? '',
          userId: response['user_id']?.toString() ?? currentUserId,
          nickname: response['nickname'] ?? value, // 🔥 Берём из ответа!
          avatarUrl: response['avatar_url'] ?? _profile?.avatarUrl,
          joinedAt: response['created_at'] != null
              ? DateTime.parse(response['created_at'])
              : _profile?.joinedAt ?? DateTime.now(),
        );
        print('🔍 [setNickname] Profile updated: ${_profile?.nickname}');
      }

      // 🔥 4. Уведомляем слушателей (КРИТИЧНО!)
      notifyListeners();

      return true;
    } catch (e, stack) {
      print('❌ [setNickname] Error: $e\n$stack');
      notifyListeners();
      return false;
    }
  }

  // 🔥 Установка аватара (с загрузкой на сервер)
  // lib/core/providers/user_provider.dart
  // lib/core/providers/user_provider.dart

  Future<bool> setAvatar(File file) async {
    try {
      final currentUserId = userId;
      if (currentUserId == null) {
        print('❌ [Avatar] User not authenticated');
        return false;
      }

      print('📤 [Avatar] Start upload. User: $currentUserId');

      // 🔥 1. Локальное обновление для мгновенного отклика (оптимистичный UI)
      _localAvatar = file;
      notifyListeners();

      // 🔥 2. Формируем имя файла: просто UUID.jpg (без папок!)
      // Это критично для корректной работы RLS-политик
      final fileName = '$currentUserId/$currentUserId.jpg';

      // 🔥 3. Загружаем файл в Supabase Storage
      try {
        await Supabase.instance.client.storage
            .from('avatars')
            .upload(
          fileName,
          file,
          fileOptions: const FileOptions(
            upsert: true,           // Перезаписываем старую аватарку
            contentType: 'image/jpeg', // Явно указываем тип
            cacheControl: '3600',   // Кэш на 1 час (опционально)
          ),
        );
        print('✅ [Avatar] File uploaded: $fileName');
      } on StorageException catch (e) {
        // 🔥 Обработка ошибок RLS/доступа
        if (e.statusCode == 403) {
          print('❌ [Avatar] RLS Policy blocked upload. Check Storage policies!');
          print('   Hint: Policy should allow: name = auth.uid()::text || \'.jpg\'');
        }
        print('❌ [Avatar] Storage error: ${e.message} (code: ${e.statusCode})');
        return false;
      } catch (e) {
        print('❌ [Avatar] Unexpected upload error: $e');
        return false;
      }

      // 🔥 4. Получаем публичный URL
      // ❗ НЕ добавляй ?t=... для публичных bucket — это ломает запрос (400 ошибка)
      // ✅ Flutter сам кэширует NetworkImage, кэш сбрасывается при изменении виджета
      String publicUrl;
      try {
        publicUrl = Supabase.instance.client.storage
            .from('avatars')
            .getPublicUrl(fileName);
        print('🔗 [Avatar] Public URL: $publicUrl');
      } catch (e) {
        print('❌ [Avatar] Failed to get public URL: $e');
        return false;
      }

      // 🔥 5. Обновляем ссылку в таблице profiles
      try {
        final response = await Supabase.instance.client
            .from('profiles')
            .update({'avatar_url': publicUrl})
            .eq('user_id', currentUserId)
            .select()
            .maybeSingle();

        if (response == null) {
          print('⚠️ [Avatar] Profile update returned no data');
        } else {
          print('✅ [Avatar] DB updated: ${response['avatar_url']}');
        }
      } catch (e) {
        print('❌ [Avatar] Database update failed: $e');
        // Не прерываем: аватар загружен, просто ссылка не обновилась
      }

      // 🔥 6. Обновляем локальную модель профиля
      if (_profile != null) {
        _profile = _profile!.copyWith(avatarUrl: publicUrl);
      }

      // 🔥 7. Финальное уведомление слушателей
      notifyListeners();
      print('🎉 [Avatar] Upload completed successfully');
      return true;

    } catch (e, stackTrace) {
      // 🔥 Глобальный catch для любых непредвиденных ошибок
      print('❌ [Avatar] Critical error: $e\n$stackTrace');

      // Откат локального состояния при ошибке
      _localAvatar = null;
      notifyListeners();
      return false;
    }
  }

  // 🔥 Очистка локальных изменений
  void clearLocalChanges() {
    _localNickname = null;
    _localAvatar = null;
    notifyListeners();
  }

  bool get hasUnsavedChanges => _localNickname != null || _localAvatar != null;


  Timer? _refreshTimer;

  void startBackgroundRefresh() {
    // Обновляем профиль каждые 5 минут
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (userId != null) {
        loadProfile(); // ← Тихая перезагрузка в фоне
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}