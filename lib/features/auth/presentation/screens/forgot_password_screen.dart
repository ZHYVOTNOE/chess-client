import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/providers/locale_provider.dart';
import '../../domain/auth_provider.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_textfield.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _isSuccess = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = context.read<AuthProvider>();

      await auth.forgotPassword(
        _emailController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isSuccess = true;
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(locale.get('forgot_title')),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _isSuccess
            ? _buildSuccessState(locale)
            : _buildForm(locale),
      ),
    );
  }

  Widget _buildForm(LocaleProvider locale) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.lock_reset_outlined,
            size: 80,
            color: Theme.of(context).primaryColor,
          ),

          const SizedBox(height: 16),

          Text(
            locale.get('forgot_description'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
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
                style: TextStyle(
                  color: Colors.red.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 16),
          ],

          AuthTextField(
            controller: _emailController,
            label: locale.get('forgot_email'),
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
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

          const SizedBox(height: 32),

          AuthButton(
            onPressed: _sendResetLink,
            isLoading: _isLoading,
            text: locale.get('forgot_button'),
          ),

          const SizedBox(height: 16),

          TextButton(
            onPressed: () => context.pop(),
            child: Text(
              locale.get(
                'forgot_back_to_login',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(
      LocaleProvider locale,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 80,
          color: Colors.green.shade600,
        ),

        const SizedBox(height: 24),

        Text(
          locale.get(
            'forgot_success_title',
          ),
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .headlineSmall,
        ),

        const SizedBox(height: 16),

        Text(
          locale.get(
            'forgot_success_message',
          ),
          textAlign: TextAlign.center,
          style:
          Theme.of(context).textTheme.bodyLarge,
        ),

        const SizedBox(height: 32),

        AuthButton(
          onPressed: () => context.pop(),
          isLoading: false,
          text: locale.get(
            'forgot_back_to_login',
          ),
        ),
      ],
    );
  }
}