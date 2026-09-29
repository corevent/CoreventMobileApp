import 'dart:async';

import 'package:corevent_mobile_app/features/events/data/events_repository.dart';
import 'package:corevent_mobile_app/features/tickets/data/ticket_dtos.dart';
import 'package:corevent_mobile_app/features/tickets/data/tickets_repository.dart';
import 'package:corevent_mobile_app/features/tickets/presentation/ticket_status.dart';
import 'package:corevent_mobile_app/features/tickets/presentation/tickets_page.dart';
import 'package:corevent_mobile_app/features/tickets/presentation/tickets_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTicketsRepository extends Mock implements TicketsRepository {}

class MockEventsRepository extends Mock implements EventsRepository {}

const ticketType = UserTicketType(id: 'type-1', name: 'Inteira', price: 75);
const ticketEvent = UserTicketEvent(id: 'event-1', title: 'Festival');
const ticketOrder = UserTicketOrder(id: 'order-1', status: 'paid');
UserTicket ticket(String id) => UserTicket(
  id: id,
  status: 'pending',
  ticketType: ticketType,
  event: ticketEvent,
  order: ticketOrder,
);
TicketPage page(List<UserTicket> items, int number, int total) => TicketPage(
  data: items,
  meta: TicketPageMeta(page: number, totalPages: total),
);

void main() {
  late MockTicketsRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockTicketsRepository();
    container = ProviderContainer(
      overrides: [ticketsRepositoryProvider.overrideWithValue(repository)],
    );
  });
  tearDown(() => container.dispose());

  test('ingresso pendente de pedido pago aparece disponível', () {
    expect(ticketVisualStatus(ticket('a')).label, 'Disponível');
    expect(canShowTicketQr(ticket('a')), isTrue);
    final awaitingPayment = UserTicket(
      id: 'pending',
      status: 'pending',
      ticketType: ticketType,
      event: ticketEvent,
      order: const UserTicketOrder(id: 'order-2', status: 'pending'),
    );
    expect(ticketVisualStatus(awaitingPayment).label, 'Aguardando pagamento');
    expect(canShowTicketQr(awaitingPayment), isFalse);
    final used = UserTicket(
      id: 'used',
      status: 'checked_in',
      ticketType: ticketType,
      event: ticketEvent,
      order: ticketOrder,
    );
    expect(canShowTicketQr(used), isFalse);
  });

  test('carrega ingressos reais e pagina sem duplicar', () async {
    when(() => repository.list(page: 1))
        .thenAnswer((_) async => page([ticket('a'), ticket('b')], 1, 2));
    when(() => repository.list(page: 2))
        .thenAnswer((_) async => page([ticket('b'), ticket('c')], 2, 2));
    final model = container.read(ticketsViewModelProvider.notifier);
    await model.load();
    await model.loadMore();
    final state = container.read(ticketsViewModelProvider);
    expect(state.items.map((item) => item.id), ['a', 'b', 'c']);
    expect(state.hasMore, false);
  });

  test('atualização falha sem apagar ingressos já mostrados', () async {
    var calls = 0;
    when(() => repository.list(page: 1)).thenAnswer((_) async {
      calls++;
      if (calls == 2) throw Exception('offline');
      return page([ticket('a')], 1, 1);
    });
    final model = container.read(ticketsViewModelProvider.notifier);
    await model.load();
    await model.refresh();
    final state = container.read(ticketsViewModelProvider);
    expect(state.items.single.id, 'a');
    expect(state.refreshError, isNotNull);
  });

  test('resposta antiga não substitui atualização recente', () async {
    final old = Completer<TicketPage>();
    var calls = 0;
    when(() => repository.list(page: 1)).thenAnswer((_) {
      calls++;
      return calls == 1
          ? old.future
          : Future.value(page([ticket('new')], 1, 1));
    });
    final model = container.read(ticketsViewModelProvider.notifier);
    final pending = model.load();
    await model.refresh();
    old.complete(page([ticket('old')], 1, 1));
    await pending;
    expect(container.read(ticketsViewModelProvider).items.single.id, 'new');
  });

  testWidgets('exibe ingresso e estado vazio com dados da API', (tester) async {
    when(() => repository.list(page: 1))
        .thenAnswer((_) async => page([ticket('a')], 1, 1));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [ticketsRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: Scaffold(body: TicketsPage())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Festival'), findsOneWidget);
    expect(find.text('Inteira'), findsOneWidget);
    expect(find.text('Disponível'), findsOneWidget);
    expect(find.text('Meus ingressos'), findsNothing);
    expect(find.text('Seus ingressos ficam reunidos aqui.'), findsNothing);

    when(() => repository.list(page: 1))
        .thenAnswer((_) async => page([], 1, 1));
    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, 300),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nenhum ingresso ainda'), findsOneWidget);
  });

  testWidgets('detalhes preservam o ingresso se o evento falhar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final eventsRepository = MockEventsRepository();
    when(() => repository.list(page: 1))
        .thenAnswer((_) async => page([ticket('a')], 1, 1));
    when(() => eventsRepository.detail('event-1'))
        .thenAnswer((_) async => throw Exception('offline'));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ticketsRepositoryProvider.overrideWithValue(repository),
          eventsRepositoryProvider.overrideWithValue(eventsRepository),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(body: TicketsPage()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Festival'));
    await tester.pumpAndSettle();
    expect(find.text('Data e local indisponíveis.'), findsOneWidget);
    expect(find.text('Identificador do ingresso'), findsOneWidget);
  });

  testWidgets('ação do card abre a tela dedicada do QR', (tester) async {
    final item = ticket('a');
    when(() => repository.list(page: 1))
        .thenAnswer((_) async => page([item], 1, 1));
    when(() => repository.refreshTicket(item)).thenAnswer((_) async => item);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [ticketsRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: Scaffold(body: TicketsPage())),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver QR Code'));
    await tester.pumpAndSettle();
    expect(find.text('Seu ingresso'), findsOneWidget);
    expect(
      find.text('Código indisponível. Atualize para tentar novamente.'),
      findsOneWidget,
    );
  });
}
