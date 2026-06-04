// lib/features/profile/presentation/screens/edit_profile_screen.dart
import 'dart:async'; // 🔥 НОВОЕ: для Timer
import 'dart:io';

import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/profile_user.dart';
import '../cubits/profile_cubit.dart';
import '../cubits/profile_state.dart';

final countryParser = CountryParser();

class EditProfileScreen extends StatefulWidget {
  final UserProfile initialProfile;

  const EditProfileScreen({super.key, required this.initialProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _bioController = TextEditingController();
  Country? _selectedCountry;
  final ImagePicker _picker = ImagePicker();
  File? _tempAvatar;
  final RegExp _nicknameRegex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
  bool _isUpdatingCountry = false;

  // 🔥 НОВЫЕ ПОЛЯ для проверки уникальности никнейма
  Timer? _debounce;
  String? _nicknameAvailabilityMessage;
  bool _isCheckingNickname = false;
  bool _isSaving = false; // 🔥 Защита от двойного сохранения

  @override
  void initState() {
    super.initState();
    _nicknameController.text = widget.initialProfile.nickname;
    _fullNameController.text = widget.initialProfile.fullName ?? '';
    _bioController.text = widget.initialProfile.bio ?? '';
    if (widget.initialProfile.countryCode != null) {
      _selectedCountry = CountryParser.parseCountryCode(widget.initialProfile.countryCode!);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel(); // 🔥 Обязательно отменяем таймер
    _nicknameController.dispose();
    _fullNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // 🔥 НОВЫЙ МЕТОД: Асинхронная проверка никнейма с debounce
  void _checkNicknameAvailability(String? value) {
    _debounce?.cancel();

    // Если ник слишком короткий или невалидный — сбрасываем статус
    if (value == null || value.trim().length < 3 || !_nicknameRegex.hasMatch(value.trim())) {
      if (mounted) {
        setState(() {
          _nicknameAvailabilityMessage = null;
          _isCheckingNickname = false;
        });
      }
      return;
    }

    // Если ник не изменился (пользователь не менял свой текущий ник) — не проверяем
    if (value.trim() == widget.initialProfile.nickname) {
      if (mounted) {
        setState(() {
          _nicknameAvailabilityMessage = null;
          _isCheckingNickname = false;
        });
      }
      return;
    }

    setState(() => _isCheckingNickname = true);

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      try {
        final cubit = context.read<ProfileCubit>();
        // 🔥 Вызываем публичный метод кубита
        final isAvailable = await cubit.checkNicknameAvailability(
          value.trim(),
          userId,
        );

        if (mounted) {
          setState(() {
            _isCheckingNickname = false;
            _nicknameAvailabilityMessage = isAvailable ? null : 'Этот никнейм уже занят';
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isCheckingNickname = false;
            _nicknameAvailabilityMessage = 'Ошибка проверки доступности';
          });
        }
      }
    });
  }

  void _showImageSourceActionSheet() {
    if (!mounted) return;
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

  Future<void> _pickImage(ImageSource source) async {
    if (!mounted) return;

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
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        setState(() => _tempAvatar = File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка выбора фото: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate() || !mounted) return;

    // Ждём завершения дебаунс-проверки
    if (_isCheckingNickname) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⏳ Подождите, проверяем никнейм...')),
      );
      return;
    }

    if (_nicknameAvailabilityMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Исправьте ошибки перед сохранением'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isSaving = true);
    final cubit = context.read<ProfileCubit>();

    try {
      final currentNickname = _nicknameController.text.trim();

      // 🔥 ФИНАЛЬНАЯ серверная проверка перед сохранением
      // Даже если ник не менялся — пропускаем проверку
      if (currentNickname != widget.initialProfile.nickname) {
        final isAvailable = await cubit.checkNicknameAvailability(currentNickname, userId);
        if (!isAvailable) {
          if (mounted) {
            setState(() {
              _nicknameAvailabilityMessage = 'Этот никнейм уже занят';
              _isSaving = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Этот никнейм уже занят'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      if (_tempAvatar != null) {
        await cubit.changeAvatar(userId, _tempAvatar!);
      }

      final currentState = cubit.state;
      final actualProfile = (currentState is ProfileLoaded)
          ? currentState.profile
          : (currentState is ProfileUpdated)
          ? currentState.profile
          : widget.initialProfile;

      final updatedProfile = actualProfile.copyWith(
        nickname: currentNickname,
        fullName: _fullNameController.text.trim().isEmpty
            ? null
            : _fullNameController.text.trim(),
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        countryCode: _selectedCountry?.countryCode,
      );

      await cubit.updateProfile(userId, updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Профиль обновлён'),
            backgroundColor: Colors.green,
          ),
        );
        await cubit.loadProfile(userId);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Ошибка сохранения: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _updateCountryViaGPS() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final cubit = context.read<ProfileCubit>();

    setState(() => _isUpdatingCountry = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Определение местоположения...')),
    );

    try {
      final countryCode = await cubit.locationService.getCountryCode();
      if (countryCode != null && mounted) {
        setState(() {
          _selectedCountry = CountryParser.parseCountryCode(countryCode);
          _isUpdatingCountry = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Страна обновлена'), backgroundColor: Colors.green),
        );
      } else if (mounted) {
        setState(() => _isUpdatingCountry = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Не удалось определить страну'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdatingCountry = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showCountryPicker() {
    if (!mounted) return;
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      onSelect: (Country country) {
        setState(() => _selectedCountry = country);
      },
    );
  }

  // 🔥 НОВЫЙ МЕТОД: Определяем иконку для поля никнейма
  Widget? _buildNicknameSuffixIcon() {
    if (_isCheckingNickname) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_nicknameAvailabilityMessage != null) {
      return const Icon(Icons.error, color: Colors.red);
    }

    // Зелёная галочка, только если ник валидный и НЕ равен текущему
    final currentText = _nicknameController.text.trim();
    if (currentText.length >= 3 &&
        _nicknameRegex.hasMatch(currentText) &&
        currentText != widget.initialProfile.nickname) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактировать профиль'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
                : const Icon(Icons.check),
            onPressed: _isSaving ? null : _saveProfile,
          ),
        ],
      ),
      // 🔥 BlocConsumer вместо BlocBuilder для обработки ошибок
      body: BlocConsumer<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading && _isSaving) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Avatar
                  Center(
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: _showImageSourceActionSheet,
                          child: CircleAvatar(
                            key: ValueKey('edit_avatar_${_tempAvatar?.path ??
                                ((state is ProfileLoaded || state is ProfileUpdated)
                                    ? (state is ProfileLoaded ? state.profile : (state as ProfileUpdated).profile).avatarUrl
                                    : widget.initialProfile.avatarUrl)}'),
                            radius: 50,
                            backgroundColor: Colors.grey.shade300,
                            backgroundImage: _tempAvatar != null
                                ? FileImage(_tempAvatar!)
                                : (state is ProfileLoaded || state is ProfileUpdated)
                                ? ((state is ProfileLoaded ? state.profile : (state as ProfileUpdated).profile).avatarUrl != null &&
                                (state is ProfileLoaded ? state.profile : (state as ProfileUpdated).profile).avatarUrl!.isNotEmpty
                                ? NetworkImage((state is ProfileLoaded ? state.profile : (state as ProfileUpdated).profile).avatarUrl!) as ImageProvider
                                : null)
                                : (widget.initialProfile.avatarUrl != null && widget.initialProfile.avatarUrl!.isNotEmpty
                                ? NetworkImage(widget.initialProfile.avatarUrl!) as ImageProvider
                                : null),
                            child: (_tempAvatar == null &&
                                ((state is! ProfileLoaded && state is! ProfileUpdated) ||
                                    ((state is ProfileLoaded || state is ProfileUpdated) &&
                                        ((state is ProfileLoaded ? state.profile : (state as ProfileUpdated).profile).avatarUrl == null ||
                                            (state is ProfileLoaded ? state.profile : (state as ProfileUpdated).profile).avatarUrl!.isEmpty))) &&
                                (widget.initialProfile.avatarUrl == null || widget.initialProfile.avatarUrl!.isEmpty))
                                ? const Icon(Icons.person, size: 50, color: Colors.grey)
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _showImageSourceActionSheet,
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: Theme.of(context).primaryColor,
                              child: const Icon(Icons.edit, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 🔥 Nickname с асинхронной проверкой
                  TextFormField(
                    controller: _nicknameController,
                    enabled: !_isSaving,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
                      LengthLimitingTextInputFormatter(20),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Никнейм',
                      hintText: 'Введите никнейм',
                      helperText: '3-20 символов: буквы, цифры, _',
                      border: const OutlineInputBorder(),
                      suffixIcon: _buildNicknameSuffixIcon(), // 🔥 Динамическая иконка
                      errorText: _nicknameAvailabilityMessage, // 🔥 Ошибка доступности
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Никнейм обязателен';
                      }
                      if (value.trim().length < 3 || value.trim().length > 20) {
                        return 'Никнейм должен быть 3-20 символов';
                      }
                      if (!_nicknameRegex.hasMatch(value.trim())) {
                        return 'Только буквы, цифры и подчеркивание';
                      }
                      // 🔥 Блокируем валидацию, если ник занят
                      if (_nicknameAvailabilityMessage != null) {
                        return _nicknameAvailabilityMessage;
                      }
                      return null;
                    },
                    onChanged: _checkNicknameAvailability, // 🔥 Проверка при вводе
                  ),
                  const SizedBox(height: 16),

                  // Full Name
                  TextFormField(
                    controller: _fullNameController,
                    enabled: !_isSaving,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\p{L}\s\-]', unicode: true)),
                      LengthLimitingTextInputFormatter(50),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Полное имя (необязательно)',
                      hintText: 'Введите имя и фамилию',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bio
                  TextFormField(
                    controller: _bioController,
                    enabled: !_isSaving,
                    maxLines: 4,
                    maxLength: 255,
                    decoration: const InputDecoration(
                      labelText: 'О себе',
                      hintText: 'Расскажите о себе',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 16),

                  // Country Selection Row
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _isSaving ? null : _showCountryPicker,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              child: Row(
                                children: [
                                  if (_selectedCountry != null) ...[
                                    Text(
                                      _selectedCountry!.flagEmoji,
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _selectedCountry!.name,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ] else
                                    const Text(
                                      'Страна не выбрана',
                                      style: TextStyle(fontSize: 16, color: Colors.grey),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const VerticalDivider(width: 1),
                        IconButton(
                          icon: _isUpdatingCountry
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Icon(Icons.location_on),
                          onPressed: (_isUpdatingCountry || _isSaving) ? null : _updateCountryViaGPS,
                          tooltip: 'Определить по GPS',
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: _isSaving ? null : _showCountryPicker,
                          tooltip: 'Выбрать страну',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}