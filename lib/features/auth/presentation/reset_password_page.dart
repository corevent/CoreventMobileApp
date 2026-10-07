import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_widgets.dart';
import 'password_requirements.dart';
import 'recovery_view_model.dart';

class ResetPasswordPage extends ConsumerWidget {
  const ResetPasswordPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(recoveryViewModelProvider);
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) => AuthPageShell(
        title: 'Redefinir senha',
        description: 'Escolha uma nova senha para sua conta.',
        onBack: () => context.goNamed('verifyReset'),
        busy: model.busy,
        children: [
          AuthField(
            label: 'Nova senha',
            hint: 'Mínimo 8 caracteres',
            initialValue: model.password,
            enabled: !model.busy,
            errorText: model.errorField == RecoveryField.password
                ? model.error
                : null,
            password: true,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            onChanged: model.setPassword,
          ),
          PasswordRequirements(password: model.password),
          AuthField(
            label: 'Confirmar senha',
            hint: 'Repita a senha',
            initialValue: model.confirmPassword,
            enabled: !model.busy,
            errorText: model.errorField == RecoveryField.confirmPassword
                ? model.error
                : null,
            password: true,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            onSubmitted: (_) => model.resetPassword(),
            onChanged: model.setConfirmPassword,
          ),
          if (model.errorField == null) AuthError(model.error),
          AuthPrimaryButton(
            label: 'Redefinir senha',
            busy: model.busy,
            onPressed: model.resetPassword,
          ),
        ],
      ),
    );
  }
}
