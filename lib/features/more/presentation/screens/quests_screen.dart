import 'package:flutter/material.dart';

class QuestsScreen extends StatelessWidget {
  const QuestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quests'),
      ),
      body: const Center(
        child: Text('Quests - Coming Soon'),
      ),
    );
  }
}
