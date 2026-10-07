import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';
import 'event_dtos.dart';
import 'events_api.dart';

class EventsRepository {
  const EventsRepository(this._api);

  final EventsApi _api;

  Future<EventPage> list({
    required int page,
    int limit = 20,
    String? search,
    String? category,
  }) => _api.getEvents(page, limit, 'opened', search, category);

  Future<EventDetail> detail(String id) async => (await _api.getEvent(id)).data;
}

final eventsApiProvider = Provider<EventsApi>(
  (ref) => EventsApi(ref.watch(authorizedDioProvider)),
);

final eventsRepositoryProvider = Provider<EventsRepository>(
  (ref) => EventsRepository(ref.watch(eventsApiProvider)),
);
