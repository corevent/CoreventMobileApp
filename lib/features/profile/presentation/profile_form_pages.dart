import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:remixicon/remixicon.dart';

import '../../../core/design_system/app_surfaces.dart';
import '../../../core/design_system/corevent_field.dart';
import '../../../core/theme/app_colors.dart';
import 'profile_forms_view_model.dart';

class ProfileSubpage extends StatelessWidget {
  const ProfileSubpage({
    super.key,
    required this.title,
    required this.child,
    this.busy = false,
    this.onBack,
  });
  final String title;
  final Widget child;
  final bool busy;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.surface,
    appBar: AppBar(
      title: Text(title),
      backgroundColor: AppColors.surface,
      shape: const Border(bottom: AppSurfaces.outline),
      elevation: 0,
      automaticallyImplyLeading: !busy,
      leading: busy
          ? const IconButton(
              onPressed: null,
              icon: Icon(RemixIcons.arrow_left_line),
            )
          : onBack == null
          ? null
          : IconButton(
              tooltip: 'Voltar',
              onPressed: onBack,
              icon: const Icon(RemixIcons.arrow_left_line),
            ),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: child,
        ),
      ),
    ),
  );
}

class ProfileSecurityPage extends ConsumerStatefulWidget {
  const ProfileSecurityPage({super.key});
  @override
  ConsumerState<ProfileSecurityPage> createState() =>
      _ProfileSecurityPageState();
}

class _ProfileSecurityPageState extends ConsumerState<ProfileSecurityPage> {
  String current = '';
  String next = '';
  String confirmation = '';
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(securityViewModelProvider);
    return PopScope(
      canPop: !state.busy,
      child: ProfileSubpage(
        title: 'Segurança',
        busy: state.busy,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Escolha uma senha forte que você não usa em outros serviços.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            CoreventField(
              label: 'Senha atual',
              password: true,
              enabled: !state.busy,
              onChanged: (value) => current = value,
            ),
            CoreventField(
              label: 'Nova senha',
              password: true,
              enabled: !state.busy,
              onChanged: (value) => next = value,
            ),
            CoreventField(
              label: 'Confirmar nova senha',
              password: true,
              enabled: !state.busy,
              onChanged: (value) => confirmation = value,
            ),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  state.error!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            FilledButton(
              onPressed: state.busy
                  ? null
                  : () async {
                      final changed = await ref
                          .read(securityViewModelProvider.notifier)
                          .change(current, next, confirmation);
                      if (changed && context.mounted) context.pop();
                    },
              child: Text(state.busy ? 'Alterando…' : 'Alterar senha'),
            ),
          ],
        ),
      ),
    );
  }
}
