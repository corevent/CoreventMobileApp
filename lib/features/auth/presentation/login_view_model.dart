import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../domain/auth_validation.dart';
import 'auth_errors.dart';
import 'auth_session.dart';

enum LoginField { email, password }

class LoginViewModel extends ChangeNotifier {
  LoginViewModel(this._session, this._router);

  final AuthSession _session;
  final GoRouter _router;
  String email = '';
  String password = '';
  String? error;
  LoginField? errorField;
  bool busy = false;

  void setEmail(String value) {
    if (busy) return;
    email = value;
    error = null;
    errorField = null;
    notifyListeners();
  }

  void setPassword(String value) {
    if (busy) return;
    password = value;
    error = null;
    errorField = null;
    notifyListeners();
  }

  Future<void> submit() async {
    if (busy) return;
    if (!validEmail(email) || password.trim().isEmpty) {
      error = !validEmail(email)
          ? 'Informe um e-mail válido.'
          : 'Informe sua senha.';
      errorField = !validEmail(email) ? LoginField.email : LoginField.password;
      notifyListeners();
      return;
    }
    busy = true;
    error = null;
    errorField = null;
    notifyListeners();
    try {
      await _session.login(email, password);
      _router.goNamed('home');
    } catch (cause) {
      final invalidCredentials =
          cause is DioException &&
          (cause.response?.statusCode == 400 ||
              cause.response?.statusCode == 401);
      error = invalidCredentials
          ? 'E-mail ou senha incorretos.'
          : authErrorMessage(cause);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void openRegister() {
    if (!busy) _router.goNamed('register');
  }

  void openRecovery() {
    if (!busy) _router.goNamed('forgotPassword');
  }
}

final loginViewModelProvider = Provider<LoginViewModel>((ref) {
  final model = LoginViewModel(
    ref.watch(authSessionProvider),
    ref.watch(routerProvider),
  );
  ref.onDispose(model.dispose);
  return model;
});
