import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../data/auth_repository.dart';
import '../domain/auth_validation.dart';
import '../domain/registration_draft.dart';
import 'auth_errors.dart';
import 'auth_flow_store.dart';

enum RegisterField {
  name,
  birthDate,
  accountType,
  document,
  email,
  password,
  confirmPassword,
}

class RegisterViewModel extends ChangeNotifier {
  RegisterViewModel(this._repository, this._router, this._flow);

  final AuthRepository _repository;
  final GoRouter _router;
  final AuthFlowStore _flow;
  final RegistrationDraft draft = RegistrationDraft();
  int step = 1;
  bool busy = false;
  String? error;
  RegisterField? errorField;

  void update(void Function(RegistrationDraft) change) {
    if (busy) return;
    change(draft);
    error = null;
    errorField = null;
    notifyListeners();
  }

  void chooseAccountType(String value) {
    if (busy) return;
    if (draft.accountType != value) draft.document = '';
    draft.accountType = value;
    error = null;
    errorField = null;
    notifyListeners();
  }

  void back() {
    if (busy) return;
    if (step > 1) {
      step--;
      error = null;
      errorField = null;
      notifyListeners();
    } else {
      _router.goNamed('welcome');
    }
  }

  Future<void> next() async {
    if (busy) return;
    final invalid = _validateCurrentStep();
    error = invalid?.message;
    errorField = invalid?.field;
    if (error != null) {
      notifyListeners();
      return;
    }
    if (step < 4) {
      step++;
      notifyListeners();
      return;
    }
    busy = true;
    errorField = null;
    notifyListeners();
    try {
      await _repository.sendVerification(draft.email);
      _flow.registration = draft;
      _router.goNamed('verifyRegister');
    } catch (cause) {
      errorField = null;
      error = authErrorMessage(
        cause,
        fallback: 'Não foi possível enviar o código. Tente novamente.',
      );
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  ({RegisterField field, String message})? _validateCurrentStep() =>
      switch (step) {
        1 when draft.name.trim().length < 3 => (
          field: RegisterField.name,
          message: 'O nome deve ter pelo menos 3 caracteres.',
        ),
        1
            when draft.birthDate == null ||
                draft.birthDate!.isAfter(DateTime.now()) =>
          (
            field: RegisterField.birthDate,
            message: 'Informe uma data de nascimento válida.',
          ),
        2 when draft.accountType == null => (
          field: RegisterField.accountType,
          message: 'Selecione o tipo de conta.',
        ),
        3 when draft.accountType == 'pj' && !validCnpj(draft.document) => (
          field: RegisterField.document,
          message: 'Informe um CNPJ válido.',
        ),
        3 when draft.accountType != 'pj' && !validCpf(draft.document) => (
          field: RegisterField.document,
          message: 'Informe um CPF válido.',
        ),
        4 when !validEmail(draft.email) => (
          field: RegisterField.email,
          message: 'Informe um e-mail válido.',
        ),
        4 when !validPassword(draft.password) => (
          field: RegisterField.password,
          message: 'A senha deve ter 8+ caracteres, maiúscula, minúscula, número e símbolo.',
        ),
        4 when draft.password != draft.confirmPassword => (
          field: RegisterField.confirmPassword,
          message: 'As senhas não conferem.',
        ),
        _ => null,
      };
}

final registerViewModelProvider = Provider<RegisterViewModel>((ref) {
  final model = RegisterViewModel(
    ref.watch(authRepositoryProvider),
    ref.watch(routerProvider),
    ref.watch(authFlowStoreProvider),
  );
  ref.onDispose(model.dispose);
  return model;
});
