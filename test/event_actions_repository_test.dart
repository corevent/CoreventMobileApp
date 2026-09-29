import 'package:corevent_mobile_app/features/favorites/data/favorites_api.dart';
import 'package:corevent_mobile_app/features/favorites/data/favorites_repository.dart';
import 'package:corevent_mobile_app/features/ratings/data/ratings_api.dart';
import 'package:corevent_mobile_app/features/ratings/data/ratings_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('clientes enviam contratos REST corretos e leem envelopes', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'));
    addTearDown(dio.close);
    final requests = <RequestOptions>[];
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          requests.add(request);
          final body = switch (request.path) {
            '/api/favorites/events/e1' => {
              'data': {'id': 'f1', 'eventId': 'e1', 'userId': 'u1'},
            },
            '/api/events/e1/ratings' || '/api/events/ratings/r1' => {
              'data': {
                'id': 'r1',
                'eventId': 'e1',
                'rating':
                    (request.data as Map<String, dynamic>?)?['rating'] ?? 4,
              },
            },
            _ => null,
          };
          handler.resolve(
            Response(
              requestOptions: request,
              statusCode: request.method == 'DELETE' ? 204 : 200,
              data: body,
            ),
          );
        },
      ),
    );
    final favorites = FavoritesRepository(FavoritesApi(dio));
    expect(await favorites.create('e1'), 'f1');
    await favorites.remove('f1');
    final ratings = RatingsRepository(RatingsApi(dio));
    expect((await ratings.save('e1', 4)).id, 'r1');
    expect((await ratings.save('e1', 5, id: 'r1')).rating, 5);
    await ratings.remove('r1');
    expect(requests.map((r) => '${r.method} ${r.path}'), [
      'POST /api/favorites/events/e1',
      'DELETE /api/favorites/f1',
      'POST /api/events/e1/ratings',
      'PATCH /api/events/ratings/r1',
      'DELETE /api/events/ratings/r1',
    ]);
    expect(requests[2].data, {'rating': 4});
    expect(requests[3].data, {'rating': 5});
    await expectLater(ratings.save('e1', 6), throwsArgumentError);
    expect(requests, hasLength(5));
  });
}
