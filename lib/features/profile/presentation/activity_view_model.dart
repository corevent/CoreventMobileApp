import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/activity_dtos.dart';
import '../data/activity_repository.dart';

enum ActivityKind { orders, ratings }

class ActivityState {
  const ActivityState({
    this.loading = false,
    this.loadingMore = false,
    this.error,
    this.items = const [],
    this.page = 0,
    this.hasMore = false,
  });
  final bool loading;
  final bool loadingMore;
  final String? error;
  final List<Object> items;
  final int page;
  final bool hasMore;
}

class ActivityViewModel extends Notifier<ActivityState> {
  ActivityViewModel(this.kind);
  final ActivityKind kind;
  int _generation = 0;

  @override
  ActivityState build() {
    ref.onDispose(() => _generation++);
    return const ActivityState();
  }

  Future<void> load() async {
    if (state.loading) return;
    final generation = ++_generation;
    state = ActivityState(
      loading: true,
      items: state.items,
      page: state.page,
      hasMore: state.hasMore,
    );
    try {
      final result = await _fetch(1);
      if (!ref.mounted || generation != _generation) return;
      state = ActivityState(items: result.$1, page: 1, hasMore: 1 < result.$2);
    } catch (_) {
      if (!ref.mounted || generation != _generation) return;
      state = ActivityState(
        items: state.items,
        page: state.page,
        hasMore: state.hasMore,
        error: 'Não foi possível carregar os dados.',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || !state.hasMore) return;
    final generation = _generation;
    state = ActivityState(
      items: state.items,
      page: state.page,
      hasMore: state.hasMore,
      loadingMore: true,
    );
    try {
      final next = state.page + 1;
      final result = await _fetch(next);
      if (!ref.mounted || generation != _generation) return;
      final unique = <String, Object>{
        for (final item in [...state.items, ...result.$1]) _id(item): item,
      };
      state = ActivityState(
        items: unique.values.toList(),
        page: next,
        hasMore: next < result.$2,
      );
    } catch (_) {
      if (!ref.mounted || generation != _generation) return;
      state = ActivityState(
        items: state.items,
        page: state.page,
        hasMore: state.hasMore,
        error: 'Não foi possível carregar mais itens.',
      );
    }
  }

  Future<(List<Object>, int)> _fetch(int page) async {
    final repository = ref.read(activityRepositoryProvider);
    switch (kind) {
      case ActivityKind.orders:
        final result = await repository.orders(page);
        return (result.data, result.meta.totalPages);
      case ActivityKind.ratings:
        final result = await repository.ratings(page);
        return (result.data, result.meta.totalPages);
    }
  }

  String _id(Object item) => switch (item) {
    final BuyerOrder order => order.id,
    final BuyerRating rating => rating.eventId,
    _ => item.hashCode.toString(),
  };
}

final ordersViewModelProvider =
    NotifierProvider<ActivityViewModel, ActivityState>(
      () => ActivityViewModel(ActivityKind.orders),
    );
final ratingsViewModelProvider =
    NotifierProvider<ActivityViewModel, ActivityState>(
      () => ActivityViewModel(ActivityKind.ratings),
    );
