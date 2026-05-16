import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/locale_provider.dart';
import '../../domain/auth_provider.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_textfield.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() =>
      _RegistrationScreenState();
}

class _RegistrationScreenState
    extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();

  final _passwordController = TextEditingController();

  final _confirmPasswordController =
  TextEditingController();

  bool _isLoading = false;

  bool _obscurePassword = true;

  bool _obscureConfirmPassword = true;

  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();

    _passwordController.dispose();

    _confirmPasswordController.dispose();

    super.dispose();
  }

  // В методе _register():
  Future<void> _register() async {
    // ... валидация ...

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (mounted) {
      if (auth.error == 'confirm_email') {
        // 🔥 Показываем диалог вместо редиректа
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('📧 Подтвердите почту'),
            content: Text(
              'Ссылка отправлена на ${_emailController.text}.\n\n'
                  'Проверьте папку "Спам" и перейдите по ссылке.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/welcome'); // ← только здесь редирект
                },
                child: const Text('Понял'),
              ),
            ],
          ),
        );
      } else if (success) {
        // Если подтверждение не нужно — редирект на /home
        context.go('/home');
      } else {
        setState(() => _errorMessage = auth.error ?? 'Ошибка регистрации');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          locale.get('register_title'),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.person_add_outlined,
                size: 80,
                color:
                Theme.of(context).primaryColor,
              ),

              const SizedBox(height: 32),

              if (_errorMessage != null) ...[
                Container(
                  padding:
                  const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius:
                    BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color:
                      Colors.red.shade700,
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],

              AuthTextField(
                controller: _emailController,
                label:
                locale.get('register_email'),
                icon: Icons.email_outlined,
                keyboardType:
                TextInputType.emailAddress,
                validator: (value) {
                  if (value == null ||
                      value.isEmpty) {
                    return locale.get(
                      'error_email_required',
                    );
                  }

                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return locale.get(
                      'error_email_invalid',
                    );
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              AuthTextField(
                controller:
                _passwordController,
                label: locale.get(
                  'register_password',
                ),
                icon: Icons.lock_outlined,
                obscureText:
                _obscurePassword,
                validator: (value) {
                  if (value == null ||
                      value.isEmpty) {
                    return locale.get(
                      'error_password_required',
                    );
                  }

                  if (value.length < 8) {
                    return locale.get(
                      'error_password_short',
                    );
                  }

                  return null;
                },
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons
                        .visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword =
                      !_obscurePassword;
                    });
                  },
                ),
              ),

              const SizedBox(height: 16),

              AuthTextField(
                controller:
                _confirmPasswordController,
                label: locale.get(
                  'register_confirm_password',
                ),
                icon: Icons.lock_outline,
                obscureText:
                _obscureConfirmPassword,
                validator: (value) {
                  if (value !=
                      _passwordController
                          .text) {
                    return locale.get(
                      'error_password_mismatch',
                    );
                  }

                  return null;
                },
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons
                        .visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword =
                      !_obscureConfirmPassword;
                    });
                  },
                ),
              ),

              const SizedBox(height: 32),

              AuthButton(
                onPressed: _register,
                isLoading: _isLoading,
                text:
                locale.get('register_button'),
              ),

              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final auth = context.read<AuthProvider>();

                    await auth.loginWithGoogle();
                  } catch (e) {
                    setState(() {
                      _errorMessage = e.toString();
                    });
                  }
                },
                icon: Image.asset(
                  'assets/pictures/google.png',
                  height: 24,
                ),
                label: const Text('Google'),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () {
                  context.replace('/login');
                },
                child: Text(
                  locale.get(
                    'register_have_account',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}