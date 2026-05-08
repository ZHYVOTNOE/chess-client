import 'dart:io';

import 'package:flutter/cupertino.dart';

class UserProvider extends ChangeNotifier {
  String nickname = 'User';
  File? avatar;

  void setNickname(String value) {
    nickname = value;
    notifyListeners();
  }

  void setAvatar(File file) {
    avatar = file;
    notifyListeners();
  }
}