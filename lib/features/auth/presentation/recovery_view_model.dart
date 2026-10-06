import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../data/auth_repository.dart';
import '../domain/auth_validation.dart';
import 'auth_errors.dart';
import 'auth_flow_store.dart';

enum RecoveryField { email, password, confirmPassword }

class RecoveryViewModel extends ChangeNotifier {
  RecoveryViewModel(this._repository, this._router, this._flow);

  final AuthRepository _repository;
  final GoRouter _router;
  final AuthFlowStore _flow;
  String email = '';
  String password = '';
  String confirmPassword = '';
  String? error;
  RecoveryField? errorField;
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

  void setConfirmPassword(String value) {
    if (busy) return;
    confirmPassword = value;
    error = null;
    errorField = null;
    notifyListeners();
  }

  Future<void> sendCode() async {
    if (busy) return;
    if (!validEmail(email)) {
      error = 'Informe um e-mail válido.';
      errorField = RecoveryField.email;
      notifyListeners();
      return;
    }
    busy = true;
    error = null;
    errorField = null;
    notifyListeners();
    try {
      await _repository.sendResetCode(email);
      _flow.recoveryEmail = email.trim();
      _router.goNamed('verifyReset');
    } catch (cause) {
      error = authErrorMessage(
        cause,
        fallback: 'Não foi possível enviar o código. Tente novamente.',
      );
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword() async {
    if (busy) return;
    if (!validPassword(password)) {
      error = 'A senha deve ter 8+ caracteres, maiúscula, minúscula, número e símbolo.';
      errorField = RecoveryField.password;
    } else if (password != confirmPassword) {
      error = 'As senhas não conferem.';
      errorField = RecoveryField.confirmPassword;
    } else if (_flow.recoveryEmail == null || _flow.recoveryCode == null) {
      error = 'Solicite um novo código de recuperação.';
      errorField = null;
    } else {
      error = null;
      errorField = null;
    }
    if (error != null) {
      notifyListeners();
      return;
    }
    busy = true;
    notifyListeners();
    try {
      await _repository.resetPassword(
        _flow.recoveryEmail!,
        _flow.recoveryCode!,
        password,
      );
      _flow.clearRecovery();
      password = '';
      confirmPassword = '';
      _router.goNamed('login');
    } catch (cause) {
      error = authErrorMessage(
        cause,
        fallback: 'Não foi possível redefinir a senha. Verifique o código e tente novamente.',
      );
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}

final recoveryViewModelProvider = Provider<RecoveryViewModel>((ref) {
  final model = RecoveryViewModel(
    ref.watch(authRepositoryProvider),
    ref.watch(routerProvider),
    ref.watch(authFlowStoreProvider),
  );
  ref.onDispose(model.dispose);
  return model;
});
