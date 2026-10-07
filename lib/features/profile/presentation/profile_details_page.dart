import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';

import '../../../core/design_system/app_surfaces.dart';
import '../../../core/design_system/app_tokens.dart';
import '../../../core/design_system/corevent_button.dart';
import '../../../core/design_system/corevent_field.dart';
import '../../../core/design_system/error_toast.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/data/auth_dtos.dart';
import '../../auth/presentation/auth_session.dart';
import '../data/avatar_picker.dart';
import '../domain/avatar_image.dart';
import '../domain/profile_formatters.dart';
import 'avatar_editor_page.dart';
import 'avatar_view_model.dart';
import 'profile_form_pages.dart';
import 'profile_forms_view_model.dart';

class ProfileDetailsPage extends ConsumerStatefulWidget {
  const ProfileDetailsPage({super.key});
  @override
  ConsumerState<ProfileDetailsPage> createState() => _ProfileDetailsPageState();
}

class _ProfileDetailsPageState extends ConsumerState<ProfileDetailsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController fade;
  bool transitioning = false;
  bool picking = false;

  @override
  void initState() {
    super.initState();
    fade = AnimationController(
      vsync: this,
      value: 1,
      duration: AppMotion.quick,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(detailsViewModelProvider.notifier).cancel();
      final recovered = ref.read(avatarPickerProvider).takeRecovered();
      if (recovered != null) _openPhoto(recovered);
    });
  }

  @override
  void dispose() {
    fade.dispose();
    super.dispose();
  }

  Future<void> _switchEditing(bool edit, UserProfile user) async {
    if (transitioning || !mounted) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => transitioning = true);
    fade.duration = AppMotion.duration(context, AppMotion.quick);
    await fade.reverse();
    if (!mounted) return;
    final model = ref.read(detailsViewModelProvider.notifier);
    if (edit) {
      model.edit(user);
    } else {
      model.cancel();
    }
    await fade.forward();
    if (mounted) setState(() => transitioning = false);
  }

  Future<bool> _mayDiscard() async {
    if (!ref.read(detailsViewModelProvider).dirty) return true;
    return await showDialog<bool>(
          context: context,
          builder: (dialog) => AlertDialog(
            elevation: 0,
            title: const Text('Descartar alterações?'),
            content: const Text(
              'As mudanças que você fez ainda não foram salvas.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialog, false),
                child: const Text('Continuar editando'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialog, true),
                child: const Text('Descartar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _back() async {
    if (ref.read(detailsViewModelProvider).busy || transitioning || picking) {
      return;
    }
    if (!await _mayDiscard() || !mounted) return;
    ref.read(detailsViewModelProvider.notifier).cancel();
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/profile');
    }
  }

  Future<void> _cancel(UserProfile user) async {
    if (await _mayDiscard() && mounted) await _switchEditing(false, user);
  }

  Future<void> _save(UserProfile user) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final saved = await ref.read(detailsViewModelProvider.notifier).save();
    if (!mounted) return;
    if (saved) {
      await _switchEditing(false, user);
      if (mounted) _success('Dados atualizados.');
    }
  }

  void _success(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: AppColors.surface),
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    if (picking || ref.read(detailsViewModelProvider).editing) return;
    setState(() => picking = true);
    try {
      final bytes = await ref.read(avatarPickerProvider).pick();
      if (bytes != null && mounted) await _openPhoto(bytes);
    } catch (error) {
      if (mounted) {
        showErrorToast(
          context,
          error is FormatException
              ? error.message
              : 'Não foi possível abrir a foto. Tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => picking = false);
    }
  }

  Future<void> _openPhoto(Uint8List source) async {
    if (mounted && !picking) setState(() => picking = true);
    try {
      final prepared = await compute(prepareAvatar, source);
      if (!mounted) return;
      ref.invalidate(avatarViewModelProvider);
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => AvatarEditorPage(image: prepared)),
      );
      if (!mounted) return;
      ref.invalidate(avatarViewModelProvider);
      if (saved == true) _success('Foto de perfil atualizada.');
    } catch (error) {
      if (mounted) {
        showErrorToast(
          context,
          error is FormatException
              ? error.message
              : 'Não foi possível preparar a foto.',
        );
      }
    } finally {
      if (mounted) setState(() => picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final state = ref.watch(detailsViewModelProvider);
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final user = session.user;
        if (user == null) {
          return const ProfileSubpage(
            title: 'Dados pessoais',
            child: Center(child: Text('Não foi possível carregar seus dados.')),
          );
        }
        final disabled = state.busy || transitioning || picking;
        final birth = DateTime.tryParse(user.birthDate ?? '');
        final initials = user.name
            .trim()
            .split(RegExp(r'\s+'))
            .where((part) => part.isNotEmpty)
            .take(2)
            .map((part) => part.characters.first.toUpperCase())
            .join();
        final model = ref.read(detailsViewModelProvider.notifier);
        return PopScope(
          canPop: !state.editing && !disabled,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _back();
          },
          child: ProfileSubpage(
            title: 'Dados pessoais',
            busy: disabled,
            onBack: _back,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: AppSurfaces.cardDecoration,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: AppColors.orangeSoft,
                              foregroundImage:
                                  user.avatarUrl?.isNotEmpty == true
                                  ? NetworkImage(user.avatarUrl!)
                                  : null,
                              onForegroundImageError:
                                  user.avatarUrl?.isNotEmpty == true
                                  ? (_, _) {}
                                  : null,
                              child: Text(
                                initials.isEmpty ? 'C' : initials,
                                style: const TextStyle(
                                  color: AppColors.primaryDark,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Foto de perfil',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (picking)
                                    const Text(
                                      'Preparando foto…',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    )
                                  else
                                    TextButton.icon(
                                      onPressed: disabled || state.editing
                                          ? null
                                          : _pickPhoto,
                                      icon: const Icon(
                                        RemixIcons.camera_line,
                                        size: 18,
                                      ),
                                      label: const Text('Alterar foto'),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        alignment: Alignment.centerLeft,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          const Icon(
                            RemixIcons.contacts_line,
                            size: 20,
                            color: AppColors.primaryDark,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Contato',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                            ),
                          ),
                          if (!state.editing)
                            TextButton.icon(
                              onPressed: disabled
                                  ? null
                                  : () => _switchEditing(true, user),
                              icon: const Icon(RemixIcons.edit_line, size: 18),
                              label: const Text('Editar'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FadeTransition(
                        opacity: CurvedAnimation(
                          parent: fade,
                          curve: AppMotion.curve,
                        ),
                        child: AbsorbPointer(
                          absorbing: disabled,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: AppSurfaces.cardDecoration,
                            child: state.editing
                                ? AutofillGroup(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CoreventField(
                                          label: 'Nome completo',
                                          initialValue: state.name,
                                          enabled: !state.busy,
                                          errorText: state.nameError,
                                          onChanged: model.changeName,
                                          keyboardType: TextInputType.name,
                                          autofillHints: const [
                                            AutofillHints.name,
                                          ],
                                          textInputAction: TextInputAction.next,
                                          scrollPadding: const EdgeInsets.only(
                                            bottom: 180,
                                          ),
                                        ),
                                        CoreventField(
                                          label: 'Telefone',
                                          hint: '(11) 91234-5678',
                                          initialValue: state.phone,
                                          enabled: !state.busy,
                                          errorText: state.phoneError,
                                          onChanged: model.changePhone,
                                          keyboardType: TextInputType.phone,
                                          autofillHints: const [
                                            AutofillHints
                                                .telephoneNumberNational,
                                          ],
                                          inputFormatters: [
                                            BrazilianPhoneFormatter(),
                                          ],
                                          textInputAction: TextInputAction.done,
                                          scrollPadding: const EdgeInsets.only(
                                            bottom: 180,
                                          ),
                                        ),
                                        const Text(
                                          'Telefone opcional · Brasil (+55)',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (state.error != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 16,
                                            ),
                                            child: Text(
                                              state.error!,
                                              style: const TextStyle(
                                                color: AppColors.error,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _DetailRow('Nome completo', user.name),
                                      const Divider(
                                        height: 32,
                                        color: AppColors.backgroundSecondary,
                                      ),
                                      _DetailRow(
                                        'Telefone',
                                        user.phoneNumber?.isNotEmpty == true
                                            ? formatPhone(user.phoneNumber!)
                                            : 'Não informado',
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Row(
                        children: [
                          Icon(
                            RemixIcons.id_card_line,
                            size: 20,
                            color: AppColors.primaryDark,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Identificação',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Dados de cadastro · somente leitura',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: AppSurfaces.cardDecoration,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DetailRow('E-mail', user.email),
                            const Divider(
                              height: 32,
                              color: AppColors.backgroundSecondary,
                            ),
                            _DetailRow(
                              user.documentType?.toUpperCase() ?? 'Documento',
                              formatDocument(user.document),
                            ),
                            const Divider(
                              height: 32,
                              color: AppColors.backgroundSecondary,
                            ),
                            _DetailRow(
                              'Data de nascimento',
                              birth == null
                                  ? 'Não informado'
                                  : DateFormat(
                                      'dd/MM/yyyy',
                                      'pt_BR',
                                    ).format(birth),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                if (state.editing)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      border: Border(top: AppSurfaces.outline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CoreventButton(
                          label: 'Salvar alterações',
                          busy: state.busy,
                          onPressed: state.dirty && state.valid && !disabled
                              ? () => _save(user)
                              : null,
                        ),
                        TextButton(
                          onPressed: disabled ? null : () => _cancel(user),
                          child: const Text('Cancelar edição'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        SelectableText(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
