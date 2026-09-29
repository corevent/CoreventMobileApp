import 'package:corevent_mobile_app/features/tickets/data/ticket_dtos.dart';
import 'package:corevent_mobile_app/features/tickets/data/tickets_api.dart';
import 'package:corevent_mobile_app/features/tickets/data/tickets_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTicketsApi extends Mock implements TicketsApi {}

void main() {
  test('consulta ingressos da conta em páginas de 20', () async {
    final api = MockTicketsApi();
    const response = TicketPage(
      data: [],
      meta: TicketPageMeta(page: 2, totalPages: 3),
    );
    when(() => api.mine(2, 20)).thenAnswer((_) async => response);
    expect(await TicketsRepository(api).list(page: 2), same(response));
    verify(() => api.mine(2, 20)).called(1);
  });

  test('lê evento, tipo, pedido e status do contrato do MAUI', () {
    final token = List.filled(64, 'a').join();
    final response = TicketPage.fromJson({
      'data': [
        {
          'id': 'ticket-1',
          'status': 'pending',
          'qrToken': token,
          'checkinAt': null,
          'ticketType': {'id': 'type-1', 'name': 'Inteira', 'price': 85.5},
          'event': {'id': 'event-1', 'title': 'Festival'},
          'order': {'id': 'order-1', 'status': 'paid'},
        },
      ],
      'meta': {'currentPage': 1, 'itemsPerPage': 20, 'totalPages': 1},
    });
    expect(response.data.single.event.title, 'Festival');
    expect(response.data.single.ticketType.price, 85.5);
    expect(response.data.single.status, 'pending');
    expect(response.data.single.qrToken, token);
  });

  test('atualiza um ingresso pelo evento e identifica o mesmo ID', () async {
    final api = MockTicketsApi();
    const ticket = UserTicket(
      id: 'ticket-1',
      status: 'pending',
      qrToken: 'abc',
      ticketType: UserTicketType(id: 'type-1', name: 'Inteira', price: 50),
      event: UserTicketEvent(id: 'event-1', title: 'Festival'),
      order: UserTicketOrder(id: 'order-1', status: 'paid'),
    );
    when(() => api.mineForEvent('event-1'))
        .thenAnswer((_) async => const EventTicketsResponse(data: [ticket]));
    expect(await TicketsRepository(api).refreshTicket(ticket), same(ticket));
    verify(() => api.mineForEvent('event-1')).called(1);
  });
}
