import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../data/auth_repository.dart';
import '../domain/auth_validation.dart';
import 'auth_errors.dart';
import 'auth_flow_store.dart';
import 'auth_session.dart';

enum VerificationMode { register, reset }

class VerificationViewModel extends ChangeNotifier {
  VerificationViewModel(
    this._repository,
    this._session,
    this._router,
    this._flow,
  );

  final AuthRepository _repository;
  final AuthSession _session;
  final GoRouter _router;
  final AuthFlowStore _flow;
  Timer? _timer;
  VerificationMode? mode;
  String code = '';
  String? error;
  bool errorOnCode = false;
  String? notice;
  bool busy = false;
  int resendSeconds = 0;

  String get email => mode == VerificationMode.register
      ? _flow.registration?.email ?? ''
      : _flow.recoveryEmail ?? '';

  void start(VerificationMode value) {
    mode = value;
    code = '';
    error = null;
    errorOnCode = false;
    notice = null;
    _beginCooldown();
  }

  void setCode(String value) {
    if (busy) return;
    code = onlyDigits(value);
    error = null;
    errorOnCode = false;
    notice = null;
    notifyListeners();
  }

  Future<void> verify() async {
    if (busy) return;
    if (!validCode(code)) {
      error = 'Insira o código de 6 dígitos enviado por e-mail.';
      errorOnCode = true;
      notifyListeners();
      return;
    }
    if (mode == VerificationMode.reset) {
      _flow.recoveryCode = code;
      _router.goNamed('resetPassword');
      return;
    }
    final draft = _flow.registration;
    if (draft == null) {
      _router.goNamed('register');
      return;
    }
    busy = true;
    error = null;
    errorOnCode = false;
    notifyListeners();
    try {
      await _repository.register(draft.toRequest(code));
      _flow.clearRegistration();
      try {
        await _session.login(draft.email, draft.password);
        _router.goNamed('home');
      } catch (_) {
        _flow.notice = 'Conta criada. Entre para continuar.';
        _router.goNamed('login');
      }
    } catch (cause) {
      errorOnCode = true;
      error = authErrorMessage(
        cause,
        fallback: 'Não foi possível criar a conta. Verifique o código e tente novamente.',
      );
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> resend() async {
    if (busy || resendSeconds > 0 || email.isEmpty) return;
    busy = true;
    error = null;
    errorOnCode = false;
    notice = null;
    notifyListeners();
    try {
      if (mode == VerificationMode.register) {
        await _repository.sendVerification(email);
      } else {
        await _repository.sendResetCode(email);
      }
      notice = 'Enviamos um novo código para seu e-mail.';
      _beginCooldown();
    } catch (cause) {
      error = authErrorMessage(
        cause,
        fallback: 'Não foi possível reenviar o código. Tente novamente.',
      );
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void _beginCooldown() {
    _timer?.cancel();
    resendSeconds = 30;
    notifyListeners();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      resendSeconds--;
      if (resendSeconds <= 0) timer.cancel();
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final verificationViewModelProvider = Provider<VerificationViewModel>((ref) {
  final model = VerificationViewModel(
    ref.watch(authRepositoryProvider),
    ref.watch(authSessionProvider),
    ref.watch(routerProvider),
    ref.watch(authFlowStoreProvider),
  );
  ref.onDispose(model.dispose);
  return model;
});
