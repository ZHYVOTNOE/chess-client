import 'package:flutter/foundation.dart';
import '../../features/auth/domain/auth_provider.dart';

class AuthRefreshListenable extends ChangeNotifier {
  final AuthProvider auth;

  AuthRefreshListenable(this.auth) {
    auth.addListener(_forwardNotification);
  }

  void _forwardNotification() => notifyListeners();

  @override
  void dispose() {
    auth.removeListener(_forwardNotification);
    super.dispose();
  }
}