import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_repository.dart';
import '../data/auth_remote_datasource.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;
  
  User? _currentUser;
  bool _isAuthenticated = false;

  AuthProvider() : _repository = AuthRepository(
    AuthRemoteDataSource(Supabase.instance.client)
  ) {
    _initAuthState();
  }

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;

  void _initAuthState() {
    _currentUser = _repository.remote.currentUser;
    _isAuthenticated = _repository.remote.currentUser != null;
    
    _repository.remote.authStateChanges.listen((state) {
      _currentUser = state.session?.user;
      _isAuthenticated = state.session != null;
      notifyListeners();
    });
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    await _repository.login(
      email: email,
      password: password,
    );
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    await _repository.register(
      email: email,
      password: password,
    );
  }

  Future<void> logout() async {
    await _repository.logout();
  }

  Future<void> forgotPassword(String email) async {
    await _repository.forgotPassword(email);
  }

  Future<void> loginWithGoogle() async {
    await _repository.loginWithGoogle();
  }
}