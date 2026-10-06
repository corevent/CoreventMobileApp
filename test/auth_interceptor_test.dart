import 'dart:async';

import 'package:corevent_mobile_app/core/network/auth_tokens.dart';
import 'package:corevent_mobile_app/core/storage/token_store.dart';
import 'package:corevent_mobile_app/features/auth/data/auth_api.dart';
import 'package:corevent_mobile_app/features/auth/data/auth_dtos.dart';
import 'package:corevent_mobile_app/features/auth/data/auth_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthApi extends Mock implements AuthApi {}

class MemoryTokenStore extends TokenStore {
  MemoryTokenStore() : super(const FlutterSecureStorage());

  String? access = 'expired';
  String? refresh = 'refresh-1';
  int clearCount = 0;

  @override
  Future<String?> readAccess() async => access;

  @override
  Future<String?> readRefresh() async => refresh;

  @override
  Future<void> save(String newAccess, String newRefresh) async {
    access = newAccess;
    refresh = newRefresh;
    notifyListeners();
  }

  @override
  Future<void> clear() async {
    clearCount++;
    access = null;
    refresh = null;
    notifyListeners();
  }
}

class AuthAdapter implements HttpClientAdapter {
  AuthAdapter(this.statusFor);

  final int Function(RequestOptions) statusFor;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final status = statusFor(options);
    return ResponseBody.fromString(
      '{}',
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUpAll(() => registerFallbackValue(const RefreshRequest('fallback')));

  late Dio dio;
  late MockAuthApi api;
  late MemoryTokenStore tokens;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://api.example/'));
    api = MockAuthApi();
    tokens = MemoryTokenStore();
    dio.interceptors.add(AuthInterceptor(dio, api, tokens));
  });

  tearDown(() {
    dio.close(force: true);
    tokens.dispose();
  });

  test(
    'envia Bearer e compartilha um refresh entre chamadas concorrentes',
    () async {
      final pendingRefresh = Completer<AuthTokens>();
      final refreshStarted = Completer<void>();
      when(() => api.refresh(any())).thenAnswer((_) {
        refreshStarted.complete();
        return pendingRefresh.future;
      });
      final adapter = AuthAdapter(
        (request) =>
            request.headers['Authorization'] == 'Bearer renewed' ? 200 : 401,
      );
      dio.httpClientAdapter = adapter;

      final first = dio.get<Map<String, dynamic>>('/first');
      final second = dio.get<Map<String, dynamic>>('/second');
      await refreshStarted.future;
      await Future<void>.delayed(Duration.zero);
      verify(() => api.refresh(any())).called(1);

      pendingRefresh.complete(
        const AuthTokens(accessToken: 'renewed', refreshToken: 'refresh-2'),
      );
      final responses = await Future.wait([first, second]);
      expect(responses.map((response) => response.statusCode), [200, 200]);
      expect(adapter.requests.length, 4);
      expect(
        adapter.requests
            .where(
              (request) => request.headers['Authorization'] == 'Bearer renewed',
            )
            .length,
        2,
      );
      expect(tokens.access, 'renewed');
      expect(tokens.refresh, 'refresh-2');
      expect(tokens.clearCount, 0);
    },
  );

  test(
    '401 após a repetição limpa a sessão sem tentar refresh de novo',
    () async {
      when(() => api.refresh(any())).thenAnswer(
        (_) async =>
            const AuthTokens(accessToken: 'renewed', refreshToken: 'refresh-2'),
      );
      final adapter = AuthAdapter((_) => 401);
      dio.httpClientAdapter = adapter;

      await expectLater(
        dio.get<dynamic>('/private'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.requests.length, 2);
      verify(() => api.refresh(any())).called(1);
      expect(tokens.clearCount, 1);
    },
  );

  test('refresh rejeitado definitivamente limpa os tokens', () async {
    when(() => api.refresh(any())).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/api/auth/refresh'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/auth/refresh'),
          statusCode: 401,
        ),
        type: DioExceptionType.badResponse,
      ),
    );
    dio.httpClientAdapter = AuthAdapter((_) => 401);

    await expectLater(
      dio.get<dynamic>('/private'),
      throwsA(isA<DioException>()),
    );
    expect(tokens.clearCount, 1);
    expect(tokens.access, isNull);
  });

  test('falha de rede no refresh preserva os tokens', () async {
    when(() => api.refresh(any())).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/api/auth/refresh'),
        type: DioExceptionType.connectionError,
      ),
    );
    dio.httpClientAdapter = AuthAdapter((_) => 401);

    await expectLater(
      dio.get<dynamic>('/private'),
      throwsA(isA<DioException>()),
    );
    expect(tokens.clearCount, 0);
    expect(tokens.access, 'expired');
    expect(tokens.refresh, 'refresh-1');
  });
}
