import 'dart:async';

import 'package:corevent_mobile_app/core/network/auth_tokens.dart';
import 'package:corevent_mobile_app/core/storage/token_store.dart';
import 'package:corevent_mobile_app/features/auth/data/auth_api.dart';
import 'package:corevent_mobile_app/features/auth/data/auth_dtos.dart';
import 'package:corevent_mobile_app/features/auth/data/auth_interceptor.dart';
import 'package:corevent_mobile_app/features/auth/data/auth_refresh.dart';
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
  AuthAdapter(this.statusFor, {this.beforeResponse});

  final int Function(RequestOptions) statusFor;
  final Future<void> Function(RequestOptions)? beforeResponse;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    await beforeResponse?.call(options);
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

  test(
    '429 preserva sessão, respeita espera e recupera na próxima chamada',
    () async {
      var now = DateTime.utc(2026, 10, 12);
      final refresh = AuthRefresh(api, tokens, now: () => now);
      dio.interceptors.clear();
      dio.interceptors.add(AuthInterceptor(dio, api, tokens, refresh: refresh));
      final options = RequestOptions(path: '/api/auth/refresh');
      when(() => api.refresh(any())).thenThrow(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            requestOptions: options,
            statusCode: 429,
            headers: Headers.fromMap({
              'retry-after': ['30'],
            }),
          ),
        ),
      );
      dio.httpClientAdapter = AuthAdapter(
        (request) =>
            request.headers['Authorization'] == 'Bearer renewed' ? 200 : 401,
      );
      for (var i = 0; i < 2; i++) {
        await expectLater(
          dio.get<dynamic>('/private'),
          throwsA(
            isA<DioException>().having(
              (e) => e.response?.statusCode,
              'status',
              429,
            ),
          ),
        );
      }
      verify(() => api.refresh(any())).called(1);
      expect(tokens.clearCount, 0);
      expect(tokens.access, 'expired');
      expect(tokens.refresh, 'refresh-1');
      now = now.add(const Duration(seconds: 30));
      when(() => api.refresh(any())).thenAnswer(
        (_) async =>
            const AuthTokens(accessToken: 'renewed', refreshToken: 'refresh-2'),
      );
      expect((await dio.get<dynamic>('/private')).statusCode, 200);
      verify(() => api.refresh(any())).called(1);
    },
  );

  test('403 de uma operação protegida não é rejeição do refresh', () async {
    dio.httpClientAdapter = AuthAdapter((_) => 403);
    await expectLater(
      dio.get<dynamic>('/private'),
      throwsA(isA<DioException>()),
    );
    verifyNever(() => api.refresh(any()));
    expect(tokens.clearCount, 0);
  });

  test(
    '503 na repetição preserva os tokens renovados e não repete de novo',
    () async {
      when(() => api.refresh(any())).thenAnswer(
        (_) async =>
            const AuthTokens(accessToken: 'renewed', refreshToken: 'refresh-2'),
      );
      final adapter = AuthAdapter(
        (request) =>
            request.headers['Authorization'] == 'Bearer renewed' ? 503 : 401,
      );
      dio.httpClientAdapter = adapter;
      await expectLater(
        dio.get<dynamic>('/private'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.requests, hasLength(2));
      verify(() => api.refresh(any())).called(1);
      expect(tokens.access, 'renewed');
      expect(tokens.clearCount, 0);
    },
  );

  test('401 atrasado reutiliza token já renovado sem outro refresh', () async {
    final started = Completer<void>();
    final release = Completer<void>();
    when(() => api.refresh(any())).thenAnswer(
      (_) async =>
          const AuthTokens(accessToken: 'renewed', refreshToken: 'refresh-2'),
    );
    dio.httpClientAdapter = AuthAdapter(
      (request) =>
          request.headers['Authorization'] == 'Bearer renewed' ? 200 : 401,
      beforeResponse: (request) async {
        if (request.path == '/late' &&
            request.headers['Authorization'] == 'Bearer expired') {
          started.complete();
          await release.future;
        }
      },
    );
    final late = dio.get<dynamic>('/late');
    await started.future;
    expect((await dio.get<dynamic>('/first')).statusCode, 200);
    release.complete();
    expect((await late).statusCode, 200);
    verify(() => api.refresh(any())).called(1);
  });
}
