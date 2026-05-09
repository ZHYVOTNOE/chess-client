import 'package:client/features/auth/data/auth_remote_datasource.dart';

class AuthRepository {
  final AuthRemoteDataSource remote;

  AuthRepository(this.remote);

  Future<void> login({
    required String email,
    required String password,
  }) async {
    await remote.signIn(
      email: email,
      password: password,
    );
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    await remote.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> forgotPassword(String email) async {
    await remote.resetPassword(email);
  }

  Future<void> logout() async {
    await remote.signOut();
  }

  Future<void> loginWithGoogle() async {
    await remote.signInWithGoogle();
  }
}