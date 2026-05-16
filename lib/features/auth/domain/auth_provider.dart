import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_repository.dart';
import '../data/auth_remote_datasource.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;
  
  User? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = true;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthProvider() : _repository = AuthRepository(
      AuthRemoteDataSource(Supabase.instance.client)
  ) {
    _initAuthState();
  }

  void _initAuthState() {
    // Синхронно читаем текущую сессию
    _currentUser = _repository.remote.currentUser;
    _isAuthenticated = _currentUser != null;
    _isLoading = false;
    _error = null;
    notifyListeners();  // 🔥 Сразу уведомляем слушателей

    // Подписываемся на будущие изменения
    _repository.remote.authStateChanges.listen((state) {
      _currentUser = state.session?.user;
      _isAuthenticated = state.session != null;
      _error = null;
      notifyListeners();  // 🔥 И снова уведомляем
    });
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.login(email: email, password: password);
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'Неизвестная ошибка: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 🔥 Теперь response имеет тип AuthResponse?
      final response = await _repository.register(
        email: email,
        password: password,
      );

      // 🔥 Проверяем подтверждение почты
      final user = response?.user;
      if (user != null && user.emailConfirmedAt == null) {
        _error = 'confirm_email';
        return false;
      }

      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'Неизвестная ошибка: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _repository.logout();
  }

  Future<bool> forgotPassword(String email) async {
    try {
      await _repository.forgotPassword(email);
      return true;
    } catch (e) {
      _error = 'Ошибка: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> loginWithGoogle() async {
    await _repository.loginWithGoogle();
  }
}