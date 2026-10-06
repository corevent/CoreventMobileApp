import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'event_dtos.dart';

part 'events_api.g.dart';

@RestApi()
abstract class EventsApi {
  factory EventsApi(Dio dio, {String? baseUrl}) = _EventsApi;

  @GET('/api/events')
  Future<EventPage> getEvents(
    @Query('page') int page,
    @Query('limit') int limit,
    @Query('status') String status,
    @Query('search') String? search,
    @Query('category') String? category,
  );

  @GET('/api/events/{id}')
  Future<EventDetailResponse> getEvent(@Path('id') String id);
}
