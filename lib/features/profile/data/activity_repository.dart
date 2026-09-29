import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';
import 'activity_api.dart';
import 'activity_dtos.dart';

class ActivityRepository {
  const ActivityRepository(this.api);
  final ActivityApi api;

  Future<OrderPage> orders(int page) => api.orders(page, 20);
  Future<OrderDetails> order(String id) async => (await api.order(id)).data;
  Future<RatingsPage> ratings(int page) => api.ratings(page, 20);
}

final activityApiProvider = Provider<ActivityApi>(
  (ref) => ActivityApi(ref.watch(authorizedDioProvider)),
);
final activityRepositoryProvider = Provider<ActivityRepository>(
  (ref) => ActivityRepository(ref.watch(activityApiProvider)),
);
