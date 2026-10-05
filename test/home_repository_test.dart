import 'package:corevent_mobile_app/features/events/data/event_dtos.dart';
import 'package:corevent_mobile_app/features/events/data/events_api.dart';
import 'package:corevent_mobile_app/features/events/data/events_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockEventsApi extends Mock implements EventsApi {}

void main() {
  test('consulta somente eventos abertos com filtros e página', () async {
    final api = MockEventsApi();
    const result = EventPage(
      data: [],
      meta: EventPageMeta(totalPages: 2, page: 3),
    );
    when(() => api.getEvents(3, 20, 'opened', 'show', 'music'))
        .thenAnswer((_) async => result);
    final repository = EventsRepository(api);

    expect(
      await repository.list(page: 3, search: 'show', category: 'music'),
      result,
    );
    verify(() => api.getEvents(3, 20, 'opened', 'show', 'music')).called(1);
  });

  test('Home consulta 50 eventos, como o cliente MAUI', () async {
    final api = MockEventsApi();
    const result = EventPage(
      data: [],
      meta: EventPageMeta(totalPages: 1, page: 1),
    );
    when(() => api.getEvents(1, 50, 'opened', null, null))
        .thenAnswer((_) async => result);

    expect(await EventsRepository(api).list(page: 1, limit: 50), result);
    verify(() => api.getEvents(1, 50, 'opened', null, null)).called(1);
  });

  test('lê evento online com local e organizador ausentes', () {
    final response = EventPage.fromJson({
      'data': [
        {
          'id': 'online-1',
          'title': 'Encontro online',
          'startDate': '2026-10-01T19:00:00.000Z',
          'endDate': '2026-10-01T21:00:00.000Z',
          'category': 'tech',
          'isAdultOnly': false,
          'locationName': null,
          'locationType': 'online',
          'organizer': null,
        },
      ],
      'meta': {'currentPage': '1', 'itemsPerPage': 50, 'totalPages': '2'},
    });

    expect(response.data.single.locationName, '');
    expect(response.data.single.organizer.name, 'Organizador');
    expect(response.meta.totalPages, 2);
  });

  test('Retrofit consulta a rota real e lê a paginação da API', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example/'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.path, '/api/events');
          expect(options.queryParameters, {
            'page': 1,
            'limit': 50,
            'status': 'opened',
          });
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'data': [
                  {
                    'id': 'evt-1',
                    'title': 'Evento online',
                    'startDate': '2026-10-01T19:00:00.000Z',
                    'endDate': '2026-10-01T21:00:00.000Z',
                    'category': 'tech',
                    'isAdultOnly': false,
                    'locationType': 'online',
                    'locationName': null,
                    'organizer': {'name': 'Corevent'},
                  },
                ],
                'meta': {
                  'currentPage': 1,
                  'itemsPerPage': 50,
                  'totalItems': 1,
                  'totalPages': 1,
                },
              },
            ),
          );
        },
      ),
    );

    final result = await EventsRepository(EventsApi(dio))
        .list(page: 1, limit: 50);
    expect(result.data.single.title, 'Evento online');
    expect(result.data.single.locationName, '');
    expect(result.meta.page, 1);
  });
}
