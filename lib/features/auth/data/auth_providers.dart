import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../../core/storage/token_store.dart';
import 'auth_api.dart';
import 'auth_interceptor.dart';

final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(ref.watch(publicDioProvider)),
);

final authorizedDioProvider = Provider<Dio>((ref) {
  final dio = Dio(apiOptions());
  dio.interceptors.add(
    AuthInterceptor(
      dio,
      ref.watch(authApiProvider),
      ref.watch(tokenStoreProvider),
    ),
  );
  ref.onDispose(() => dio.close(force: true));
  return dio;
});

final profileApiProvider = Provider<ProfileApi>(
  (ref) => ProfileApi(ref.watch(authorizedDioProvider)),
);
