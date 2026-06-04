import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart'; // 👈 ДОБАВЬТЕ ИМПОРТ
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_repository.dart';
import '../data/auth_remote_datasource.dart';
import '../../../core/services/presence_service.dart'; // 👈 ИМПОРТ PresenceService

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;
  final PresenceService _presenceService; // 👈 ХРАНИМ ССЫЛКУ

  User? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = true;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthProvider()
      : _repository = AuthRepository(AuthRemoteDataSource(Supabase.instance.client)),
        _presenceService = GetIt.instance<PresenceService>() {
    _initAuthState();
  }

  void _handleAuthChange(User? user) {
    print('🔐 [AuthProvider] _handleAuthChange called with user: ${user?.id ?? "null"}');

    if (user != null) {
      print('🔐 [AuthProvider] User logged in, initializing PresenceService');
      _presenceService.init(user.id);
    } else {
      print('🔐 [AuthProvider] User logged out, disposing PresenceService');
      _presenceService.dispose();
    }
  }

  void _initAuthState() {
    // Синхронно читаем текущую сессию
    _currentUser = _repository.remote.currentUser;
    _isAuthenticated = _currentUser != null;
    _isLoading = false;
    _error = null;

    _handleAuthChange(_currentUser); // 👈 ЗАПУСКАЕМ ЕСЛИ УЖЕ ЗАЛОГИНЕН
    notifyListeners();

    // Подписываемся на будущие изменения
    _repository.remote.authStateChanges.listen((state) {
      final user = state.session?.user;

      // Срабатываем только если пользователь РЕАЛЬНО изменился
      if (_currentUser?.id != user?.id) {
        _currentUser = user;
        _isAuthenticated = state.session != null;
        _error = null;

        _handleAuthChange(user); // 👈 АВТОМАТИЧЕСКИЙ ЗАПУСК/ОСТАНОВКА
        notifyListeners();
      }
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
      // PresenceService запустится автоматически через authStateChanges listener
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
      final response = await _repository.register(
        email: email,
        password: password,
      );

      final user = response?.user;
      if (user != null && user.emailConfirmedAt == null) {
        _error = 'confirm_email';
        return false;
      }

      // PresenceService запустится автоматически через authStateChanges listener
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
    // PresenceService остановится автоматически через authStateChanges listener,
    // так как сессия станет null
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
    // PresenceService запустится автоматически через authStateChanges listener
  }

  @override
  void dispose() {
    _presenceService.dispose(); // 👈 ОЧИЩАЕМ ПРИ УНИЧТОЖЕНИИ ПРОВАЙДЕРА
    super.dispose();
  }
}