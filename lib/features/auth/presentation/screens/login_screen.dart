import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/locale_provider.dart';
import '../../domain/auth_provider.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_textfield.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (mounted) {
      if (success) {
        FocusScope.of(context).unfocus();
      } else {
        setState(() => _errorMessage = auth.error ?? 'Ошибка входа');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(locale.get('login_title')),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.login_outlined,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),

              const SizedBox(height: 32),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red.shade700,
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],

              AuthTextField(
                controller: _emailController,
                label: locale.get('login_email'),
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return locale.get('error_email_required');
                  }

                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return locale.get('error_email_invalid');
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              AuthTextField(
                controller: _passwordController,
                label: locale.get('login_password'),
                icon: Icons.lock_outlined,
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return locale.get('error_password_required');
                  }

                  return null;
                },
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),

              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    context.push('/forgot-password');
                  },
                  child: Text(
                    locale.get('login_forgot_password'),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              AuthButton(
                onPressed: _login,
                isLoading: _isLoading,
                text: locale.get('login_button'),
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
                  context.replace('/registration');
                },
                child: Text(
                  locale.get('login_no_account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}