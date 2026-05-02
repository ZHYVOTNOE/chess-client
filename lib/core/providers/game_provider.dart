import 'package:flutter/cupertino.dart';

class GameProvider extends ChangeNotifier{
  bool _vsRandom = false;
  bool _vsComputer = false;
  bool _vsFriend = false;
  bool _isLoading = false;

  bool get vsRandom => _vsRandom;
  bool get vsComputer => _vsComputer;
  bool get vsFriend => _vsFriend;
  bool get isLoading => _isLoading;

  void setVsRandom({required bool value}){
    _vsRandom = value;
    notifyListeners();
  }

  void setVsComputer({required bool value}){
    _vsComputer = value;
    notifyListeners();
  }

  void setVsFriend({required bool value}){
    _vsFriend = value;
    notifyListeners();
  }

  void setIsLoading({required bool value}){
    _isLoading = value;
    notifyListeners();
  }
}