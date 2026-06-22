import 'dart:async';
import 'dart:io';

import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/providers/locale_provider.dart';
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

  Timer? _debounce;
  String? _nicknameAvailabilityMessage;
  bool _isCheckingNickname = false;
  bool _isSaving = false;

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
    _debounce?.cancel();
    _nicknameController.dispose();
    _fullNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _checkNicknameAvailability(String? value, LocaleProvider locale) {
    _debounce?.cancel();

    if (value == null || value.trim().length < 3 || !_nicknameRegex.hasMatch(value.trim())) {
      if (mounted) {
        setState(() {
          _nicknameAvailabilityMessage = null;
          _isCheckingNickname = false;
        });
      }
      return;
    }

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
        final isAvailable = await cubit.checkNicknameAvailability(
          value.trim(),
          userId,
        );

        if (mounted) {
          setState(() {
            _isCheckingNickname = false;
            _nicknameAvailabilityMessage = isAvailable ? null : locale.get('edit_profile_nickname_taken');
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isCheckingNickname = false;
            _nicknameAvailabilityMessage = locale.get('edit_profile_checking_availability');
          });
        }
      }
    });
  }

  void _showImageSourceActionSheet(LocaleProvider locale) {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(locale.get('edit_profile_take_photo')),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera, locale);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(locale.get('edit_profile_choose_from_gallery')),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery, locale);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, LocaleProvider locale) async {
    if (!mounted) return;

    final permission = source == ImageSource.camera
        ? Permission.camera
        : Permission.photos;

    final status = await permission.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${locale.get('edit_profile_media_access_denied')}'),
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
          SnackBar(content: Text('${locale.get('edit_profile_photo_error')}$e')),
        );
      }
    }
  }

  Future<void> _saveProfile(LocaleProvider locale) async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate() || !mounted) return;

    if (_isCheckingNickname) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⏳ ${locale.get('edit_profile_wait_checking')}')),
      );
      return;
    }

    if (_nicknameAvailabilityMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${locale.get('edit_profile_fix_errors')}'),
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

      if (currentNickname != widget.initialProfile.nickname) {
        final isAvailable = await cubit.checkNicknameAvailability(currentNickname, userId);
        if (!isAvailable) {
          if (mounted) {
            setState(() {
              _nicknameAvailabilityMessage = locale.get('edit_profile_nickname_taken');
              _isSaving = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ ${locale.get('edit_profile_nickname_taken')}'),
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
          SnackBar(
            content: Text('✅ ${locale.get('edit_profile_profile_updated')}'),
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
            content: Text('❌ ${locale.get('edit_profile_save_error')}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _updateCountryViaGPS(LocaleProvider locale) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final cubit = context.read<ProfileCubit>();

    setState(() => _isUpdatingCountry = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(locale.get('edit_profile_detecting_location'))),
    );

    try {
      final countryCode = await cubit.locationService.getCountryCode();
      if (countryCode != null && mounted) {
        setState(() {
          _selectedCountry = CountryParser.parseCountryCode(countryCode);
          _isUpdatingCountry = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ ${locale.get('edit_profile_country_updated')}'), backgroundColor: Colors.green),
        );
      } else if (mounted) {
        setState(() => _isUpdatingCountry = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ ${locale.get('edit_profile_country_detect_failed')}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdatingCountry = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ ${locale.get('edit_profile_detect_error')}$e'), backgroundColor: Colors.red),
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

  Widget? _buildNicknameSuffixIcon() {
    if (_isCheckingNickname) {
      return Padding(
        padding: EdgeInsets.all(12.r),
        child: SizedBox(
          width: 20.r,
          height: 20.r,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_nicknameAvailabilityMessage != null) {
      return const Icon(Icons.error, color: Colors.red);
    }

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
    final locale = context.watch<LocaleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(locale.get('edit_profile_title')),
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
            onPressed: _isSaving ? null : () => _saveProfile(locale),
          ),
        ],
      ),
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
                  Center(
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: () => _showImageSourceActionSheet(locale),
                          child: CircleAvatar(
                            key: ValueKey('edit_avatar_${_tempAvatar?.path ?? ((state is ProfileLoaded || state is ProfileUpdated) ? (state is ProfileLoaded ? state.profile : (state as ProfileUpdated).profile).avatarUrl : widget.initialProfile.avatarUrl)}'),
                            radius: 50.r,
                            backgroundColor: Colors.grey.shade300,
                            backgroundImage: _tempAvatar != null
                                ? FileImage(_tempAvatar!)
                                : (state is ProfileLoaded || state is ProfileUpdated)
                                ? ((state is ProfileLoaded ? state.profile : (state as ProfileUpdated).profile).avatarUrl != null && (state is ProfileLoaded ? state.profile : (state as ProfileUpdated).profile).avatarUrl!.isNotEmpty
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
                            onTap: () => _showImageSourceActionSheet(locale),
                            child: CircleAvatar(
                              radius: 16.r,
                              backgroundColor: Theme.of(context).primaryColor,
                              child: const Icon(Icons.edit, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _nicknameController,
                    enabled: !_isSaving,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
                      LengthLimitingTextInputFormatter(20),
                    ],
                    decoration: InputDecoration(
                      labelText: locale.get('edit_profile_nickname'),
                      hintText: locale.get('edit_profile_enter_nickname'),
                      helperText: locale.get('edit_profile_nickname_helper'),
                      border: const OutlineInputBorder(),
                      suffixIcon: _buildNicknameSuffixIcon(),
                      errorText: _nicknameAvailabilityMessage,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return locale.get('edit_profile_nickname_required');
                      }
                      if (value.trim().length < 3 || value.trim().length > 20) {
                        return locale.get('edit_profile_nickname_length');
                      }
                      if (!_nicknameRegex.hasMatch(value.trim())) {
                        return locale.get('edit_profile_nickname_invalid');
                      }
                      if (_nicknameAvailabilityMessage != null) {
                        return _nicknameAvailabilityMessage;
                      }
                      return null;
                    },
                    onChanged: (value) => _checkNicknameAvailability(value, locale),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _fullNameController,
                    enabled: !_isSaving,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\p{L}\s\-]', unicode: true)),
                      LengthLimitingTextInputFormatter(50),
                    ],
                    decoration: InputDecoration(
                      labelText: locale.get('edit_profile_full_name'),
                      hintText: locale.get('edit_profile_enter_full_name'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _bioController,
                    enabled: !_isSaving,
                    maxLines: 4,
                    maxLength: 255,
                    decoration: InputDecoration(
                      labelText: locale.get('edit_profile_bio'),
                      hintText: locale.get('edit_profile_tell_about_yourself'),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 16),

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
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
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
                                    Text(
                                      locale.get('edit_profile_country_not_selected'),
                                      style: const TextStyle(fontSize: 16, color: Colors.grey),
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
                          onPressed: (_isUpdatingCountry || _isSaving) ? null : () => _updateCountryViaGPS(locale),
                          tooltip: locale.get('edit_profile_detect_by_gps'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: _isSaving ? null : _showCountryPicker,
                          tooltip: locale.get('edit_profile_select_country'),
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