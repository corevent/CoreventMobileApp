import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'ticket_dtos.dart';

part 'tickets_api.g.dart';

@RestApi()
abstract class TicketsApi {
  factory TicketsApi(Dio dio, {String? baseUrl}) = _TicketsApi;

  @GET('/api/users/me/tickets')
  Future<TicketPage> mine(@Query('page') int page, @Query('limit') int limit);

  @GET('/api/events/{eventId}/my/tickets')
  Future<EventTicketsResponse> mineForEvent(@Path('eventId') String eventId);
}
