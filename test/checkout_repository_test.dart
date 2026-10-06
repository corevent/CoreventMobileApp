import 'package:corevent_mobile_app/features/checkout/data/checkout_api.dart';
import 'package:corevent_mobile_app/features/checkout/data/checkout_dtos.dart';
import 'package:corevent_mobile_app/features/checkout/data/checkout_repository.dart';
import 'package:corevent_mobile_app/features/events/data/event_dtos.dart';
import 'package:corevent_mobile_app/features/events/data/events_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCheckoutApi extends Mock implements CheckoutApi {}

class MockEventsRepository extends Mock implements EventsRepository {}

void main() {
  test('lê preço decimal textual e une páginas sem duplicar tipos', () async {
    final api = MockCheckoutApi();
    final events = MockEventsRepository();
    final event = EventDetail(
      id: 'e1',
      title: 'Festival',
      startDate: DateTime.utc(2026, 10, 1),
      endDate: DateTime.utc(2026, 10, 2),
      category: 'music',
      isAdultOnly: false,
      locationName: 'Arena',
      organizer: const EventOrganizer(name: 'Org'),
    );
    when(() => events.detail('e1')).thenAnswer((_) async => event);
    Map<String, dynamic> item(String id, String price) => {
      'id': id,
      'name': id,
      'price': price,
      'availableQuantity': 2,
      'startDate': '2026-09-01T00:00:00Z',
      'endDate': '2026-10-01T00:00:00Z',
    };
    when(() => api.ticketTypes('e1', 1, 50, true)).thenAnswer(
      (_) async => TicketTypePage.fromJson({
        'data': [item('a', '25.50')],
        'meta': {'currentPage': 1, 'totalPages': 2},
      }),
    );
    when(() => api.ticketTypes('e1', 2, 50, true)).thenAnswer(
      (_) async => TicketTypePage.fromJson({
        'data': [item('a', '25.50'), item('b', '0.00')],
        'meta': {'currentPage': 2, 'totalPages': 2},
      }),
    );
    final catalog = await CheckoutRepository(api, events).catalog('e1');
    expect(catalog.types.map((type) => type.id), ['a', 'b']);
    expect(catalog.types.first.price, 25.5);
    expect(catalog.types.last.price, 0);
  });
}
