import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';
import 'rating_dtos.dart';
import 'ratings_api.dart';

class RatingsRepository {
  const RatingsRepository(this.api);
  final RatingsApi api;
  Future<RatedEventPage> list(int page) => api.list(page, 20);
  Future<RatingData> save(String eventId, int rating, {String? id}) async {
    if (rating < 1 || rating > 5) throw ArgumentError.value(rating, 'rating');
    final body = RatingRequest(rating);
    return (id == null
            ? await api.create(eventId, body)
            : await api.update(id, body))
        .data;
  }

  Future<void> remove(String id) => api.remove(id);
}

final ratingsRepositoryProvider = Provider<RatingsRepository>(
  (ref) => RatingsRepository(RatingsApi(ref.watch(authorizedDioProvider))),
);
