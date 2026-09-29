import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';
import '../../events/data/event_dtos.dart';
import 'favorites_api.dart';

class FavoritesRepository {
  const FavoritesRepository(this.api);
  final FavoritesApi api;

  Future<EventPage> list(int page, String status) => api.list(page, 20, status);
  Future<void> remove(String id) => api.remove(id);
  Future<String> create(String eventId) async =>
      (await api.create(eventId)).data.id;
}

final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (ref) => FavoritesRepository(FavoritesApi(ref.watch(authorizedDioProvider))),
);
