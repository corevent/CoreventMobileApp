import 'dart:async';
import 'dart:io';

import 'package:corevent_mobile_app/core/network/auth_tokens.dart';
import 'package:corevent_mobile_app/core/storage/token_store.dart';
import 'package:corevent_mobile_app/features/auth/data/auth_api.dart';
import 'package:corevent_mobile_app/features/auth/data/auth_dtos.dart';
import 'package:corevent_mobile_app/features/auth/data/auth_refresh.dart';
import 'package:corevent_mobile_app/features/auth/data/auth_repository.dart';
import 'package:corevent_mobile_app/features/auth/presentation/auth_session.dart';
import 'package:corevent_mobile_app/features/auth/presentation/authenticated_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _AuthApi extends Mock implements AuthApi {}

class _ProfileApi extends Mock implements ProfileApi {}

class _Tokens extends TokenStore {
  _Tokens() : super(const FlutterSecureStorage());
  String? access = 'expired';
  String? refreshToken = 'refresh-1';
  int clears = 0;

  @override
  Future<String?> readAccess() async => access;
  @override
  Future<String?> readRefresh() async => refreshToken;
  @override
  Future<void> save(String access, String refresh) async {
    this.access = access;
    refreshToken = refresh;
    notifyListeners();
  }

  @override
  Future<void> clear() async {
    clears++;
    access = refreshToken = null;
    notifyListeners();
  }
}

DioException _failure(int status, {String? retryAfter}) {
  final options = RequestOptions(path: '/api/auth/refresh');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: status,
      headers: Headers.fromMap({
        if (retryAfter != null) 'retry-after': [retryAfter],
      }),
    ),
  );
}

