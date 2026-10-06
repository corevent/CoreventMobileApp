import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../events/data/event_dtos.dart';
import 'favorite_dtos.dart';

part 'favorites_api.g.dart';

@RestApi()
abstract class FavoritesApi {
  factory FavoritesApi(Dio dio, {String? baseUrl}) = _FavoritesApi;

  @GET('/api/events/my/favorites')
  Future<EventPage> list(
    @Query('page') int page,
    @Query('limit') int limit,
    @Query('status') String status,
  );

  @DELETE('/api/favorites/{id}')
  Future<void> remove(@Path('id') String id);

  @POST('/api/favorites/events/{eventId}')
  Future<FavoriteResponse> create(@Path('eventId') String eventId);
}
