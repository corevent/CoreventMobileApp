import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_session.dart';
import '../../events/data/event_dtos.dart';
import '../../events/data/events_repository.dart';
import '../../events/domain/event_discovery_filter.dart';
import '../../events/domain/event_visibility.dart';
import 'explore_state.dart';

class ExploreViewModel extends Notifier<ExploreState> {
  Timer? _searchTimer;
  int _generation = 0;

  @override
  ExploreState build() {
    ref.onDispose(() {
      _generation++;
      _searchTimer?.cancel();
    });
    return const ExploreState();
  }

  void applyDiscovery(EventDiscoveryFilter filter) {
    _searchTimer?.cancel();
    _generation++;
    state = state.copyWith(
      search: '',
      category: filter.category,
      discovery: filter,
      events: [],
      page: 0,
      hasMore: false,
      loading: true,
      refreshing: false,
      loadingMore: false,
      error: null,
      refreshError: null,
      loadMoreError: null,
    );
    load();
  }

  Future<({List<EventSummary> events, int page, bool hasMore})?> _fetch(
    int page,
    int generation,
  ) async {
    final query = state.search.trim();
    final category = state.category;
    final filter = state.discovery;
    final birthDate = ref.read(authSessionProvider).user?.birthDate;
    final events = <EventSummary>[];
    var currentPage = page;
    var hasMore = false;
    // Bound requests when a client-side filter finds no matches in a page.
    for (var attempt = 0; attempt < 3; attempt++) {
      final result = await ref
          .read(eventsRepositoryProvider)
          .list(
            page: currentPage,
            limit: 10,
            search: query.isEmpty ? null : query,
            category: category,
          );
      if (!ref.mounted || generation != _generation) return null;
      events.addAll(
        visibleEvents(
          result.data,
          birthDate: birthDate,
          now: DateTime.now(),
        ).where(filter.matches),
      );
      hasMore = currentPage < result.meta.totalPages;
      if (events.isNotEmpty || !hasMore || attempt == 2) break;
      currentPage++;
    }
    return (events: events, page: currentPage, hasMore: hasMore);
  }

  void setSearch(String value) {
    _searchTimer?.cancel();
    _generation++;
    state = state.copyWith(
      search: value,
      events: [],
      page: 0,
      hasMore: false,
      loading: true,
      refreshing: false,
      loadingMore: false,
      error: null,
      loadMoreError: null,
    );
    _searchTimer = Timer(const Duration(milliseconds: 350), load);
  }

  void submitSearch() {
    _searchTimer?.cancel();
    load();
  }

  void setCategory(String? category) {
    if (state.category == category) return;
    _searchTimer?.cancel();
    _generation++;
    state = state.copyWith(
      category: category,
      discovery: EventDiscoveryFilter(
        category: category,
        locationType: state.discovery.locationType,
        from: state.discovery.from,
        until: state.discovery.until,
      ),
      events: [],
      page: 0,
      hasMore: false,
      loading: true,
      refreshing: false,
      loadingMore: false,
      error: null,
      loadMoreError: null,
    );
    load();
  }

  void clearFilters() {
    _searchTimer?.cancel();
    _generation++;
    state = state.copyWith(
      search: '',
      category: null,
      discovery: const EventDiscoveryFilter(),
      events: [],
      page: 0,
      hasMore: false,
      loading: true,
      refreshing: false,
      loadingMore: false,
      error: null,
      loadMoreError: null,
    );
    load();
  }

  Future<void> load() async {
    final generation = ++_generation;
    state = state.copyWith(
      loading: true,
      refreshing: false,
      loadingMore: false,
      error: null,
      refreshError: null,
      loadMoreError: null,
    );
    try {
      final result = await _fetch(1, generation);
      if (result == null) return;
      state = state.copyWith(
        events: result.events,
        page: result.page,
        hasMore: result.hasMore,
        loading: false,
      );
    } catch (_) {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(
        events: [],
        page: 0,
        hasMore: false,
        loading: false,
        error: 'Não foi possível carregar os eventos.',
      );
    }
  }

  Future<void> refresh() async {
    _searchTimer?.cancel();
    final generation = ++_generation;
    state = state.copyWith(
      refreshing: true,
      loadingMore: false,
      refreshError: null,
      loadMoreError: null,
    );
    try {
      final result = await _fetch(1, generation);
      if (result == null) return;
      state = state.copyWith(
        events: result.events,
        page: result.page,
        hasMore: result.hasMore,
        loading: false,
        refreshing: false,
        error: null,
      );
    } catch (_) {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(
        loading: false,
        refreshing: false,
        refreshError: 'Não foi possível atualizar. Puxe para tentar novamente.',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.loading ||
        state.refreshing ||
        state.loadingMore ||
        !state.hasMore) {
      return;
    }
    final generation = _generation;
    final nextPage = state.page + 1;
    state = state.copyWith(loadingMore: true, loadMoreError: null);
    try {
      final result = await _fetch(nextPage, generation);
      if (result == null) return;
      state = state.copyWith(
        events: visibleEvents(
          [...state.events, ...result.events],
          birthDate: ref.read(authSessionProvider).user?.birthDate,
          now: DateTime.now(),
        ),
        page: result.page,
        hasMore: result.hasMore,
        loadingMore: false,
      );
    } catch (_) {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(
        loadingMore: false,
        loadMoreError: 'Não foi possível carregar mais eventos.',
      );
    }
  }
}

final exploreViewModelProvider =
    NotifierProvider<ExploreViewModel, ExploreState>(ExploreViewModel.new);
