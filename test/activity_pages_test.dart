import 'package:corevent_mobile_app/features/profile/data/activity_dtos.dart';
import 'package:corevent_mobile_app/features/profile/data/activity_repository.dart';
import 'package:corevent_mobile_app/features/profile/presentation/activity_pages.dart';
import 'package:corevent_mobile_app/features/profile/presentation/activity_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

class MockActivityRepository extends Mock implements ActivityRepository {}

BuyerOrder order() => BuyerOrder(
  'o1',
  OrderEvent('e1', 'Festival de música', DateTime(2026, 10, 10)),
  25,
  'pending',
  DateTime(2026, 9, 30),
);

OrderDetails detail() => OrderDetails(
  'o1',
  OrderEvent('e1', 'Festival de música', DateTime(2026, 10, 10)),
  25,
  'pending',
  DateTime(2026, 9, 30),
  [const OrderTicket('t1', 'available', OrderTicketType('Inteira', 25))],
  null,
);

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));
  late MockActivityRepository repository;
  late GoRouter router;

  setUp(() {
    repository = MockActivityRepository();
    router = GoRouter(
      initialLocation: '/profile/orders',
      routes: [
        GoRoute(
          path: '/profile/orders',
          builder: (_, _) => const ActivityPage(kind: ActivityKind.orders),
        ),
        GoRoute(
          path: '/profile/orders/:id',
          builder: (_, state) =>
              OrderDetailPage(id: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/orders/:id/status',
          builder: (_, _) => const Scaffold(body: Text('Status do pedido')),
        ),
      ],
    );
  });

  tearDown(() => router.dispose());

  Future<void> show(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [activityRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('pedidos vazios mostram orientação sem títulos redundantes', (
    tester,
  ) async {
    when(() => repository.orders(1))
        .thenAnswer((_) async => const OrderPage([], ActivityMeta(1, 1)));
    await show(tester);
    expect(find.text('Você ainda não fez pedidos.'), findsOneWidget);
    expect(find.text('Carregar mais'), findsNothing);
  });

  testWidgets('erro inicial oferece nova tentativa e recupera a lista', (
    tester,
  ) async {
    var calls = 0;
    when(() => repository.orders(1)).thenAnswer((_) async {
      if (++calls == 1) throw Exception('offline');
      return OrderPage([order()], const ActivityMeta(1, 1));
    });
    await show(tester);
    expect(find.text('Não foi possível carregar os dados.'), findsOneWidget);
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('Festival de música'), findsOneWidget);
    verify(() => repository.orders(1)).called(2);
  });

  testWidgets('pedido abre detalhes e mostra seus ingressos', (tester) async {
    when(
      () => repository.orders(1),
    ).thenAnswer((_) async => OrderPage([order()], const ActivityMeta(1, 1)));
    when(() => repository.order('o1')).thenAnswer((_) async => detail());
    await show(tester);
    await tester.tap(find.text('Festival de música'));
    await tester.pumpAndSettle();
    expect(find.text('Detalhes do pedido'), findsOneWidget);
    expect(find.text('Status: Aguardando pagamento'), findsOneWidget);
    expect(find.text('Inteira'), findsOneWidget);
    expect(find.text('Acompanhar pagamento'), findsOneWidget);
  });

  testWidgets('detalhe com erro permite tentar novamente', (tester) async {
    when(
      () => repository.orders(1),
    ).thenAnswer((_) async => OrderPage([order()], const ActivityMeta(1, 1)));
    var calls = 0;
    when(() => repository.order('o1')).thenAnswer((_) async {
      if (++calls == 1) throw Exception('offline');
      return detail();
    });
    await show(tester);
    await tester.tap(find.text('Festival de música'));
    await tester.pumpAndSettle();
    expect(find.text('Não foi possível carregar o pedido.'), findsOneWidget);
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('Inteira'), findsOneWidget);
    verify(() => repository.order('o1')).called(2);
  });
}
