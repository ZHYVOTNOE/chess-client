import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthProvider>();
    final success = await auth.forgotPassword(_emailController.text.trim());  // 🔥 Проверяем результат

    if (mounted) {
      if (success) {
        setState(() => _isSuccess = true);
      } else {
        setState(() => _errorMessage = auth.error ?? 'Ошибка отправки');
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
        padding: EdgeInsets.all(24.r),
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
            size: 80.r,
            color: Theme.of(context).primaryColor,
          ),

          SizedBox(height: 16.h),

          Text(
            locale.get('forgot_description'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),

          SizedBox(height: 32.h),

          if (_errorMessage != null) ...[
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: Colors.red.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            SizedBox(height: 16.h),
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

          SizedBox(height: 32.h),

          AuthButton(
            onPressed: _sendResetLink,
            isLoading: _isLoading,
            text: locale.get('forgot_button'),
          ),

          SizedBox(height: 16.h),

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
          size: 80.r,
          color: Colors.green.shade600,
        ),

        SizedBox(height: 24.h),

        Text(
          locale.get(
            'forgot_success_title',
          ),
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .headlineSmall,
        ),

        SizedBox(height: 16.h),

        Text(
          locale.get(
            'forgot_success_message',
          ),
          textAlign: TextAlign.center,
          style:
          Theme.of(context).textTheme.bodyLarge,
        ),

        SizedBox(height: 32.h),

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