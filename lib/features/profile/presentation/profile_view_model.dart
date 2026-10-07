import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_session.dart';

class ProfileState {
  const ProfileState({this.busy = false, this.error});
  final bool busy;
  final String? error;
}

class ProfileViewModel extends Notifier<ProfileState> {
  @override
  ProfileState build() => const ProfileState();

  Future<void> refresh() async {
    if (state.busy) return;
    state = const ProfileState(busy: true);
    try {
      await ref.read(authSessionProvider).refreshProfile();
      if (ref.mounted) state = const ProfileState();
    } catch (_) {
      if (ref.mounted) {
        state = const ProfileState(
          error: 'Não foi possível atualizar seu perfil.',
        );
      }
    }
  }

  Future<void> logout() async {
    if (state.busy) return;
    state = const ProfileState(busy: true);
    try {
      await ref.read(authSessionProvider).logout();
    } finally {
      if (ref.mounted) state = const ProfileState();
    }
  }
}

final profileViewModelProvider =
    NotifierProvider<ProfileViewModel, ProfileState>(ProfileViewModel.new);
