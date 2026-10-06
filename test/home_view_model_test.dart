import 'dart:async';

import 'package:corevent_mobile_app/features/auth/data/auth_dtos.dart';
import 'package:corevent_mobile_app/features/auth/presentation/auth_session.dart';
import 'package:corevent_mobile_app/features/events/data/event_dtos.dart';
import 'package:corevent_mobile_app/features/events/data/events_repository.dart';
import 'package:corevent_mobile_app/features/events/domain/event_discovery_filter.dart';
import 'package:corevent_mobile_app/features/explore/presentation/explore_view_model.dart';
import 'package:corevent_mobile_app/features/home/presentation/home_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockEventsRepository extends Mock implements EventsRepository {}

class MockSession extends Mock implements AuthSession {}

const organizer = EventOrganizer(name: 'Org');

EventSummary item(String id, {bool adult = false, String? mode}) =>
    EventSummary(
      id: id,
      title: id,
      startDate: DateTime.now().add(const Duration(days: 2)),
      endDate: DateTime.now().add(const Duration(days: 2, hours: 2)),
      category: 'music',
      locationType: mode,
      isAdultOnly: adult,
      locationName: 'Arena',
      organizer: organizer,
    );

EventPage page(List<EventSummary> items, int number, int total) => EventPage(
  data: items,
  meta: EventPageMeta(page: number, totalPages: total),
);

