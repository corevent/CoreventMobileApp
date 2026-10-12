import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/token_store.dart';
import 'auth_api.dart';
import 'auth_dtos.dart';
import 'auth_providers.dart';
import 'auth_refresh.dart';

class AuthRepository {
  AuthRepository(
    this._api,
    this._profileApi,
    this._tokens, {
    AuthRefresh? refresh,
  }) : _refresh = refresh ?? AuthRefresh(_api, _tokens);

  final AuthApi _api;
  final ProfileApi _profileApi;
  final TokenStore _tokens;
  final AuthRefresh _refresh;

  Future<UserProfile> login(String email, String password) async {
    final tokens = await _api.login(LoginRequest(email.trim(), password));
    await _tokens.save(tokens.accessToken, tokens.refreshToken);
    return (await _profileApi.me()).data;
  }

  Future<UserProfile?> restore() async {
    final access = await _tokens.readAccess();
    final refresh = await _tokens.readRefresh();
    if ((access == null || access.isEmpty) &&
        (refresh == null || refresh.isEmpty)) {
      return null;
    }
    if ((access == null || access.isEmpty) &&
        refresh != null &&
        refresh.isNotEmpty) {
      await _refresh.refresh(refresh);
    }
    try {
      return (await _profileApi.me()).data;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) await _tokens.clear();
      rethrow;
    }
  }

  Future<UserProfile> refreshProfile() async => (await _profileApi.me()).data;

  Future<void> sendVerification(String email) =>
      _api.verifyEmail(EmailRequest(email.trim()));

  Future<void> register(RegisterRequest request) => _api.register(request);

  Future<void> sendResetCode(String email) =>
      _api.forgotPassword(EmailRequest(email.trim()));

  Future<void> resetPassword(String email, String code, String password) =>
      _api.resetPassword(ResetPasswordRequest(email.trim(), code, password));

  Future<void> logout() async {
    try {
      final refresh = await _tokens.readRefresh();
      if (refresh != null && refresh.isNotEmpty) {
        await _api.logout(RefreshRequest(refresh));
      }
    } catch (_) {
      // Local logout must still complete when the API is unavailable.
    } finally {
      await _tokens.clear();
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(authApiProvider),
    ref.watch(profileApiProvider),
    ref.watch(tokenStoreProvider),
    refresh: ref.watch(authRefreshProvider),
  ),
);
