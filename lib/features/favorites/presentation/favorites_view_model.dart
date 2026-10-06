import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../events/data/event_dtos.dart';
import '../data/favorites_repository.dart';

enum FavoriteStatus {
  opened('opened', 'Abertos', 'Nenhum evento aberto salvo'),
  going('going', 'Em andamento', 'Nenhum evento em andamento salvo'),
  finished('finished', 'Encerrados', 'Nenhum evento encerrado salvo');

  const FavoriteStatus(this.value, this.label, this.emptyTitle);
  final String value;
  final String label;
  final String emptyTitle;
}

const _unchanged = Object();

class FavoritesState {
  const FavoritesState({
    this.events = const [],
    this.status = FavoriteStatus.opened,
    this.hasLoaded = false,
    this.loading = false,
    this.refreshing = false,
    this.loadingMore = false,
    this.page = 0,
    this.hasMore = false,
    this.removingIds = const {},
    this.error,
    this.refreshError,
    this.loadMoreError,
  });
  final List<EventSummary> events;
  final FavoriteStatus status;
  final bool hasLoaded;
  final bool loading;
  final bool refreshing;
  final bool loadingMore;
  final int page;
  final bool hasMore;
  final Set<String> removingIds;
  final String? error;
  final String? refreshError;
  final String? loadMoreError;

  FavoritesState copyWith({
    List<EventSummary>? events,
    bool? hasLoaded,
    bool? loading,
    bool? refreshing,
    bool? loadingMore,
    int? page,
    bool? hasMore,
    Set<String>? removingIds,
    Object? error = _unchanged,
    Object? refreshError = _unchanged,
    Object? loadMoreError = _unchanged,
  }) => FavoritesState(
    status: status,
    events: events == null ? this.events : List.unmodifiable(events),
    hasLoaded: hasLoaded ?? this.hasLoaded,
    loading: loading ?? this.loading,
    refreshing: refreshing ?? this.refreshing,
    loadingMore: loadingMore ?? this.loadingMore,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    removingIds: removingIds == null
        ? this.removingIds
        : Set.unmodifiable(removingIds),
    error: identical(error, _unchanged) ? this.error : error as String?,
    refreshError: identical(refreshError, _unchanged)
        ? this.refreshError
        : refreshError as String?,
    loadMoreError: identical(loadMoreError, _unchanged)
        ? this.loadMoreError
        : loadMoreError as String?,
  );
}

class FavoritesViewModel extends Notifier<FavoritesState> {
  int _generation = 0;
  int _lifecycle = 0;
  int _mutation = 0;
  bool _paginationDirty = false;
  bool _refreshPending = false;
  final _removed = <String>{};

  @override
  FavoritesState build() {
    _generation++;
    _lifecycle++;
    _mutation = 0;
    _paginationDirty = false;
    _refreshPending = false;
    _removed.clear();
    ref.onDispose(() {
      _generation++;
      _lifecycle++;
    });
    return const FavoritesState();
  }

  bool _current(int generation) => ref.mounted && generation == _generation;

  List<EventSummary> _unique(Iterable<EventSummary> events) =>
      <String, EventSummary>{
        for (final event in events)
          if (!_removed.contains(event.favoriteId)) event.id: event,
      }.values.toList();

  Future<void> load() async {
    if (state.loading || state.refreshing) return;
    await _firstPage(refresh: state.hasLoaded);
  }

  void requestRefresh() {
    if (state.loading || state.refreshing || state.loadingMore) {
      _refreshPending = true;
    } else if (state.hasLoaded) {
      unawaited(load());
    }
  }

  void _flushRefresh() {
    if (!_refreshPending || !ref.mounted) return;
    _refreshPending = false;
    requestRefresh();
  }

  void applyRemoval(String id) {
    _removed.add(id);
    _mutation++;
    _paginationDirty = true;
    state = state.copyWith(
      events: state.events.where((e) => e.favoriteId != id).toList(),
    );
    if (state.events.isEmpty && state.hasMore) unawaited(loadMore());
  }

