import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_session.dart';
import '../data/avatar_repository.dart';

class AvatarState {
  const AvatarState({
    this.busy = false,
    this.confirming = false,
    this.progress = 0,
    this.uploadedKey,
    this.error,
  });
  final bool busy;
  final bool confirming;
  final double progress;
  final String? uploadedKey;
  final String? error;
}

class AvatarViewModel extends Notifier<AvatarState> {
  @override
  AvatarState build() => const AvatarState();

  Future<bool> save(Uint8List bytes) async {
    if (state.busy) return false;
    var key = state.uploadedKey;
    var stage = key == null ? 'upload' : 'confirm';
    state = AvatarState(busy: true, confirming: key != null, uploadedKey: key);
    try {
      key ??= await ref.read(avatarRepositoryProvider).upload(bytes, (
        progress,
      ) {
        if (ref.mounted) state = AvatarState(busy: true, progress: progress);
      });
      if (!ref.mounted) return false;
      state = AvatarState(
        busy: true,
        confirming: true,
        progress: 1,
        uploadedKey: key,
      );
      stage = 'confirm';
      final user = await ref.read(avatarRepositoryProvider).confirm(key);
      if (!ref.mounted) return false;
      stage = 'updateSession';
      ref.read(authSessionProvider).updateUser(user);
      state = const AvatarState();
      return true;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrintStack(
          label: '[Avatar/save] stage=$stage exception=${error.runtimeType}',
          stackTrace: stackTrace,
        );
      }
      if (ref.mounted) {
        state = AvatarState(
          uploadedKey: key,
          error: key == null
              ? 'Não foi possível enviar a foto. Tente novamente.'
              : 'A foto foi enviada, mas a confirmação falhou. Tente novamente.',
        );
      }
      return false;
    }
  }
}

final avatarViewModelProvider = NotifierProvider<AvatarViewModel, AvatarState>(
  AvatarViewModel.new,
);
