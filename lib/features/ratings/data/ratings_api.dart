import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'rating_dtos.dart';

part 'ratings_api.g.dart';

@RestApi()
abstract class RatingsApi {
  factory RatingsApi(Dio dio, {String? baseUrl}) = _RatingsApi;
  @GET('/api/events/my/ratings')
  Future<RatedEventPage> list(
    @Query('page') int page,
    @Query('limit') int limit,
  );
  @POST('/api/events/{eventId}/ratings')
  Future<RatingResponse> create(
    @Path('eventId') String eventId,
    @Body() RatingRequest body,
  );
  @PATCH('/api/events/ratings/{id}')
  Future<RatingResponse> update(
    @Path('id') String id,
    @Body() RatingRequest body,
  );
  @DELETE('/api/events/ratings/{id}')
  Future<void> remove(@Path('id') String id);
}
