import 'dart:async';

import 'package:corevent_mobile_app/features/events/data/event_dtos.dart';
import 'package:corevent_mobile_app/features/favorites/data/favorites_repository.dart';
import 'package:corevent_mobile_app/features/favorites/presentation/event_favorites_view_model.dart';
import 'package:corevent_mobile_app/features/favorites/presentation/favorites_view_model.dart';
import 'package:corevent_mobile_app/features/ratings/data/rating_dtos.dart';
import 'package:corevent_mobile_app/features/ratings/data/ratings_repository.dart';
import 'package:corevent_mobile_app/features/ratings/presentation/event_ratings_view_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFavorites extends Mock implements FavoritesRepository {}

class MockRatings extends Mock implements RatingsRepository {}

EventSummary event(String id) => EventSummary(
  id: id,
  favoriteId: 'f$id',
  title: id,
  startDate: DateTime(2026, 10),
  endDate: DateTime(2026, 11),
  category: 'music',
  isAdultOnly: false,
  locationName: 'Arena',
  organizer: const EventOrganizer(name: 'Org'),
);
EventPage favorites(List<EventSummary> events, {int total = 1}) => EventPage(
  data: events,
  meta: EventPageMeta(page: 1, totalPages: total),
);
RatedEvent rated(String id, {int score = 4, String? ratingId}) => RatedEvent(
  eventId: id,
  eventTitle: 'Festival $id',
  userRating: score,
  ratingId: ratingId,
);
RatedEventPage ratings(List<RatedEvent> events, {int total = 1}) =>
    RatedEventPage(events, RatingPageMeta(1, total));
DioException httpError(int status) => DioException(
  requestOptions: RequestOptions(),
  response: Response(requestOptions: RequestOptions(), statusCode: status),
);