void main() {
  late MockEventsRepository repository;
  late MockSession session;
  late ProviderContainer container;

  setUp(() {
    repository = MockEventsRepository();
    session = MockSession();
    when(() => session.user).thenReturn(
      const UserProfile(
        id: '1',
        name: 'Ana',
        email: 'ana@corevent.com',
        birthDate: '2000-01-01',
      ),
    );
    container = ProviderContainer(
      overrides: [
        eventsRepositoryProvider.overrideWithValue(repository),
        authSessionProvider.overrideWithValue(session),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('carrega, pagina e remove repetidos', () async {
    when(
      () => repository.list(page: 1, limit: 50, search: null, category: null),
    ).thenAnswer((_) async => page([item('b'), item('a')], 1, 2));
    when(
      () => repository.list(page: 2, limit: 50, search: null, category: null),
    ).thenAnswer((_) async => page([item('a'), item('c')], 2, 2));
    final vm = container.read(homeViewModelProvider.notifier);
    await vm.load();
    expect(container.read(homeViewModelProvider).events.length, 2);
    expect(container.read(homeViewModelProvider).hasMore, true);
    await vm.loadMore();
    final state = container.read(homeViewModelProvider);
    expect(state.events.map((event) => event.id).toSet(), {'a', 'b', 'c'});
    expect(state.hasMore, false);
  });

  test('resposta antiga de busca não substitui a busca nova', () async {
    final oldResult = Completer<EventPage>();
    final newResult = Completer<EventPage>();
    when(
      () =>
          repository.list(page: 1, limit: 10, search: 'antiga', category: null),
    ).thenAnswer((_) => oldResult.future);
    when(
      () => repository.list(page: 1, limit: 10, search: 'nova', category: null),
    ).thenAnswer((_) => newResult.future);
    final vm = container.read(exploreViewModelProvider.notifier);
    vm.setSearch('antiga');
    vm.submitSearch();
    vm.setSearch('nova');
    vm.submitSearch();
    newResult.complete(page([item('nova')], 1, 1));
    await Future<void>.delayed(Duration.zero);
    oldResult.complete(page([item('antiga')], 1, 1));
    await Future<void>.delayed(Duration.zero);
    expect(container.read(exploreViewModelProvider).events.single.id, 'nova');
  });

  test('mantém os eventos quando a atualização falha', () async {
    var calls = 0;
    when(
      () => repository.list(page: 1, limit: 50, search: null, category: null),
    ).thenAnswer((_) async {
      calls++;
      if (calls == 2) throw Exception('offline');
      return page([item('visível')], 1, 1);
    });
    final vm = container.read(homeViewModelProvider.notifier);
    await vm.load();
    await vm.refresh();
    final state = container.read(homeViewModelProvider);
    expect(state.events.single.id, 'visível');
    expect(state.refreshError, isNotNull);
    expect(state.refreshing, false);
  });

  test('falha ao carregar mais preserva a página anterior', () async {
    when(
      () => repository.list(page: 1, limit: 50, search: null, category: null),
    ).thenAnswer((_) async => page([item('primeiro')], 1, 2));
    when(
      () => repository.list(page: 2, limit: 50, search: null, category: null),
    ).thenThrow(Exception('offline'));
    final vm = container.read(homeViewModelProvider.notifier);
    await vm.load();
    await vm.loadMore();
    final state = container.read(homeViewModelProvider);
    expect(state.events.single.id, 'primeiro');
    expect(state.page, 1);
    expect(state.loadMoreError, isNotNull);
    expect(state.hasMore, true);
  });

  test('atualização descarta uma página antiga ainda em andamento', () async {
    var firstPageCalls = 0;
    final oldPage = Completer<EventPage>();
    when(
      () => repository.list(page: 1, limit: 50, search: null, category: null),
    ).thenAnswer((_) async {
      firstPageCalls++;
      return firstPageCalls == 1
          ? page([item('anterior')], 1, 2)
          : page([item('atualizado')], 1, 1);
    });
    when(
      () => repository.list(page: 2, limit: 50, search: null, category: null),
    ).thenAnswer((_) => oldPage.future);
    final vm = container.read(homeViewModelProvider.notifier);
    await vm.load();
    final pending = vm.loadMore();
    await vm.refresh();
    oldPage.complete(page([item('obsoleto')], 2, 2));
    await pending;
    final state = container.read(homeViewModelProvider);
    expect(state.events.single.id, 'atualizado');
    expect(state.loadingMore, false);
    expect(state.hasMore, false);
  });

  test('quando a idade é desconhecida oculta eventos +18', () async {
    when(() => session.user).thenReturn(
      const UserProfile(id: '1', name: 'Ana', email: 'ana@corevent.com'),
    );
    when(
      () => repository.list(page: 1, limit: 50, search: null, category: null),
    ).thenAnswer(
      (_) async => page([item('livre'), item('adulto', adult: true)], 1, 1),
    );
    final vm = container.read(homeViewModelProvider.notifier);
    await vm.load();
    expect(container.read(homeViewModelProvider).events.single.id, 'livre');
  });

  test(
    'atalho aplica categoria, datas e modalidade juntos em uma consulta',
    () async {
      when(
        () => repository.list(
          page: 1,
          limit: 10,
          search: null,
          category: 'music',
        ),
      ).thenAnswer(
        (_) async =>
            page([item('online', mode: 'online'), item('presencial')], 1, 1),
      );
      final now = DateTime.now();
      final filter = EventDiscoveryFilter(
        category: 'music',
        locationType: 'online',
        from: now,
        until: now.add(const Duration(days: 7)),
      );
      container.read(exploreViewModelProvider.notifier).applyDiscovery(filter);
      await Future<void>.delayed(Duration.zero);
      final state = container.read(exploreViewModelProvider);
      expect(state.discovery, filter);
      expect(state.events.single.id, 'online');
      verify(
        () => repository.list(
          page: 1,
          limit: 10,
          search: null,
          category: 'music',
        ),
      ).called(1);
      verifyNever(
        () => repository.list(page: 1, limit: 10, search: null, category: null),
      );
    },
  );

  test(
    'filtro online atravessa páginas vazias e pagina sem duplicar',
    () async {
      for (final number in [1, 2]) {
        when(
          () => repository.list(
            page: number,
            limit: 10,
            search: null,
            category: null,
          ),
        ).thenAnswer(
          (_) async => page([item('presencial-$number')], number, 4),
        );
      }
      when(
        () => repository.list(page: 3, limit: 10, search: null, category: null),
      ).thenAnswer((_) async => page([item('online', mode: 'online')], 3, 4));
      when(
        () => repository.list(page: 4, limit: 10, search: null, category: null),
      ).thenAnswer(
        (_) async => page(
          [item('online', mode: 'online'), item('outro', mode: 'online')],
          4,
          4,
        ),
      );
      final vm = container.read(exploreViewModelProvider.notifier);
      vm.applyDiscovery(const EventDiscoveryFilter(locationType: 'online'));
      await Future<void>.delayed(Duration.zero);
      expect(container.read(exploreViewModelProvider).page, 3);
      expect(
        container.read(exploreViewModelProvider).events.single.id,
        'online',
      );
      await vm.loadMore();
      expect(container.read(exploreViewModelProvider).events.map((e) => e.id), [
        'online',
        'outro',
      ]);
      expect(container.read(exploreViewModelProvider).hasMore, false);
    },
  );

  test(
    'limita consultas sem resultados e mantém possibilidade de continuar',
    () async {
      for (final number in [1, 2, 3]) {
        when(
          () => repository.list(
            page: number,
            limit: 10,
            search: null,
            category: null,
          ),
        ).thenAnswer((_) async => page([item('$number')], number, 10));
      }
      container
          .read(exploreViewModelProvider.notifier)
          .applyDiscovery(const EventDiscoveryFilter(locationType: 'online'));
      await Future<void>.delayed(Duration.zero);
      final state = container.read(exploreViewModelProvider);
      expect(state.events, isEmpty);
      expect(state.page, 3);
      expect(state.hasMore, true);
      expect(state.loading, false);
      verifyNever(
        () => repository.list(page: 4, limit: 10, search: null, category: null),
      );
    },
  );
}
