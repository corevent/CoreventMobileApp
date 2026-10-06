import 'dart:async';

import 'package:corevent_mobile_app/features/profile/data/activity_dtos.dart';
import 'package:corevent_mobile_app/features/profile/data/activity_repository.dart';
import 'package:corevent_mobile_app/features/profile/presentation/activity_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockActivityRepository extends Mock implements ActivityRepository {}

BuyerOrder order(String id) => BuyerOrder(
  id,
  OrderEvent('event-$id', 'Evento $id', DateTime(2026, 10, 10)),
  25,
  'pending',
  DateTime(2026, 9, 30),
);

OrderPage page(List<BuyerOrder> items, int current, int total) =>
    OrderPage(items, ActivityMeta(current, total));

void main() {
  late MockActivityRepository repository;
  late ProviderContainer container;
  late ActivityViewModel model;

  setUp(() {
    repository = MockActivityRepository();
    container = ProviderContainer(
      overrides: [activityRepositoryProvider.overrideWithValue(repository)],
    );
    model = container.read(ordersViewModelProvider.notifier);
  });

  tearDown(() => container.dispose());

  test(
    'paginação remove pedidos repetidos e preserva ordem recebida',
    () async {
      when(() => repository.orders(1))
          .thenAnswer((_) async => page([order('1')], 1, 2));
      when(() => repository.orders(2))
          .thenAnswer((_) async => page([order('1'), order('2')], 2, 2));

      await model.load();
      expect(container.read(ordersViewModelProvider).hasMore, true);
      await model.loadMore();
      final state = container.read(ordersViewModelProvider);
      expect(state.items.cast<BuyerOrder>().map((item) => item.id), ['1', '2']);
      expect(state.hasMore, false);
      verify(() => repository.orders(2)).called(1);
    },
  );

  test('falha ao carregar mais conserva itens e permite repetir', () async {
    when(() => repository.orders(1))
        .thenAnswer((_) async => page([order('1')], 1, 2));
    var attempts = 0;
    when(() => repository.orders(2)).thenAnswer((_) async {
      if (++attempts == 1) throw Exception('offline');
      return page([order('2')], 2, 2);
    });

    await model.load();
    await model.loadMore();
    expect(container.read(ordersViewModelProvider).items.length, 1);
    expect(
      container.read(ordersViewModelProvider).error,
      contains('mais itens'),
    );
    await model.loadMore();
    expect(container.read(ordersViewModelProvider).items.length, 2);
    expect(container.read(ordersViewModelProvider).error, isNull);
  });

  test('falha de atualização conserva pedidos já carregados', () async {
    var attempts = 0;
    when(() => repository.orders(1)).thenAnswer((_) async {
      if (++attempts == 2) throw Exception('offline');
      return page([order('1')], 1, 1);
    });

    await model.load();
    await model.load();
    final state = container.read(ordersViewModelProvider);
    expect(state.items.cast<BuyerOrder>().single.id, '1');
    expect(state.error, isNotNull);
    expect(state.loading, false);
  });

  test('resposta antiga de paginação não substitui nova atualização', () async {
    final pendingPage = Completer<OrderPage>();
    var firstPageCalls = 0;
    when(() => repository.orders(1)).thenAnswer((_) async {
      firstPageCalls++;
      return page([order(firstPageCalls == 1 ? 'old' : 'new')], 1, 2);
    });
    when(() => repository.orders(2)).thenAnswer((_) => pendingPage.future);

    await model.load();
    final more = model.loadMore();
    await model.load();
    pendingPage.complete(page([order('late')], 2, 2));
    await more;
    final state = container.read(ordersViewModelProvider);
    expect(state.items.cast<BuyerOrder>().map((item) => item.id), ['new']);
    expect(state.page, 1);
  });
}
