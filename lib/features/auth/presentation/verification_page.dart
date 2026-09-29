import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_widgets.dart';
import 'verification_code_field.dart';
import 'verification_view_model.dart';

class VerificationPage extends ConsumerStatefulWidget {
  const VerificationPage({super.key, required this.mode});
  final VerificationMode mode;

  @override
  ConsumerState<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends ConsumerState<VerificationPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(verificationViewModelProvider).start(widget.mode);
    });
  }

  @override
  Widget build(BuildContext context) {
    final model = ref.watch(verificationViewModelProvider);
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) => AuthPageShell(
        title: 'Verifique seu e-mail',
        description: 'Enviamos um código de 6 dígitos para ${model.email}.',
        busy: model.busy,
        onBack: () => context.goNamed(
          widget.mode == VerificationMode.register
              ? 'register'
              : 'forgotPassword',
        ),
        children: [
          VerificationCodeField(
            key: ValueKey('verify-${widget.mode.name}'),
            code: model.code,
            errorText: model.errorOnCode ? model.error : null,
            enabled: !model.busy,
            onChanged: model.setCode,
            onSubmitted: model.verify,
          ),
          if (!model.errorOnCode) AuthError(model.error),
          AuthSuccess(model.notice),
          AuthPrimaryButton(
            label: 'Verificar',
            busy: model.busy,
            onPressed: model.verify,
          ),
          const SizedBox(height: 16),
          AuthTextAction(
            label: model.resendSeconds > 0
                ? 'Reenviar código (${model.resendSeconds}s)'
                : 'Reenviar código',
            onPressed: model.busy || model.resendSeconds > 0
                ? null
                : model.resend,
          ),
          AuthTextAction(
            label: 'Alterar e-mail',
            onPressed: model.busy
                ? null
                : () => context.goNamed(
                    widget.mode == VerificationMode.register
                        ? 'register'
                        : 'forgotPassword',
                  ),
          ),
        ],
      ),
    );
  }
}
