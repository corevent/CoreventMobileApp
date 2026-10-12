import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/network/auth_tokens.dart';
import '../../../core/storage/token_store.dart';
import 'auth_api.dart';
import 'auth_dtos.dart';

/// Shared by restoration and intercepted requests, using the public auth client.
class AuthRefresh {
  AuthRefresh(this._api, this._tokens, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static const fallbackRetryDelay = Duration(seconds: 10);
  final AuthApi _api;
  final TokenStore _tokens;
  final DateTime Function() _now;
  Future<AuthTokens>? _pending;
  DateTime? _retryAt;
  String? _rateLimitedToken;

  Future<AuthTokens> refresh(String token) {
    if (_pending != null) return _pending!;
    final retryAt = _retryAt;
    if (token == _rateLimitedToken &&
        retryAt != null &&
        _now().isBefore(retryAt)) {
      final options = RequestOptions(path: '/api/auth/refresh');
      final seconds = (retryAt.difference(_now()).inMilliseconds / 1000).ceil();
      return Future.error(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            requestOptions: options,
            statusCode: 429,
            headers: Headers.fromMap({
              'retry-after': ['$seconds'],
            }),
          ),
        ),
      );
    }
    return _pending = _refresh(token).whenComplete(() => _pending = null);
  }

  Future<AuthTokens> _refresh(String token) async {
    try {
      final tokens = await _api.refresh(RefreshRequest(token));
      await _tokens.save(tokens.accessToken, tokens.refreshToken);
      _retryAt = null;
      _rateLimitedToken = null;
      return tokens;
    } on DioException catch (error) {
      if (isPermanentRefreshFailure(error)) {
        await _tokens.clear();
      } else if (error.response?.statusCode == 429) {
        _rateLimitedToken = token;
        _retryAt = _now().add(retryDelay(error, _now()));
      }
      rethrow;
    }
  }

  static bool isPermanentRefreshFailure(DioException error) =>
      const [400, 401, 403].contains(error.response?.statusCode);

  static Duration retryDelay(DioException error, DateTime now) {
    final value = error.response?.headers.value('retry-after')?.trim();
    if (value == null) return fallbackRetryDelay;
    final seconds = int.tryParse(value);
    if (seconds != null) {
      return seconds >= 0 ? Duration(seconds: seconds) : fallbackRetryDelay;
    }
    try {
      final delay = HttpDate.parse(value).difference(now);
      return delay.isNegative ? Duration.zero : delay;
    } on HttpException {
      return fallbackRetryDelay;
    }
  }
}
