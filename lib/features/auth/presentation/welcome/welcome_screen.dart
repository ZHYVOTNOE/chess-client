import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/locale_provider.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 28,
            right: 8,
            child: _LanguageSelector(),
          ),
          Center(child: Image.asset('assets/pictures/logo.png')),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.66,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildButton(context, locale.get('welcome_login'), () {
                  context.push('/login');
                }),
                const SizedBox(height: 16),
                _buildButton(context, locale.get('welcome_register'), () {
                  context.push('/registration');
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context, String text, VoidCallback onPressed) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.66,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(text),
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final locale = context.read<LocaleProvider>();

    return PopupMenuButton<String>(
      icon: const Icon(Icons.language),
      onSelected: locale.load,
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'ru', child: Text('Русский')),
        const PopupMenuItem(value: 'en', child: Text('English')),
      ],
    );
  }
}