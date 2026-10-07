import 'dart:async';

import 'package:corevent_mobile_app/features/events/data/event_dtos.dart';
import 'package:corevent_mobile_app/features/favorites/data/favorites_api.dart';
import 'package:corevent_mobile_app/features/favorites/data/favorites_repository.dart';
import 'package:corevent_mobile_app/features/favorites/presentation/favorites_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRepository extends Mock implements FavoritesRepository {}

class MockApi extends Mock implements FavoritesApi {}

EventSummary favorite(String id) => EventSummary(
  id: id,
  favoriteId: 'f$id',
  title: id,
  startDate: DateTime(2026, 10, 1),
  endDate: DateTime(2026, 10, 2),
  category: 'music',
  isAdultOnly: false,
  locationName: 'Arena',
  organizer: const EventOrganizer(name: 'Org'),
);
EventPage page(List<EventSummary> items, {int number = 1, int total = 1}) =>
    EventPage(
      data: items,
      meta: EventPageMeta(page: number, totalPages: total),
    );

void main() {
  late MockRepository repository;
  late ProviderContainer container;
  late FavoritesViewModel model;
  setUp(() {
    repository = MockRepository();
    container = ProviderContainer(
      overrides: [favoritesRepositoryProvider.overrideWithValue(repository)],
    );
    model = container.read(favoritesViewModelProvider.notifier);
  });
  tearDown(() => container.dispose());

  test('repositório usa filtro, paginação e id do favorito', () async {
    final api = MockApi();
    final result = page([favorite('1')]);
    when(() => api.list(2, 20, 'finished')).thenAnswer((_) async => result);
    when(() => api.remove('f1')).thenAnswer((_) async {});
    final repo = FavoritesRepository(api);
    expect(await repo.list(2, 'finished'), same(result));
    await repo.remove('f1');
    verify(() => api.list(2, 20, 'finished')).called(1);
    verify(() => api.remove('f1')).called(1);
  });

  test(
    'trocas rápidas descartam respostas e erros do filtro anterior',
    () async {
      final opened = Completer<EventPage>();
      final going = Completer<EventPage>();
      final finished = Completer<EventPage>();
      when(() => repository.list(1, 'opened')).thenAnswer((_) => opened.future);
      when(() => repository.list(1, 'going')).thenAnswer((_) => going.future);
      when(() => repository.list(1, 'finished'))
          .thenAnswer((_) => finished.future);
      final load = model.load();
      model.selectStatus(FavoriteStatus.going);
      model.selectStatus(FavoriteStatus.finished);
      finished.complete(page([favorite('finished')]));
      await Future<void>.delayed(Duration.zero);
      opened.complete(page([favorite('old')]));
      going.completeError(Exception('old failure'));
      await load;
      await Future<void>.delayed(Duration.zero);
      final state = container.read(favoritesViewModelProvider);
      expect(state.status, FavoriteStatus.finished);
      expect(state.events.single.id, 'finished');
      expect(state.error, isNull);
      expect(state.loading, false);
    },
  );

  test('paginação deduplica e falha permite nova tentativa', () async {
    when(
      () => repository.list(1, 'opened'),
    ).thenAnswer((_) async => page([favorite('1'), favorite('1')], total: 2));
    var attempts = 0;
    when(() => repository.list(2, 'opened')).thenAnswer((_) async {
      if (++attempts == 1) throw Exception('offline');
      return page([favorite('1'), favorite('2')], number: 2, total: 2);
    });
    await model.load();
    expect(container.read(favoritesViewModelProvider).events.length, 1);
    await model.loadMore();
    expect(container.read(favoritesViewModelProvider).loadMoreError, isNotNull);
    expect(container.read(favoritesViewModelProvider).page, 1);
    await model.loadMore();
    final state = container.read(favoritesViewModelProvider);
    expect(state.events.map((e) => e.id), ['1', '2']);
    expect(state.loadMoreError, isNull);
    expect(state.hasMore, false);
  });

  test(
    'atualização mantém cards e separa erro de carregamento inicial',
    () async {
      when(() => repository.list(1, 'opened'))
          .thenAnswer((_) async => page([favorite('1')]));
      await model.load();
      final response = Completer<EventPage>();
      when(() => repository.list(1, 'opened'))
          .thenAnswer((_) => response.future);
      final refresh = model.refresh();
      expect(container.read(favoritesViewModelProvider).events.single.id, '1');
      expect(container.read(favoritesViewModelProvider).refreshing, true);
      response.completeError(Exception('offline'));
      expect(await refresh, isNotNull);
      final state = container.read(favoritesViewModelProvider);
      expect(state.events.single.id, '1');
      expect(state.refreshError, isNotNull);
      expect(state.error, isNull);
    },
  );

  test('remoção bloqueia repetição e falha mantém evento', () async {
    final event = favorite('1');
    when(() => repository.list(1, 'opened'))
        .thenAnswer((_) async => page([event]));
    await model.load();
    final response = Completer<void>();
    when(() => repository.remove('f1')).thenAnswer((_) => response.future);
    final remove = model.remove(event);
    expect(container.read(favoritesViewModelProvider).removingIds, {'f1'});
    expect(await model.remove(event), false);
    response.completeError(Exception('offline'));
    expect(await remove, false);
    expect(container.read(favoritesViewModelProvider).events.single.id, '1');
    expect(container.read(favoritesViewModelProvider).removingIds, isEmpty);
    verify(() => repository.remove('f1')).called(1);
  });

  test('refresh iniciado antes da remoção não restaura o favorito', () async {
    final event = favorite('1');
    when(() => repository.list(1, 'opened'))
        .thenAnswer((_) async => page([event, favorite('2')]));
    when(() => repository.remove('f1')).thenAnswer((_) async {});
    await model.load();
    final response = Completer<EventPage>();
    when(() => repository.list(1, 'opened')).thenAnswer((_) => response.future);
    final refresh = model.refresh();
    await model.remove(event);
    expect(container.read(favoritesViewModelProvider).refreshing, true);
    response.complete(page([event, favorite('2')]));
    await refresh;
    expect(container.read(favoritesViewModelProvider).events.map((e) => e.id), [
      '2',
    ]);
  });

  test(
    'remoção do filtro anterior preserva resultado do filtro atual',
    () async {
      final event = favorite('1');
      when(() => repository.list(1, 'opened'))
          .thenAnswer((_) async => page([event]));
      when(() => repository.list(1, 'finished'))
          .thenAnswer((_) async => page([favorite('2')]));
      final response = Completer<void>();
      when(() => repository.remove('f1')).thenAnswer((_) => response.future);
      await model.load();
      final removal = model.remove(event);
      model.selectStatus(FavoriteStatus.finished);
      await Future<void>.delayed(Duration.zero);
      response.complete();
      await removal;
      final state = container.read(favoritesViewModelProvider);
      expect(state.status, FavoriteStatus.finished);
      expect(state.events.single.id, '2');
    },
  );

  test(
    'após remoção paginação recompõe páginas para não pular eventos',
    () async {
      when(
        () => repository.list(1, 'opened'),
      ).thenAnswer((_) async => page([favorite('1'), favorite('2')], total: 3));
      when(() => repository.remove('f1')).thenAnswer((_) async {});
      await model.load();
      await model.remove(favorite('1'));
      when(
        () => repository.list(1, 'opened'),
      ).thenAnswer((_) async => page([favorite('2'), favorite('3')], total: 2));
      when(() => repository.list(2, 'opened'))
          .thenAnswer((_) async => page([favorite('4')], number: 2, total: 2));
      await model.loadMore();
      final state = container.read(favoritesViewModelProvider);
      expect(state.events.map((e) => e.id), ['2', '3', '4']);
      expect(state.hasMore, false);
      verify(() => repository.list(1, 'opened')).called(2);
    },
  );
}
