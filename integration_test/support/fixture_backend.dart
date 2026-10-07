import 'dart:convert';
import 'dart:typed_data';

import 'package:corevent_mobile_app/core/network/network_providers.dart';
import 'package:corevent_mobile_app/core/storage/token_store.dart';
import 'package:corevent_mobile_app/features/auth/data/auth_interceptor.dart';
import 'package:corevent_mobile_app/features/auth/data/auth_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Responds inside Dio on every target. No request reaches the production API.
class FixtureBackend {
  static const accessToken = 'integration-access';
  static const refreshToken = 'integration-refresh';
  static const orderId = 'integration-order';
  static const eventId = 'integration-event';

  bool failNextEvents = false;
  bool failNextEventDetail = false;
  bool failNextLogin = false;
  bool failNextRegister = false;
  bool failNextProfileUnauthorized = false;
  bool failRefresh = false;
  bool favoriteSaved = false;
  bool orderCreated = false;
  bool orderPaid = false;
  String profileName = 'Ana Teste';
  String? profilePhone;
  int createOrderCalls = 0;
  int updateProfileCalls = 0;
  int changePasswordCalls = 0;
  int verifyEmailCalls = 0;
  int forgotPasswordCalls = 0;
  int resetPasswordCalls = 0;
  int registerCalls = 0;
  int loginCalls = 0;
  int refreshCalls = 0;
  final unexpectedRequests = <String>[];
  final requests = <RequestOptions>[];

  void expectOnlySupportedRequests() {
    if (unexpectedRequests.isNotEmpty) {
      throw StateError('Unmocked requests: ${unexpectedRequests.join(', ')}');
    }
  }

  ProviderContainer createContainer() => ProviderContainer(
    overrides: [
      publicDioProvider.overrideWith((ref) {
        final dio = _dio();
        ref.onDispose(() => dio.close(force: true));
        return dio;
      }),
      authorizedDioProvider.overrideWith((ref) {
        final dio = _dio();
        dio.interceptors.insert(
          0,
          AuthInterceptor(
            dio,
            ref.read(authApiProvider),
            ref.read(tokenStoreProvider),
          ),
        );
        ref.onDispose(() => dio.close(force: true));
        return dio;
      }),
    ],
  );

  Dio _dio() {
    final dio = Dio(BaseOptions(baseUrl: 'https://fixture.invalid/'));
    dio.httpClientAdapter = _FixtureAdapter(this);
    return dio;
  }

