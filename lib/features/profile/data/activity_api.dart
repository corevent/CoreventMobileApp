import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'activity_dtos.dart';

part 'activity_api.g.dart';

@RestApi()
abstract class ActivityApi {
  factory ActivityApi(Dio dio, {String? baseUrl}) = _ActivityApi;

  @GET('/api/events/my/orders')
  Future<OrderPage> orders(@Query('page') int page, @Query('limit') int limit);

  @GET('/api/events/orders/{id}')
  Future<OrderDetailsResponse> order(@Path('id') String id);

  @GET('/api/events/my/ratings')
  Future<RatingsPage> ratings(
    @Query('page') int page,
    @Query('limit') int limit,
  );
}
