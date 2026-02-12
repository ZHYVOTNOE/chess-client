import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LocaleProvider extends ChangeNotifier {
  String _lang = 'ru';
  Map<String, String> _strings = {};

  String get lang => _lang;
  String get(String key) => _strings[key] ?? key;

  Future<void> load(String lang) async {
    _lang = lang;
    final jsonString = await rootBundle.loadString('assets/lang/$lang.json');
    _strings = (json.decode(jsonString) as Map).cast<String, String>();
    notifyListeners();
  }
}