void main() {
  setUpAll(() => registerFallbackValue(const RefreshRequest('fallback')));
  late _AuthApi api;
  late _ProfileApi profile;
  late _Tokens tokens;
  late DateTime now;
  late AuthRefresh refresh;
  const renewed = AuthTokens(accessToken: 'renewed', refreshToken: 'refresh-2');
  const user = UserProfile(id: 'user', name: 'Ana', email: 'ana@example.test');

  setUp(() {
    api = _AuthApi();
    profile = _ProfileApi();
    tokens = _Tokens();
    now = DateTime.utc(2026, 10, 12, 12);
    refresh = AuthRefresh(api, tokens, now: () => now);
    when(() => profile.me())
        .thenAnswer((_) async => const ProfileResponse(user));
  });
  tearDown(() => tokens.dispose());

  for (final status in [408, 429, 500, 503, 404, 422]) {
    test(
      'refresh $status preserva credenciais e permite tentativa posterior',
      () async {
        var calls = 0;
        when(() => api.refresh(any())).thenAnswer((_) async {
          if (++calls == 1) throw _failure(status);
          return renewed;
        });
        await expectLater(
          refresh.refresh('refresh-1'),
          throwsA(isA<DioException>()),
        );
        expect(tokens.access, 'expired');
        expect(tokens.refreshToken, 'refresh-1');
        expect(tokens.clears, 0);
        now = now.add(AuthRefresh.fallbackRetryDelay);
        expect(await refresh.refresh('refresh-1'), renewed);
        expect(tokens.access, 'renewed');
        expect(calls, 2);
      },
    );
  }

  for (final status in [400, 401, 403]) {
    test('rejeição definitiva $status revoga tokens', () async {
      when(() => api.refresh(any())).thenThrow(_failure(status));
      await expectLater(
        refresh.refresh('refresh-1'),
        throwsA(isA<DioException>()),
      );
      expect(tokens.access, isNull);
      expect(tokens.refreshToken, isNull);
      expect(tokens.clears, 1);
    });
  }

  test(
    'falhas de transporte preservam tokens sem bloquear nova tentativa',
    () async {
      for (final type in [
        DioExceptionType.connectionError,
        DioExceptionType.connectionTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        when(() => api.refresh(any())).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/auth/refresh'),
            type: type,
          ),
        );
        await expectLater(
          refresh.refresh('refresh-1'),
          throwsA(isA<DioException>()),
        );
        expect(tokens.access, 'expired');
        expect(tokens.refreshToken, 'refresh-1');
      }
      when(() => api.refresh(any())).thenAnswer((_) async => renewed);
      expect(await refresh.refresh('refresh-1'), renewed);
    },
  );

  test(
    '429 compartilha falha concorrente e impede chamadas antes de Retry-After',
    () async {
      final pending = Completer<AuthTokens>();
      when(() => api.refresh(any())).thenAnswer((_) => pending.future);
      final first = expectLater(
        refresh.refresh('refresh-1'),
        throwsA(isA<DioException>()),
      );
      final second = expectLater(
        refresh.refresh('refresh-1'),
        throwsA(isA<DioException>()),
      );
      pending.completeError(_failure(429, retryAfter: '30'));
      await Future.wait([first, second]);
      now = now.add(const Duration(seconds: 29));
      await expectLater(
        refresh.refresh('refresh-1'),
        throwsA(isA<DioException>()),
      );
      verify(() => api.refresh(any())).called(1);
      expect(tokens.clears, 0);
      now = now.add(const Duration(seconds: 1));
      when(() => api.refresh(any())).thenAnswer((_) async => renewed);
      expect(await refresh.refresh('refresh-1'), renewed);
      verify(() => api.refresh(any())).called(1);
    },
  );

  test('Retry-After interpreta segundos, data HTTP e valores inválidos', () {
    expect(
      AuthRefresh.retryDelay(_failure(429, retryAfter: '45'), now),
      const Duration(seconds: 45),
    );
    expect(
      AuthRefresh.retryDelay(
        _failure(
          429,
          retryAfter: HttpDate.format(now.add(const Duration(seconds: 60))),
        ),
        now,
      ),
      const Duration(seconds: 60),
    );
    expect(
      AuthRefresh.retryDelay(
        _failure(
          429,
          retryAfter: HttpDate.format(
            now.subtract(const Duration(seconds: 60)),
          ),
        ),
        now,
      ),
      Duration.zero,
    );
    for (final value in [null, '', '-1', 'invalid']) {
      expect(
        AuthRefresh.retryDelay(_failure(429, retryAfter: value), now),
        AuthRefresh.fallbackRetryDelay,
      );
    }
    expect(
      AuthRefresh.retryDelay(_failure(429, retryAfter: '0'), now),
      Duration.zero,
    );
  });

  test(
    'restauração sem access token mantém refresh em 429 e recupera sessão',
    () async {
      tokens.access = null;
      final repository = AuthRepository(api, profile, tokens, refresh: refresh);
      final session = AuthSession(repository, tokens);
      addTearDown(session.dispose);
      when(() => api.refresh(any())).thenThrow(_failure(429, retryAfter: '30'));
      await session.restore();
      expect(session.status, SessionStatus.networkError);
      expect(session.recoveryMessage, contains('Muitas tentativas'));
      expect(tokens.refreshToken, 'refresh-1');
      verifyNever(() => profile.me());
      await session.restore();
      verify(() => api.refresh(any())).called(1);
      now = now.add(const Duration(seconds: 30));
      when(() => api.refresh(any())).thenAnswer((_) async => renewed);
      await session.restore();
      expect(session.status, SessionStatus.authenticated);
      expect(session.user, user);
      expect(session.recoveryMessage, isNull);
    },
  );

  test(
    '403 do perfil não encerra sessão como se fosse refresh recusado',
    () async {
      when(() => profile.me()).thenThrow(_failure(403));
      final session = AuthSession(
        AuthRepository(api, profile, tokens, refresh: refresh),
        tokens,
      );
      addTearDown(session.dispose);
      await session.restore();
      expect(session.status, SessionStatus.networkError);
      expect(tokens.clears, 0);
      verifyNever(() => api.refresh(any()));
    },
  );

  test(
    'restore sem access compartilha refresh com outras requisições',
    () async {
      tokens.access = null;
      final pending = Completer<AuthTokens>();
      when(() => api.refresh(any())).thenAnswer((_) => pending.future);
      final repository = AuthRepository(api, profile, tokens, refresh: refresh);
      final restoring = repository.restore();
      await Future<void>.delayed(Duration.zero);
      final requestRefresh = refresh.refresh('refresh-1');
      verify(() => api.refresh(any())).called(1);
      pending.complete(renewed);
      expect(await restoring, user);
      expect(await requestRefresh, renewed);
    },
  );

  testWidgets('restauração limitada oferece nova tentativa sem mostrar login', (
    tester,
  ) async {
    tokens.access = null;
    when(() => api.refresh(any())).thenThrow(_failure(429, retryAfter: '0'));
    final session = AuthSession(
      AuthRepository(api, profile, tokens, refresh: refresh),
      tokens,
    );
    addTearDown(session.dispose);
    await session.restore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authSessionProvider.overrideWithValue(session)],
        child: const MaterialApp(home: SessionLoadingPage()),
      ),
    );
    expect(
      find.text(
        'Muitas tentativas. Aguarde um pouco antes de tentar novamente.',
      ),
      findsOneWidget,
    );
    expect(find.text('Entrar'), findsNothing);
    expect(tokens.refreshToken, 'refresh-1');
    when(() => api.refresh(any())).thenAnswer((_) async => renewed);
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(session.status, SessionStatus.authenticated);
    expect(tokens.access, 'renewed');
  });
}
