import 'package:corevent_mobile_app/features/auth/data/auth_api.dart';
import 'package:corevent_mobile_app/features/auth/data/auth_dtos.dart';
import 'package:corevent_mobile_app/features/checkout/data/checkout_api.dart';
import 'package:corevent_mobile_app/features/tickets/data/tickets_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Dio dio;
  late List<RequestOptions> requests;

  setUp(() {
    requests = [];
    dio = Dio(BaseOptions(baseUrl: 'https://fixture.invalid'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          final body = switch (options.path) {
            '/api/auth/login' || '/api/auth/refresh' => {
              'accessToken': 'access',
              'refreshToken': 'refresh',
            },
            '/api/events/event-1/ticket-types' => {
              'data': <Object>[],
              'meta': {'currentPage': 1, 'totalPages': 1},
            },
            '/api/events/event-1/orders' => {
              'data': {
                'orderId': 'order-1',
                'checkoutLinks': [
                  {
                    'rel': 'pay',
                    'href': 'https://payment.invalid/order-1',
                    'method': 'GET',
                  },
                ],
                'ticketIds': ['ticket-1'],
              },
            },
            '/api/users/me/tickets' => {
              'data': <Object>[],
              'meta': {'currentPage': 2, 'totalPages': 3},
            },
            _ => null,
          };
          if (body == null) {
            handler.reject(DioException(requestOptions: options));
            return;
          }
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: body,
            ),
          );
        },
      ),
    );
  });

  tearDown(() => dio.close(force: true));

  test('auth serializa login e refresh nos contratos REST', () async {
    final api = AuthApi(dio);
    final login = await api.login(
      const LoginRequest('ana@test.invalid', 'Senha1!'),
    );
    final refreshed = await api.refresh(const RefreshRequest('refresh'));

    expect(login.accessToken, 'access');
    expect(refreshed.refreshToken, 'refresh');
    expect(requests.map((request) => request.path), [
      '/api/auth/login',
      '/api/auth/refresh',
    ]);
    expect(requests.first.method, 'POST');
    expect(requests.first.data, {
      'email': 'ana@test.invalid',
      'password': 'Senha1!',
    });
    expect(requests.last.data, {'refreshToken': 'refresh'});
  });

  test('checkout envia filtro e itens, e lê o link de pagamento', () async {
    final api = CheckoutApi(dio);
    final types = await api.ticketTypes('event-1', 1, 50, true);
    final order = await api.createOrder('event-1', {
      'items': [
        {'ticketTypeId': 'type-1', 'quantity': 2},
      ],
    });

    expect(types.meta.totalPages, 1);
    expect(requests.first.path, '/api/events/event-1/ticket-types');
    expect(requests.first.queryParameters, {
      'page': 1,
      'limit': 50,
      'availableOnly': true,
    });
    expect(requests.last.method, 'POST');
    expect(requests.last.data, {
      'items': [
        {'ticketTypeId': 'type-1', 'quantity': 2},
      ],
    });
    expect(order.data.orderId, 'order-1');
    expect(
      order.data.checkoutLinks.single.href,
      'https://payment.invalid/order-1',
    );
  });

  test('ingressos usam paginação e interpretam metadados da API', () async {
    final page = await TicketsApi(dio).mine(2, 20);

    expect(requests.single.path, '/api/users/me/tickets');
    expect(requests.single.queryParameters, {'page': 2, 'limit': 20});
    expect(page.meta.page, 2);
    expect(page.meta.totalPages, 3);
  });
}