  Future<ResponseBody> _fetch(RequestOptions options) async {
    requests.add(options);
    if (options.path == '/api/events' && failNextEvents) {
      failNextEvents = false;
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    if (options.path == '/api/events/$eventId' && failNextEventDetail) {
      failNextEventDetail = false;
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    final result = _response(options);
    if (result == null) {
      unexpectedRequests.add('${options.method} ${options.path}');
      return ResponseBody.fromString('null', 404);
    }
    return ResponseBody.fromString(
      jsonEncode(result.body),
      result.status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  ({int status, Object? body})? _response(RequestOptions request) {
    final path = request.path;
    final method = request.method.toUpperCase();
    if (method == 'POST' && path == '/api/auth/login') {
      loginCalls++;
      if (failNextLogin) {
        failNextLogin = false;
        return (status: 401, body: {'message': 'Credenciais inválidas'});
      }
      return (
        status: 200,
        body: {'accessToken': accessToken, 'refreshToken': refreshToken},
      );
    }
    if (method == 'POST' && path == '/api/auth/refresh') {
      refreshCalls++;
      if (failRefresh) {
        return (status: 401, body: {'message': 'Sessão expirada'});
      }
      return (
        status: 200,
        body: {'accessToken': accessToken, 'refreshToken': refreshToken},
      );
    }
    if (method == 'POST' && path == '/api/auth/verify-email') {
      verifyEmailCalls++;
      return (status: 200, body: {'message': 'Código enviado'});
    }
    if (method == 'POST' && path == '/api/auth/forgot-password') {
      forgotPasswordCalls++;
      return (status: 200, body: {'message': 'Código enviado'});
    }
    if (method == 'POST' && path == '/api/auth/reset-password') {
      resetPasswordCalls++;
      return (status: 200, body: {'message': 'Senha redefinida'});
    }
    if (method == 'POST' && path == '/api/auth/register') {
      registerCalls++;
      if (failNextRegister) {
        failNextRegister = false;
        return (status: 400, body: {'message': 'Código inválido'});
      }
      return (status: 204, body: null);
    }
    if (method == 'POST' && path == '/api/auth/logout') {
      return (status: 204, body: null);
    }
    if (method == 'GET' && path == '/api/users/me') {
      if (failNextProfileUnauthorized) {
        failNextProfileUnauthorized = false;
        return (status: 401, body: {'message': 'Token expirado'});
      }
      return _responseForProfile();
    }
    if (method == 'PATCH' && path == '/api/users') {
      updateProfileCalls++;
      final changes = request.data as Map<String, dynamic>;
      profileName = changes['name'] as String? ?? profileName;
      if (changes.containsKey('phoneNumber')) {
        profilePhone = changes['phoneNumber'] as String?;
      }
      return _responseForProfile();
    }
    if (method == 'PATCH' && path == '/api/users/pass') {
      changePasswordCalls++;
      return (status: 200, body: {'message': 'Senha alterada'});
    }
    if (method == 'GET' && path == '/api/events') {
      return (status: 200, body: _page([_event()]));
    }
    if (method == 'GET' && path == '/api/events/my/favorites') {
      return (
        status: 200,
        body: _page(
          favoriteSaved
              ? [
                  {..._event(), 'favoriteId': 'integration-favorite'},
                ]
              : [],
        ),
      );
    }
    if (method == 'POST' && path == '/api/favorites/events/$eventId') {
      favoriteSaved = true;
      return (
        status: 201,
        body: {
          'data': {'id': 'integration-favorite', 'eventId': eventId},
        },
      );
    }
    if (method == 'DELETE' && path == '/api/favorites/integration-favorite') {
      favoriteSaved = false;
      return (status: 204, body: null);
    }
    if (method == 'GET' && path == '/api/events/$eventId') {
      return (
        status: 200,
        body: {
          'data': {
            ..._event(),
            'description': 'Evento de integração',
            'status': 'opened',
          },
        },
      );
    }
    if (method == 'GET' && path == '/api/events/$eventId/ticket-types') {
      return (status: 200, body: _page([_ticketType()]));
    }
    if (method == 'POST' && path == '/api/events/$eventId/orders') {
      createOrderCalls++;
      orderCreated = true;
      return (
        status: 201,
        body: {
          'data': {
            'orderId': orderId,
            'checkoutLinks': <Object>[],
            'ticketIds': ['integration-ticket'],
          },
        },
      );
    }
    if (method == 'GET' && path == '/api/events/my/orders') {
      return (status: 200, body: _page(orderCreated ? [_order()] : []));
    }
    if (method == 'GET' && path == '/api/events/orders/$orderId') {
      if (!orderCreated) return null;
      return (
        status: 200,
        body: {
          'data': {
            ..._order(),
            'tickets': orderPaid ? [_orderTicket()] : <Map<String, Object?>>[],
            'checkout': null,
          },
        },
      );
    }
    if (method == 'GET' && path == '/api/users/me/tickets' ||
        method == 'GET' && path == '/api/events/$eventId/my/tickets') {
      return (
        status: 200,
        body: _page(orderCreated && orderPaid ? [_userTicket()] : []),
      );
    }
    if (method == 'GET' && path == '/api/events/my/ratings') {
      return (status: 200, body: _page([]));
    }
    return null;
  }

  Map<String, Object> _page(List<Map<String, Object?>> data) => {
    'data': data,
    'meta': {'currentPage': 1, 'totalPages': 1},
  };

  ({int status, Object? body}) _responseForProfile() => (
    status: 200,
    body: {
      'data': {
        'id': 'integration-user',
        'name': profileName,
        'email': 'ana@integration.test',
        'birthDate': '2000-01-01',
        'createdAt': '2026-01-01T12:00:00Z',
        'phoneNumber': profilePhone,
      },
    },
  );

  Map<String, Object?> _event() {
    final starts = DateTime.now().toUtc().add(const Duration(days: 3));
    return {
      'id': eventId,
      'title': 'Festival de integração',
      'startDate': starts.toIso8601String(),
      'endDate': starts.add(const Duration(hours: 3)).toIso8601String(),
      'category': 'music',
      'isAdultOnly': false,
      'locationName': 'Arena Teste',
      'organizer': {'name': 'Corevent'},
    };
  }

  Map<String, Object?> _ticketType() => {
    'id': 'integration-type',
    'name': 'Inteira',
    'price': '25.00',
    'availableQuantity': 5,
    'startDate': DateTime.now()
        .toUtc()
        .subtract(const Duration(days: 1))
        .toIso8601String(),
    'endDate': DateTime.now()
        .toUtc()
        .add(const Duration(days: 1))
        .toIso8601String(),
  };

  Map<String, Object?> _order() => {
    'id': orderId,
    'event': {
      'id': eventId,
      'title': 'Festival de integração',
      'startDate': _event()['startDate'],
    },
    'totalAmount': '25.00',
    'status': orderPaid ? 'paid' : 'pending',
    'createdAt': DateTime.now().toUtc().toIso8601String(),
  };

  Map<String, Object?> _orderTicket() => {
    'id': 'integration-ticket',
    'status': 'pending',
    'ticketType': {'name': 'Inteira', 'price': '25.00'},
  };

  Map<String, Object?> _userTicket() => {
    'id': 'integration-ticket',
    'status': 'pending',
    'qrToken': List.filled(64, 'a').join(),
    'ticketType': {'id': 'integration-type', 'name': 'Inteira', 'price': 25.0},
    'event': {'id': eventId, 'title': 'Festival de integração'},
    'order': {'id': orderId, 'status': 'paid'},
  };
}

class _FixtureAdapter implements HttpClientAdapter {
  _FixtureAdapter(this.backend);

  final FixtureBackend backend;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => backend._fetch(options);

  @override
  void close({bool force = false}) {}
}
