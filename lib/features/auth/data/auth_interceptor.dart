import 'package:dio/dio.dart';

import '../../../core/network/auth_tokens.dart';
import '../../../core/storage/token_store.dart';
import 'auth_api.dart';
import 'auth_dtos.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._dio, this._api, this._tokens);

  static const _retriedKey = 'auth_retried';
  final Dio _dio;
  final AuthApi _api;
  final TokenStore _tokens;
  Future<AuthTokens>? _refreshing;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final access = await _tokens.readAccess();
      if (access != null && access.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $access';
      }
      handler.next(options);
    } catch (error) {
      handler.reject(DioException(requestOptions: options, error: error));
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }
    if (err.requestOptions.extra[_retriedKey] == true) {
      await _tokens.clear();
      handler.next(err);
      return;
    }

    final refresh = await _tokens.readRefresh();
    if (refresh == null || refresh.isEmpty) {
      await _tokens.clear();
      handler.next(err);
      return;
    }

    try {
      final tokens = await (_refreshing ??= _refresh(refresh));
      final request = err.requestOptions;
      final retry = request.copyWith(
        headers: {
          ...request.headers,
          'Authorization': 'Bearer ${tokens.accessToken}',
        },
        extra: {...request.extra, _retriedKey: true},
      );
      handler.resolve(await _dio.fetch<dynamic>(retry));
    } on DioException catch (refreshError) {
      if (_isPermanentRefreshFailure(refreshError)) await _tokens.clear();
      handler.next(refreshError);
    } catch (refreshError) {
      handler.reject(
        DioException(requestOptions: err.requestOptions, error: refreshError),
      );
    } finally {
      _refreshing = null;
    }
  }

  Future<AuthTokens> _refresh(String refresh) async {
    final tokens = await _api.refresh(RefreshRequest(refresh));
    await _tokens.save(tokens.accessToken, tokens.refreshToken);
    return tokens;
  }

  static bool _isPermanentRefreshFailure(DioException error) {
    final code = error.response?.statusCode;
    return code != null && code >= 400 && code < 500;
  }
}
