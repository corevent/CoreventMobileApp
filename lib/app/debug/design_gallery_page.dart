import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import '../../core/design_system/app_tokens.dart';
import '../../core/design_system/corevent_button.dart';
import '../../core/design_system/corevent_field.dart';
import '../../core/design_system/corevent_notice.dart';
import '../../core/design_system/corevent_selection_card.dart';
import '../../core/design_system/corevent_step_progress.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/presentation/password_requirements.dart';
import '../../features/auth/presentation/verification_code_field.dart';

class DesignGalleryPage extends StatefulWidget {
  const DesignGalleryPage({super.key});

  @override
  State<DesignGalleryPage> createState() => _DesignGalleryPageState();
}

class _DesignGalleryPageState extends State<DesignGalleryPage> {
  bool selected = true;
  String code = '';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Componentes Corevent'),
      automaticallyImplyLeading: false,
      leading: Navigator.of(context).canPop()
          ? IconButton(
              tooltip: 'Voltar',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(RemixIcons.arrow_left_line),
            )
          : null,
    ),
    body: ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Ações',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                CoreventButton(label: 'Ação principal', onPressed: () {}),
                const SizedBox(height: AppSpacing.sm),
                const CoreventButton(
                  label: 'Enviando',
                  onPressed: null,
                  busy: true,
                ),
                const SizedBox(height: AppSpacing.sm),
                const CoreventButton(label: 'Desabilitado', onPressed: null),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Campos',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                CoreventField(
                  label: 'E-mail',
                  hint: 'seu@email.com',
                  onChanged: (_) {},
                ),
                CoreventField(
                  label: 'Campo com erro',
                  initialValue: 'inválido',
                  errorText: 'Revise este campo.',
                  onChanged: (_) {},
                ),
                const PasswordRequirements(password: 'Senha1!'),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Escolha e progresso',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                CoreventSelectionCard(
                  title: 'Pessoa Física',
                  subtitle: 'Usar CPF',
                  icon: RemixIcons.user_line,
                  selected: selected,
                  onTap: () => setState(() => selected = !selected),
                ),
                const SizedBox(height: AppSpacing.lg),
                const CoreventStepProgress(current: 2, total: 4),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Mensagens e código',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                const CoreventNotice(
                  message: 'Operação concluída.',
                  type: CoreventNoticeType.success,
                ),
                const CoreventNotice(
                  message: 'Verifique os dados e tente novamente.',
                ),
                VerificationCodeField(
                  code: code,
                  onChanged: (value) => setState(() => code = value),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Fundo #F5F5F6 · superfícies brancas · sem sombras',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
