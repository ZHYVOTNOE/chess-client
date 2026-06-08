import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:client/core/providers/locale_provider.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(locale.get('more_inbox')),
      ),
      body: Center(
        child: Text('${locale.get('more_inbox')} - ${locale.get('coming_soon')}'),
      ),
    );
  }
}