void main() {
  late MockFavorites favoriteRepo;
  late MockRatings ratingRepo;
  late ProviderContainer container;
  setUp(() {
    favoriteRepo = MockFavorites();
    ratingRepo = MockRatings();
    when(() => favoriteRepo.list(any(), any()))
        .thenAnswer((_) async => favorites([]));
    when(() => ratingRepo.list(any())).thenAnswer((_) async => ratings([]));
    container = ProviderContainer(
      overrides: [
        favoritesRepositoryProvider.overrideWithValue(favoriteRepo),
        ratingsRepositoryProvider.overrideWithValue(ratingRepo),
      ],
    );
  });
  tearDown(() => container.dispose());

  test(
    'favoritos desconhecidos até concluir todas as páginas e estados',
    () async {
      final last = Completer<EventPage>();
      when(() => favoriteRepo.list(1, 'opened'))
          .thenAnswer((_) async => favorites([event('1')], total: 2));
      when(() => favoriteRepo.list(2, 'opened'))
          .thenAnswer((_) async => favorites([event('2')]));
      when(() => favoriteRepo.list(1, 'finished'))
          .thenAnswer((_) => last.future);
      final model = container.read(eventFavoritesViewModelProvider.notifier);
      final request = model.load();
      await Future<void>.delayed(Duration.zero);
      expect(container.read(eventFavoritesViewModelProvider).known('3'), false);
      last.complete(favorites([event('3')]));
      await request;
      expect(container.read(eventFavoritesViewModelProvider).ids, {
        '1': 'f1',
        '2': 'f2',
        '3': 'f3',
      });
      expect(container.read(eventFavoritesViewModelProvider).known('4'), true);
    },
  );

  test(
    'falha de consulta não transforma estado desconhecido em não favorito',
    () async {
      when(() => favoriteRepo.list(1, 'going')).thenThrow(Exception('offline'));
      final model = container.read(eventFavoritesViewModelProvider.notifier);
      expect(await model.toggle('1'), isNotNull);
      expect(container.read(eventFavoritesViewModelProvider).loaded, false);
      verifyNever(() => favoriteRepo.create(any()));
    },
  );

  test('favoritar só confirma após API e ignora toque repetido', () async {
    final response = Completer<String>();
    when(() => favoriteRepo.create('1')).thenAnswer((_) => response.future);
    final model = container.read(eventFavoritesViewModelProvider.notifier);
    await model.load();
    final request = model.toggle('1');
    await model.toggle('1');
    expect(container.read(eventFavoritesViewModelProvider).busy, {'1'});
    expect(container.read(eventFavoritesViewModelProvider).ids, isEmpty);
    response.complete('f1');
    expect(await request, isNull);
    expect(container.read(eventFavoritesViewModelProvider).ids['1'], 'f1');
    verify(() => favoriteRepo.create('1')).called(1);
  });

  test('remover sincroniza lista e mantém estado em falha', () async {
    when(() => favoriteRepo.list(1, 'opened'))
        .thenAnswer((_) async => favorites([event('1')]));
    final list = container.read(favoritesViewModelProvider.notifier);
    await list.load();
    final model = container.read(eventFavoritesViewModelProvider.notifier);
    await model.load();
    when(() => favoriteRepo.remove('f1')).thenThrow(Exception('offline'));
    expect(await model.toggle('1'), isNotNull);
    expect(container.read(eventFavoritesViewModelProvider).ids['1'], 'f1');
    expect(container.read(favoritesViewModelProvider).events, hasLength(1));
    when(() => favoriteRepo.remove('f1')).thenAnswer((_) async {});
    expect(await model.toggle('1'), isNull);
    expect(container.read(eventFavoritesViewModelProvider).ids, isEmpty);
    expect(container.read(favoritesViewModelProvider).events, isEmpty);
  });

  test(
    'resposta antiga não desfaz favorito criado durante atualização',
    () async {
      final model = container.read(eventFavoritesViewModelProvider.notifier);
      await model.load();
      final refresh = Completer<EventPage>();
      when(() => favoriteRepo.list(1, 'opened'))
          .thenAnswer((_) => refresh.future);
      final request = model.load(refresh: true);
      when(() => favoriteRepo.create('1')).thenAnswer((_) async => 'f1');
      await model.toggle('1');
      refresh.complete(favorites([]));
      await request;
      expect(container.read(eventFavoritesViewModelProvider).ids['1'], 'f1');
    },
  );

  test('reconcilia favorito duplicado sem presumir sucesso', () async {
    final model = container.read(eventFavoritesViewModelProvider.notifier);
    await model.load();
    when(() => favoriteRepo.create('1')).thenThrow(httpError(400));
    when(() => favoriteRepo.list(1, 'opened'))
        .thenAnswer((_) async => favorites([event('1')]));
    expect(await model.toggle('1'), isNotNull);
    expect(container.read(eventFavoritesViewModelProvider).ids['1'], 'f1');
  });

  test(
    'consulta avaliações paginadas e mantém existente sem id só para leitura',
    () async {
      when(() => ratingRepo.list(1))
          .thenAnswer((_) async => ratings([rated('1')], total: 2));
      when(() => ratingRepo.list(2))
          .thenAnswer((_) async => ratings([rated('2')]));
      final model = container.read(eventRatingsViewModelProvider.notifier);
      await model.load();
      expect(
        container.read(eventRatingsViewModelProvider).events,
        hasLength(2),
      );
      expect(await model.save(rated('1'), 5), isNotNull);
      expect(await model.remove('1'), isNotNull);
      verifyNever(() => ratingRepo.save(any(), any(), id: any(named: 'id')));
    },
  );

  test('cria, altera e remove usando identificador recebido', () async {
    when(() => ratingRepo.save('1', 4, id: null))
        .thenAnswer((_) async => const RatingData('r1', '1', 4));
    when(() => ratingRepo.save('1', 5, id: 'r1'))
        .thenAnswer((_) async => const RatingData('r1', '1', 5));
    when(() => ratingRepo.remove('r1')).thenAnswer((_) async {});
    final model = container.read(eventRatingsViewModelProvider.notifier);
    expect(await model.save(rated('1'), 4), isNull);
    // A real list returns the created event but currently omits its rating ID.
    when(() => ratingRepo.list(1))
        .thenAnswer((_) async => ratings([rated('1')]));
    await model.load(refresh: true);
    expect(
      container.read(eventRatingsViewModelProvider).events['1']?.ratingId,
      'r1',
    );
    expect(await model.save(rated('1'), 5), isNull);
    expect(
      container.read(eventRatingsViewModelProvider).events['1']?.userRating,
      5,
    );
    expect(await model.remove('1'), isNull);
    expect(container.read(eventRatingsViewModelProvider).events, isEmpty);
  });

  test(
    'valida nota, impede envios simultâneos e preserva nota após falha',
    () async {
      final result = Completer<RatingData>();
      when(() => ratingRepo.save('1', 5, id: 'r1'))
          .thenAnswer((_) => result.future);
      when(() => ratingRepo.list(1))
          .thenAnswer((_) async => ratings([rated('1', ratingId: 'r1')]));
      final model = container.read(eventRatingsViewModelProvider.notifier);
      await model.load();
      expect(await model.save(rated('1'), 0), isNotNull);
      expect(await model.save(rated('1'), 6), isNotNull);
      final request = model.save(rated('1'), 5);
      expect(await model.save(rated('1'), 5), isNotNull);
      result.completeError(Exception('offline'));
      expect(await request, isNotNull);
      expect(
        container.read(eventRatingsViewModelProvider).events['1']?.userRating,
        4,
      );
      expect(container.read(eventRatingsViewModelProvider).busy, isEmpty);
      verify(() => ratingRepo.save('1', 5, id: 'r1')).called(1);
    },
  );

  test(
    'consulta em andamento é compartilhada antes de criar avaliação',
    () async {
      final result = Completer<RatedEventPage>();
      when(() => ratingRepo.list(1)).thenAnswer((_) => result.future);
      when(() => ratingRepo.save('1', 4, id: null))
          .thenAnswer((_) async => const RatingData('r1', '1', 4));
      final model = container.read(eventRatingsViewModelProvider.notifier);
      final loading = model.load();
      final saving = model.save(rated('1'), 4);
      verifyNever(() => ratingRepo.save(any(), any(), id: any(named: 'id')));
      result.complete(ratings([]));
      await loading;
      expect(await saving, isNull);
      verify(() => ratingRepo.list(1)).called(1);
    },
  );

  test('consulta antiga não restaura avaliação removida', () async {
    when(() => ratingRepo.list(1))
        .thenAnswer((_) async => ratings([rated('1', ratingId: 'r1')]));
    when(() => ratingRepo.remove('r1')).thenAnswer((_) async {});
    final model = container.read(eventRatingsViewModelProvider.notifier);
    await model.load();
    final response = Completer<RatedEventPage>();
    when(() => ratingRepo.list(1)).thenAnswer((_) => response.future);
    final refresh = model.load(refresh: true);
    await model.remove('1');
    response.complete(ratings([rated('1', ratingId: 'r1')]));
    await refresh;
    expect(container.read(eventRatingsViewModelProvider).events, isEmpty);
  });

  test(
    'invalidar estado privado descarta respostas da conta anterior',
    () async {
      final response = Completer<RatedEventPage>();
      when(() => ratingRepo.list(1)).thenAnswer((_) => response.future);
      final old = container.read(eventRatingsViewModelProvider.notifier).load();
      container.invalidate(eventRatingsViewModelProvider);
      expect(container.read(eventRatingsViewModelProvider).events, isEmpty);
      response.complete(ratings([rated('1')]));
      await old;
      expect(container.read(eventRatingsViewModelProvider).events, isEmpty);
    },
  );
}
