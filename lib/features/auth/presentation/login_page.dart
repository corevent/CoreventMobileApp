import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_flow_store.dart';
import 'auth_widgets.dart';
import 'login_view_model.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(loginViewModelProvider);
    final notice = ref.read(authFlowStoreProvider).notice;
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) => AuthPageShell(
        title: 'Bem-vindo de volta!',
        description: 'Sentimos sua falta. Entre para continuar explorando.',
        onBack: () => context.goNamed('welcome'),
        busy: model.busy,
        children: [
          if (notice != null) ...[
            AuthSuccess(notice),
            const SizedBox(height: 18),
          ],
          AuthField(
            label: 'E-mail',
            hint: 'seu@email.com',
            initialValue: model.email,
            enabled: !model.busy,
            errorText: model.errorField == LoginField.email
                ? model.error
                : null,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email, AutofillHints.username],
            onChanged: model.setEmail,
          ),
          AuthField(
            label: 'Senha',
            hint: 'Sua senha',
            initialValue: model.password,
            enabled: !model.busy,
            errorText: model.errorField == LoginField.password
                ? model.error
                : null,
            password: true,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => model.submit(),
            onChanged: model.setPassword,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: AuthTextAction(
              label: 'Esqueceu a senha?',
              onPressed: model.busy ? null : model.openRecovery,
            ),
          ),
          const SizedBox(height: 20),
          if (model.errorField == null) AuthError(model.error),
          AuthPrimaryButton(
            label: 'Entrar',
            busy: model.busy,
            onPressed: model.submit,
          ),
          const SizedBox(height: 16),
          AuthTextAction(
            label: 'Não possui conta? Cadastre-se',
            onPressed: model.busy ? null : model.openRegister,
          ),
        ],
      ),
    );
  }
}