  Future<String?> refresh() async {
    if (state.loading || state.refreshing) return null;
    return _firstPage(refresh: state.hasLoaded);
  }

  void selectStatus(FavoriteStatus status) {
    if (status == state.status) return;
    _generation++;
    _paginationDirty = false;
    state = FavoritesState(status: status, removingIds: state.removingIds);
    unawaited(_firstPage(refresh: false));
  }

  Future<String?> _firstPage({required bool refresh}) async {
    final generation = ++_generation;
    final status = state.status;
    final mutation = _mutation;
    state = state.copyWith(
      loading: !refresh,
      refreshing: refresh,
      loadingMore: false,
      error: null,
      refreshError: null,
      loadMoreError: null,
    );
    try {
      final result = await ref
          .read(favoritesRepositoryProvider)
          .list(1, status.value);
      if (!_current(generation)) return null;
      _paginationDirty = mutation != _mutation;
      state = state.copyWith(
        events: _unique(result.data),
        page: 1,
        hasMore: result.meta.totalPages > 1,
        hasLoaded: true,
        loading: false,
        refreshing: false,
      );
      return null;
    } catch (_) {
      if (!_current(generation)) return null;
      const message = 'Não foi possível carregar seus favoritos.';
      state = state.copyWith(
        loading: false,
        refreshing: false,
        error: refresh ? null : message,
        refreshError: refresh ? message : null,
      );
      return message;
    } finally {
      if (_current(generation)) _flushRefresh();
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
    final status = state.status;
    final next = state.page + 1;
    state = state.copyWith(loadingMore: true, loadMoreError: null);
    try {
      var mutation = _mutation;
      var rebuild = _paginationDirty;
      final events = <EventSummary>[];
      var totalPages = next;
      do {
        mutation = _mutation;
        events.clear();
        if (!rebuild) events.addAll(state.events);
        for (
          var page = rebuild ? 1 : next;
          page <= next && page <= totalPages;
          page++
        ) {
          final result = await ref
              .read(favoritesRepositoryProvider)
              .list(page, status.value);
          if (!_current(generation)) return;
          totalPages = result.meta.totalPages;
          events.addAll(result.data);
        }
        rebuild = mutation != _mutation;
      } while (rebuild);
      if (!_current(generation)) return;
      _paginationDirty = false;
      state = state.copyWith(
        events: _unique(events),
        page: next < totalPages ? next : totalPages,
        hasMore: next < totalPages,
        loadingMore: false,
      );
    } catch (_) {
      if (!_current(generation)) return;
      state = state.copyWith(
        loadingMore: false,
        loadMoreError: 'Não foi possível carregar mais favoritos.',
      );
    } finally {
      if (_current(generation)) _flushRefresh();
    }
  }

  Future<bool> remove(EventSummary event) async {
    final lifecycle = _lifecycle;
    final id = event.favoriteId;
    if (id == null || state.removingIds.contains(id)) return false;
    state = state.copyWith(removingIds: {...state.removingIds, id});
    try {
      await ref.read(favoritesRepositoryProvider).remove(id);
      if (!ref.mounted || lifecycle != _lifecycle) return false;
      _removed.add(id);
      _mutation++;
      _paginationDirty = true;
      state = state.copyWith(
        events: state.events.where((e) => e.favoriteId != id).toList(),
        removingIds: {...state.removingIds}..remove(id),
      );
      if (state.events.isEmpty && state.hasMore) unawaited(loadMore());
      return true;
    } catch (_) {
      if (ref.mounted && lifecycle == _lifecycle) {
        state = state.copyWith(removingIds: {...state.removingIds}..remove(id));
      }
      return false;
    }
  }
}

final favoritesViewModelProvider =
    NotifierProvider<FavoritesViewModel, FavoritesState>(
      FavoritesViewModel.new,
    );
