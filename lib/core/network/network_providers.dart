import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _configuredApiBaseUrl = String.fromEnvironment('COREVENT_API_URL');

final apiBaseUrl = _configuredApiBaseUrl.isNotEmpty
    ? _configuredApiBaseUrl
    : 'https://api.corevent.site/';

BaseOptions apiOptions() => BaseOptions(
  baseUrl: apiBaseUrl,
  connectTimeout: const Duration(seconds: 15),
  receiveTimeout: const Duration(seconds: 30),
);

final publicDioProvider = Provider<Dio>((ref) {
  final dio = Dio(apiOptions());
  ref.onDispose(() => dio.close(force: true));
  return dio;
});
