import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:client/core/providers/locale_provider.dart';

class EndgamesScreen extends StatelessWidget {
  const EndgamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(locale.get('learn_endgames')),
      ),
      body: Center(
        child: Text('${locale.get('learn_endgames')} - ${locale.get('coming_soon')}'),
      ),
    );
  }
}
