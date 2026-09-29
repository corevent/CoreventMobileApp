import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/registration_draft.dart';

class AuthFlowStore {
  RegistrationDraft? registration;
  String? recoveryEmail;
  String? recoveryCode;
  String? notice;

  void clearRegistration() => registration = null;
  void clearRecovery() {
    recoveryEmail = null;
    recoveryCode = null;
  }
}

final authFlowStoreProvider = Provider<AuthFlowStore>((ref) => AuthFlowStore());
