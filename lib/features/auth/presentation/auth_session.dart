import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/token_store.dart';
import '../data/auth_dtos.dart';
import '../data/auth_repository.dart';

enum SessionStatus { loading, authenticated, unauthenticated, networkError }

class AuthSession extends ChangeNotifier {
  AuthSession(this._repository, this._tokens) {
    _tokens.addListener(_onTokensChanged);
  }

  final AuthRepository _repository;
  final TokenStore _tokens;
  SessionStatus status = SessionStatus.loading;
  UserProfile? user;
  String? recoveryMessage;

  Future<void> restore() async {
    status = SessionStatus.loading;
    recoveryMessage = null;
    notifyListeners();
    try {
      user = await _repository.restore();
      status = user == null
          ? SessionStatus.unauthenticated
          : SessionStatus.authenticated;
    } on DioException catch (error) {
      final access = await _tokens.readAccess();
      final refresh = await _tokens.readRefresh();
      status =
          (access == null || access.isEmpty) &&
              (refresh == null || refresh.isEmpty)
          ? SessionStatus.unauthenticated
          : SessionStatus.networkError;
      if (error.response?.statusCode == 429) {
        recoveryMessage =
            'Muitas tentativas. Aguarde um pouco antes de tentar novamente.';
      }
    } catch (_) {
      status = SessionStatus.networkError;
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    user = await _repository.login(email, password);
    status = SessionStatus.authenticated;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    user = await _repository.refreshProfile();
    notifyListeners();
  }

  void updateUser(UserProfile updated) {
    user = updated;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } finally {
      user = null;
      status = SessionStatus.unauthenticated;
      notifyListeners();
    }
  }

  void _onTokensChanged() {
    unawaited(_checkTokens());
  }

  Future<void> _checkTokens() async {
    final access = await _tokens.readAccess();
    final refresh = await _tokens.readRefresh();
    if ((access == null || access.isEmpty) &&
        (refresh == null || refresh.isEmpty)) {
      user = null;
      status = SessionStatus.unauthenticated;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _tokens.removeListener(_onTokensChanged);
    super.dispose();
  }
}

final authSessionProvider = Provider<AuthSession>((ref) {
  final session = AuthSession(
    ref.watch(authRepositoryProvider),
    ref.watch(tokenStoreProvider),
  );
  ref.onDispose(session.dispose);
  scheduleMicrotask(session.restore);
  return session;
});
