import 'package:client/core/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(locale.get('more_games')),
      ),
      body: Center(
        child: Text('${locale.get('more_games')} - ${locale.get('coming_soon')}'),
      ),
    );
  }
}
