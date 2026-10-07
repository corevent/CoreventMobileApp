import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';

import '../../../core/design_system/app_tokens.dart';
import '../../../core/design_system/corevent_selection_card.dart';
import '../../../core/design_system/corevent_step_progress.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/auth_validation.dart';
import 'auth_widgets.dart';
import 'birth_date_field.dart';
import 'document_formatter.dart';
import 'password_requirements.dart';
import 'register_view_model.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();
  late final AnimationController _fadeController;
  late final CurvedAnimation _opacity;
  late final RegisterViewModel _model;
  late int _visibleStep;
  bool _transitioning = false;

  static const _titles = [
    'Conte-nos sobre você',
    'Pessoa ou empresa?',
    'Seu documento',
    'Credenciais de acesso',
  ];
  static const _descriptions = [
    'Vamos começar com o básico para criar seu perfil.',
    'Selecione o tipo da sua conta.',
    'Informe o documento da sua conta.',
    'Informe seu e-mail e crie uma senha para entrar no app.',
  ];

  @override
  void initState() {
    super.initState();
    _model = ref.read(registerViewModelProvider);
    _visibleStep = _model.step;
    _fadeController = AnimationController(
      vsync: this,
      duration: AppMotion.quick,
      value: 1,
    );
    _opacity = CurvedAnimation(
      parent: _fadeController,
      curve: AppMotion.curve,
      reverseCurve: Curves.easeInCubic,
    );
    _model.addListener(_onModelChanged);
  }

  void _onModelChanged() {
    if (_model.step == _visibleStep || _transitioning) return;
    unawaited(_transitionToStep());
  }

  Future<void> _transitionToStep() async {
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() => _visibleStep = _model.step);
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
      FocusManager.instance.primaryFocus?.unfocus();
      return;
    }
    setState(() => _transitioning = true);
    FocusManager.instance.primaryFocus?.unfocus();
    await _fadeController.reverse();
    if (!mounted) return;
    setState(() => _visibleStep = _model.step);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    await _fadeController.forward();
    if (mounted) setState(() => _transitioning = false);
  }

  @override
  void dispose() {
    _model.removeListener(_onModelChanged);
    _opacity.dispose();
    _fadeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = ref.watch(registerViewModelProvider);
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && !model.busy && !_transitioning) model.back();
        },
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: AbsorbPointer(
              absorbing: model.busy,
              child: AutofillGroup(
                child: Column(
                  children: [
                    _RegisterTop(
                      step: _visibleStep,
                      onBack: _transitioning || model.busy ? null : model.back,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        key: const ValueKey('register-scroll'),
                        controller: _scrollController,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.xl,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: IgnorePointer(
                              ignoring: _transitioning,
                              child: FadeTransition(
                                key: const ValueKey('register-step-fade'),
                                opacity: _opacity,
                                child: _stepContent(
                                  context,
                                  model,
                                  _visibleStep,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    _RegisterFooter(
                      label: _visibleStep == 4 ? 'Finalizar' : 'Próximo',
                      busy: model.busy,
                      onPressed: _transitioning || model.busy
                          ? null
                          : model.next,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepContent(
    BuildContext context,
    RegisterViewModel model,
    int step,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        _titles[step - 1],
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        _descriptions[step - 1],
        style: Theme.of(context).textTheme.bodyLarge
            ?.copyWith(color: AppColors.textSecondary),
      ),
      const SizedBox(height: AppSpacing.xl),
      if (step == 1) ...[
        AuthField(
          key: const ValueKey('register-name'),
          label: 'Nome completo',
          hint: 'Seu nome completo',
          initialValue: model.draft.name,
          errorText: model.errorField == RegisterField.name
              ? model.error
              : null,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          onChanged: (value) => model.update((draft) => draft.name = value),
        ),
        BirthDateField(
          initialDate: model.draft.birthDate,
          errorText: model.errorField == RegisterField.birthDate
              ? model.error
              : null,
          onChanged: (date) => model.update((draft) => draft.birthDate = date),
        ),
      ],
      if (step == 2) ...[
        CoreventSelectionCard(
          title: 'Pessoa Física',
          subtitle: 'Usar CPF',
          icon: RemixIcons.user_line,
          selected: model.draft.accountType == 'pf',
          onTap: () => model.chooseAccountType('pf'),
        ),
        const SizedBox(height: 12),
        CoreventSelectionCard(
          title: 'Pessoa Jurídica',
          subtitle: 'Usar CNPJ',
          icon: RemixIcons.building_2_line,
          selected: model.draft.accountType == 'pj',
          onTap: () => model.chooseAccountType('pj'),
        ),
        if (model.errorField == RegisterField.accountType) ...[
          const SizedBox(height: 12),
          AuthError(model.error),
        ],
      ],
      if (step == 3)
        AuthField(
          key: ValueKey('register-document-${model.draft.accountType}'),
          label: model.draft.accountType == 'pj' ? 'CNPJ' : 'CPF',
          hint: model.draft.accountType == 'pj'
              ? '00.000.000/0001-00'
              : '000.000.000-00',
          initialValue: DocumentFormatter(
            isCompany: model.draft.accountType == 'pj',
          ).formatDigits(model.draft.document),
          errorText: model.errorField == RegisterField.document
              ? model.error
              : null,
          keyboardType: TextInputType.number,
          inputFormatters: [
            DocumentFormatter(isCompany: model.draft.accountType == 'pj'),
          ],
          onChanged: (value) =>
              model.update((draft) => draft.document = onlyDigits(value)),
        ),
      if (step == 4) ...[
        AuthField(
          key: const ValueKey('register-email'),
          label: 'E-mail',
          hint: 'seu@email.com',
          initialValue: model.draft.email,
          enabled: !model.busy,
          errorText: model.errorField == RegisterField.email
              ? model.error
              : null,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          onChanged: (value) => model.update((draft) => draft.email = value),
        ),
        AuthField(
          key: const ValueKey('register-password'),
          label: 'Senha',
          hint: 'Mínimo 8 caracteres',
          initialValue: model.draft.password,
          enabled: !model.busy,
          errorText: model.errorField == RegisterField.password
              ? model.error
              : null,
          password: true,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
          onChanged: (value) => model.update((draft) => draft.password = value),
        ),
        PasswordRequirements(password: model.draft.password),
        AuthField(
          key: const ValueKey('register-confirm'),
          label: 'Confirmar senha',
          hint: 'Repita a senha',
          initialValue: model.draft.confirmPassword,
          enabled: !model.busy,
          errorText: model.errorField == RegisterField.confirmPassword
              ? model.error
              : null,
          password: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          onSubmitted: (_) => model.next(),
          onChanged: (value) =>
              model.update((draft) => draft.confirmPassword = value),
        ),
      ],
      const SizedBox(height: AppSpacing.lg),
      if (model.errorField == null) AuthError(model.error),
    ],
  );
}

class _RegisterTop extends StatelessWidget {
  const _RegisterTop({required this.step, required this.onBack});

  final int step;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.lg,
      AppSpacing.lg,
      AppSpacing.md,
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  tooltip: 'Voltar',
                  icon: const Icon(RemixIcons.arrow_left_line),
                ),
                Expanded(
                  child: Image.asset(
                    'assets/images/logo_corevent_full.png',
                    height: 28,
                    alignment: Alignment.center,
                    semanticLabel: 'Corevent',
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            CoreventStepProgress(current: step, total: 4),
          ],
        ),
      ),
    ),
  );
}

class _RegisterFooter extends StatelessWidget {
  const _RegisterFooter({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: const BoxDecoration(
      color: AppColors.background,
      border: Border(top: BorderSide(color: AppColors.backgroundSecondary)),
    ),
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.md,
      AppSpacing.lg,
      AppSpacing.md,
    ),
    child: Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SizedBox(
          width: double.infinity,
          child: AuthPrimaryButton(
            label: label,
            busy: busy,
            onPressed: onPressed,
          ),
        ),
      ),
    ),
  );
}
