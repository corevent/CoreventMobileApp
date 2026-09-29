import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_widgets.dart';
import 'recovery_view_model.dart';

class ForgotPasswordPage extends ConsumerWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(recoveryViewModelProvider);
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) => AuthPageShell(
        title: 'Recuperar senha',
        description: 'Informe seu e-mail para receber o código de verificação.',
        onBack: () => context.goNamed('login'),
        busy: model.busy,
        children: [
          AuthField(
            label: 'E-mail',
            hint: 'seu@email.com',
            initialValue: model.email,
            enabled: !model.busy,
            errorText: model.errorField == RecoveryField.email
                ? model.error
                : null,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            onSubmitted: (_) => model.sendCode(),
            onChanged: model.setEmail,
          ),
          if (model.errorField == null) AuthError(model.error),
          AuthPrimaryButton(
            label: 'Enviar código',
            busy: model.busy,
            onPressed: model.sendCode,
          ),
        ],
      ),
    );
  }
}
