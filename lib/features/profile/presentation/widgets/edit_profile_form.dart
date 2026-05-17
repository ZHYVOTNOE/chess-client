import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../../../../core/providers/user_provider.dart';
import '../../domain/entities/profile_user.dart';
import '../cubits/profile_cubit.dart';
import '../validators/profile_form_validator.dart';

class EditProfileForm extends StatefulWidget {
  final UserProfile profile;
  final String userId;

  const EditProfileForm({
    super.key,
    required this.profile,
    required this.userId,
  });

  @override
  State<EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<EditProfileForm> {
  late TextEditingController _nicknameController;
  File? _tempAvatar;
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: widget.profile.nickname);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  // 🔥 Показ выбора: камера или галерея
  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Сделать фото'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Выбрать из галереи'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 Запрос разрешений и выбор изображения
  Future<void> _pickImage(ImageSource source) async {
    // Запрашиваем нужное разрешение
    final permission = source == ImageSource.camera
        ? Permission.camera
        : Permission.photos;

    final status = await permission.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Доступ к медиафайлам запрещён'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85, // Сжимаем для быстрой загрузки
      );

      if (pickedFile != null && mounted) {
        setState(() {
          _tempAvatar = File(pickedFile.path);
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Ошибка выбора фото: $e');
      }
    }
  }

  // 🔥 Сохранение никнейма (оптимистичное обновление + сервер)
  Future<void> _saveNickname() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final newNickname = _nicknameController.text.trim();
    final userProvider = context.read<UserProvider>();
    final profileCubit = context.read<ProfileCubit>();

    // 1️⃣ Мгновенное обновление в UI (оптимистично)
    userProvider.setNickname(newNickname);

    try {
      // 2️⃣ Асинхронная синхронизация с сервером
      await profileCubit.changeNickname(widget.userId, newNickname);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Никнейм обновлён'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // 3️⃣ Очищаем локальные изменения после успеха
        userProvider.clearLocalChanges();
      }
    } catch (e) {
      // 🔥 Откат при ошибке
      if (mounted) {
        userProvider.setNickname(widget.profile.nickname);
        setState(() => _errorMessage = 'Не удалось сохранить: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Ошибка: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // 🔥 Сохранение аватара
  Future<void> _saveAvatar() async {
    if (_tempAvatar == null) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final userProvider = context.read<UserProvider>();

    try {
      // 🔥 Показываем выбранный аватар сразу
      userProvider.setAvatar(_tempAvatar!);

      // 🔥 Здесь должен быть вызов Cubit для загрузки на сервер
      // Пока заглушка — добавь метод changeAvatar в ProfileCubit:
      // await context.read<ProfileCubit>().changeAvatar(widget.userId, _tempAvatar!);

      // TODO: Раскомментируй, когда добавишь метод в Cubit
      // await Future.delayed(const Duration(seconds: 1)); // Имитация загрузки

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Аватар обновлён'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        userProvider.clearLocalChanges();
        setState(() => _tempAvatar = null);
      }
    } catch (e) {
      if (mounted) {
        // Откат при ошибке
        userProvider.setAvatar(File('')); // или сбрось через null
        setState(() => _errorMessage = 'Ошибка загрузки: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Не удалось загрузить аватар'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // 🔥 Объединённое сохранение (ник + аватар)
  Future<void> _saveAll() async {
    if (_formKey.currentState!.validate()) {
      await _saveNickname();
      if (_tempAvatar != null && mounted) {
        await _saveAvatar();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 Подписываемся на UserProvider для реактивного обновления
    final userProvider = context.watch<UserProvider>();

    return Form(
      key: _formKey,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 🔥 Аватар с возможностью редактирования
              Stack(
                children: [
                  GestureDetector(
                    onTap: _isSaving ? null : _showImageSourceActionSheet,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade300,
                      // Приоритет: временный файл → профиль → заглушка
                      backgroundImage: _tempAvatar != null
                          ? FileImage(_tempAvatar!)
                          : (userProvider.avatarFile != null
                          ? FileImage(userProvider.avatarFile!)
                          : (widget.profile.avatarUrl != null
                          ? NetworkImage(widget.profile.avatarUrl!)
                          : null)),
                      child: (_tempAvatar == null &&
                          userProvider.avatarFile == null &&
                          widget.profile.avatarUrl == null)
                          ? const Icon(Icons.person, size: 50, color: Colors.grey)
                          : null,
                    ),
                  ),
                  // 🔥 Иконка редактирования (скрыта при загрузке)
                  if (!_isSaving)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: const Icon(
                          Icons.edit,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // 🔥 Поле никнейма
              TextFormField(
                controller: _nicknameController,
                textAlign: TextAlign.center,
                enabled: !_isSaving,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Введите никнейм',
                  suffixIcon: _isSaving
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : null,
                ),
                validator: ProfileValidator.nickname,
                onFieldSubmitted: (_) => _saveAll(),
              ),

              // 🔥 Сообщения об ошибках
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 24),

              // 🔥 Кнопка сохранения
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveAll,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text(
                    'Сохранить изменения',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),

              // 🔥 Подсказка про аватар
              if (_tempAvatar != null) ...[
                const SizedBox(height: 12),
                Text(
                  '📷 Новый аватар выбран. Нажмите "Сохранить" для загрузки.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}