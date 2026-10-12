import 'package:dio/dio.dart';

import '../../../core/storage/token_store.dart';
import 'auth_api.dart';
import 'auth_refresh.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._dio, AuthApi api, this._tokens, {AuthRefresh? refresh})
    : _refresh = refresh ?? AuthRefresh(api, _tokens);

  static const _retriedKey = 'auth_retried';
  final Dio _dio;
  final TokenStore _tokens;
  final AuthRefresh _refresh;

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
      final currentAccess = await _tokens.readAccess();
      // A late 401 may belong to a token already renewed by another request.
      final access =
          currentAccess != null &&
              currentAccess.isNotEmpty &&
              err.requestOptions.headers['Authorization'] !=
                  'Bearer $currentAccess'
          ? currentAccess
          : (await _refresh.refresh(refresh)).accessToken;
      final request = err.requestOptions;
      final retry = request.copyWith(
        headers: {...request.headers, 'Authorization': 'Bearer $access'},
        extra: {...request.extra, _retriedKey: true},
      );
      handler.resolve(await _dio.fetch<dynamic>(retry));
    } on DioException catch (refreshError) {
      handler.next(refreshError);
    } catch (refreshError) {
      handler.reject(
        DioException(requestOptions: err.requestOptions, error: refreshError),
      );
    }
  }
}
