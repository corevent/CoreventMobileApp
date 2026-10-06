import 'package:corevent_mobile_app/features/auth/data/auth_dtos.dart';
import 'package:corevent_mobile_app/features/auth/presentation/auth_session.dart';
import 'package:corevent_mobile_app/features/checkout/data/checkout_dtos.dart';
import 'package:corevent_mobile_app/features/checkout/data/checkout_repository.dart';
import 'package:corevent_mobile_app/features/checkout/presentation/checkout_view_model.dart';
import 'package:corevent_mobile_app/features/events/data/event_dtos.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCheckoutRepository extends Mock implements CheckoutRepository {}

class MockPendingStore extends Mock implements PendingCheckoutStore {}

class MockSession extends Mock implements AuthSession {}

void main() {
  late MockCheckoutRepository repository;
  late MockPendingStore store;
  late ProviderContainer container;
  late CheckoutCatalog catalog;

  setUp(() {
    repository = MockCheckoutRepository();
    store = MockPendingStore();
    final session = MockSession();
    when(() => session.user).thenReturn(
      const UserProfile(
        id: 'u1',
        name: 'Ana',
        email: 'ana@example.com',
        birthDate: '2000-01-01',
      ),
    );
    final now = DateTime.now();
    catalog = CheckoutCatalog(
      EventDetail(
        id: 'e1',
        title: 'Festival',
        startDate: now.add(const Duration(days: 2)),
        endDate: now.add(const Duration(days: 2, hours: 2)),
        category: 'music',
        isAdultOnly: false,
        locationName: 'Arena',
        organizer: const EventOrganizer(name: 'Org'),
        status: 'opened',
      ),
      [
        CheckoutTicketType(
          id: 'paid',
          name: 'Inteira',
          price: 25,
          availableQuantity: 3,
          startDate: now.subtract(const Duration(days: 1)),
          endDate: now.add(const Duration(days: 1)),
        ),
        CheckoutTicketType(
          id: 'free',
          name: 'Cortesia',
          price: 0,
          availableQuantity: 5,
          startDate: now.subtract(const Duration(days: 1)),
          endDate: now.add(const Duration(days: 1)),
        ),
      ],
    );
    when(() => repository.catalog('e1')).thenAnswer((_) async => catalog);
    when(() => store.save('u1', any())).thenAnswer((_) async {});
    container = ProviderContainer(
      overrides: [
        checkoutRepositoryProvider.overrideWithValue(repository),
        pendingCheckoutStoreProvider.overrideWithValue(store),
        authSessionProvider.overrideWithValue(session),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('limita quantidade e separa ingressos pagos dos gratuitos', () async {
    final vm = container.read(checkoutViewModelProvider.notifier);
    await vm.load('e1');
    vm.setQuantity(catalog.types.first, 99);
    expect(container.read(checkoutViewModelProvider).quantity('paid'), 3);
    vm.setQuantity(catalog.types.last, 2);
    final state = container.read(checkoutViewModelProvider);
    expect(state.quantity('paid'), 0);
    expect(state.quantity('free'), 1);
    expect(state.total, 0);
  });

  test('cria o pedido apenas uma vez e guarda a referência', () async {
    final vm = container.read(checkoutViewModelProvider.notifier);
    await vm.load('e1');
    vm.setQuantity(catalog.types.first, 2);
    when(() => repository.create('e1', {'paid': 2}))
        .thenAnswer((_) async => const CreatedOrder('o1', [], []));
    await vm.submit();
    await vm.submit();
    expect(container.read(checkoutViewModelProvider).order?.orderId, 'o1');
    verify(() => repository.create('e1', {'paid': 2})).called(1);
    verify(() => store.save('u1', 'o1')).called(1);
  });

  test('não cria pedido quando o estoque muda', () async {
    final vm = container.read(checkoutViewModelProvider.notifier);
    await vm.load('e1');
    vm.setQuantity(catalog.types.first, 2);
    final changed = CheckoutCatalog(catalog.event, [
      CheckoutTicketType(
        id: 'paid',
        name: 'Inteira',
        price: 25,
        availableQuantity: 1,
        startDate: catalog.types.first.startDate,
        endDate: catalog.types.first.endDate,
      ),
    ]);
    when(() => repository.catalog('e1')).thenAnswer((_) async => changed);
    await vm.submit();
    expect(
      container.read(checkoutViewModelProvider).error,
      contains('disponibilidade'),
    );
    verifyNever(() => repository.create(any(), any()));
  });

  test('não oferece compra para evento encerrado', () async {
    catalog = CheckoutCatalog(
      EventDetail(
        id: 'e1',
        title: 'Festival',
        startDate: DateTime.now().subtract(const Duration(days: 2)),
        endDate: DateTime.now().subtract(const Duration(days: 1)),
        category: 'music',
        isAdultOnly: false,
        locationName: 'Arena',
        organizer: const EventOrganizer(name: 'Org'),
        status: 'finished',
      ),
      catalog.types,
    );
    await container.read(checkoutViewModelProvider.notifier).load('e1');
    final state = container.read(checkoutViewModelProvider);
    expect(state.types, isEmpty);
    expect(state.error, contains('disponível'));
  });

  test('pede aceite etário antes de criar pedido de evento +18', () async {
    catalog = CheckoutCatalog(
      EventDetail(
        id: 'e1',
        title: 'Festival',
        startDate: catalog.event.startDate,
        endDate: catalog.event.endDate,
        category: 'music',
        isAdultOnly: true,
        locationName: 'Arena',
        organizer: const EventOrganizer(name: 'Org'),
        status: 'opened',
      ),
      catalog.types,
    );
    final vm = container.read(checkoutViewModelProvider.notifier);
    await vm.load('e1');
    vm.setQuantity(catalog.types.first, 1);
    when(
      () => repository.requiredAgePolicy(),
    ).thenAnswer((_) async => const AgePolicy('policy', 'Termos de idade', 1));
    when(() => repository.acceptAgePolicy()).thenAnswer((_) async {});
    when(() => repository.create('e1', {'paid': 1}))
        .thenAnswer((_) async => const CreatedOrder('o2', [], []));
    final policy = await vm.submit();
    expect(policy?.description, 'Termos de idade');
    verifyNever(() => repository.create(any(), any()));
    await vm.acceptAndSubmit();
    expect(container.read(checkoutViewModelProvider).order?.orderId, 'o2');
    verify(() => repository.acceptAgePolicy()).called(1);
  });

  test(
    'timeout de criação mantém resultado incerto sem repetir POST',
    () async {
      final vm = container.read(checkoutViewModelProvider.notifier);
      await vm.load('e1');
      vm.setQuantity(catalog.types.first, 1);
      when(() => repository.create('e1', {'paid': 1})).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/orders'),
          type: DioExceptionType.receiveTimeout,
        ),
      );
      await vm.submit();
      await vm.submit();
      expect(container.read(checkoutViewModelProvider).uncertain, true);
      verify(() => repository.create('e1', {'paid': 1})).called(1);
    },
  );
}
