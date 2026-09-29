import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_dtos.dart';
import '../../auth/presentation/auth_session.dart';
import '../data/profile_repository.dart';
import '../domain/profile_formatters.dart';

class ProfileFormState {
  const ProfileFormState({this.busy = false, this.error, this.success = false});
  final bool busy;
  final String? error;
  final bool success;
}

class DetailsState {
  const DetailsState({
    this.editing = false,
    this.busy = false,
    this.name = '',
    this.phone = '',
    this.originalName = '',
    this.originalPhone = '',
    this.nameError,
    this.phoneError,
    this.error,
  });
  final bool editing;
  final bool busy;
  final String name;
  final String phone;
  final String originalName;
  final String originalPhone;
  final String? nameError;
  final String? phoneError;
  final String? error;
  bool get dirty =>
      name.trim() != originalName.trim() ||
      normalizePhone(phone) != normalizePhone(originalPhone);
  bool get valid =>
      name.trim().isNotEmpty &&
      (phone.trim().isEmpty ||
          RegExp(r'^\+55\d{10,11}$').hasMatch(normalizePhone(phone)));
}

class DetailsViewModel extends Notifier<DetailsState> {
  @override
  DetailsState build() => const DetailsState();

  void edit(UserProfile user) {
    state = DetailsState(
      editing: true,
      name: user.name,
      phone: formatPhone(user.phoneNumber ?? ''),
      originalName: user.name,
      originalPhone: user.phoneNumber ?? '',
    );
  }

  void cancel() => state = const DetailsState();

  void changeName(String value) => _change(name: value);
  void changePhone(String value) => _change(phone: value);

  void _change({String? name, String? phone}) {
    if (state.busy) return;
    final nextName = name ?? state.name;
    final nextPhone = phone ?? state.phone;
    state = DetailsState(
      editing: true,
      name: nextName,
      phone: nextPhone,
      originalName: state.originalName,
      originalPhone: state.originalPhone,
      nameError: nextName.trim().isEmpty ? 'Informe seu nome.' : null,
      phoneError:
          nextPhone.isNotEmpty &&
              !RegExp(r'^\+55\d{10,11}$').hasMatch(normalizePhone(nextPhone))
          ? 'Informe o DDD e um telefone válido.'
          : null,
    );
  }

  Future<bool> save() async {
    if (state.busy || !state.dirty || !state.valid) return false;
    final draft = state;
    state = DetailsState(
      editing: true,
      busy: true,
      name: draft.name,
      phone: draft.phone,
      originalName: draft.originalName,
      originalPhone: draft.originalPhone,
    );
    try {
      final changes = <String, dynamic>{
        if (draft.name.trim() != draft.originalName.trim())
          'name': draft.name.trim(),
        if (normalizePhone(draft.phone) != normalizePhone(draft.originalPhone))
          'phoneNumber': draft.phone.trim().isEmpty
              ? null
              : normalizePhone(draft.phone),
      };
      final updated = await ref
          .read(profileRepositoryProvider)
          .updateFields(changes);
      if (!ref.mounted) return false;
      ref.read(authSessionProvider).updateUser(updated);
      state = DetailsState(
        editing: true,
        name: updated.name,
        phone: formatPhone(updated.phoneNumber ?? ''),
        originalName: updated.name,
        originalPhone: updated.phoneNumber ?? '',
      );
      return true;
    } catch (_) {
      if (ref.mounted) {
        state = DetailsState(
          editing: true,
          name: draft.name,
          phone: draft.phone,
          originalName: draft.originalName,
          originalPhone: draft.originalPhone,
          error: 'Não foi possível salvar seus dados.',
        );
      }
      return false;
    }
  }
}

final detailsViewModelProvider =
    NotifierProvider<DetailsViewModel, DetailsState>(DetailsViewModel.new);

class SecurityViewModel extends Notifier<ProfileFormState> {
  @override
  ProfileFormState build() => const ProfileFormState();

  Future<bool> change(String current, String next, String confirmation) async {
    if (state.busy) return false;
    if (current.isEmpty) {
      state = const ProfileFormState(error: 'Informe a senha atual.');
      return false;
    }
    if (next.length < 8 ||
        !RegExp(r'[A-Z]').hasMatch(next) ||
        !RegExp(r'[a-z]').hasMatch(next) ||
        !RegExp(r'\d').hasMatch(next) ||
        !RegExp(r'[^A-Za-z0-9]').hasMatch(next)) {
      state = const ProfileFormState(
        error: 'A nova senha precisa de 8 caracteres, maiúscula, minúscula, número e símbolo.',
      );
      return false;
    }
    if (next != confirmation) {
      state = const ProfileFormState(error: 'As novas senhas não coincidem.');
      return false;
    }
    state = const ProfileFormState(busy: true);
    try {
      await ref.read(profileRepositoryProvider).changePassword(current, next);
      if (ref.mounted) state = const ProfileFormState(success: true);
      return true;
    } catch (_) {
      if (ref.mounted) {
        state = const ProfileFormState(
          error: 'Não foi possível alterar a senha. Confira a senha atual.',
        );
      }
      return false;
    }
  }
}

final securityViewModelProvider =
    NotifierProvider<SecurityViewModel, ProfileFormState>(
      SecurityViewModel.new,
    );
