import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../events/data/event_dtos.dart';
import '../data/favorites_repository.dart';
import 'favorites_view_model.dart';

class EventFavoritesState {
  const EventFavoritesState({
    this.ids = const {},
    this.events = const {},
    this.busy = const {},
    this.loaded = false,
    this.loading = false,
    this.error,
  });
  final Map<String, String> ids;
  final Map<String, EventSummary> events;
  final Set<String> busy;
  final bool loaded;
  final bool loading;
  final String? error;
  bool known(String eventId) => loaded || ids.containsKey(eventId);
}

/// Complete account index, independent of the visible list's filter and pages.
class EventFavoritesViewModel extends Notifier<EventFavoritesState> {
  final _changes = <String, String?>{};
  Future<void>? _loading;
  int _generation = 0;
  @override
  EventFavoritesState build() {
    _generation++;
    _changes.clear();
    _loading = null;
    ref.onDispose(() => _generation++);
    return const EventFavoritesState();
  }

  bool _current(int generation) => ref.mounted && generation == _generation;

  Future<void> load({bool refresh = false}) {
    if (_loading != null) return _loading!;
    if (state.loaded && !refresh) return Future.value();
    final generation = _generation;
    return _loading = _load(generation).whenComplete(() {
      if (_current(generation)) _loading = null;
    });
  }

  Future<void> _load(int generation) async {
    _changes.clear();
    state = EventFavoritesState(
      ids: state.ids,
      events: state.events,
      busy: state.busy,
      loaded: state.loaded,
      loading: true,
    );
    try {
      final ids = <String, String>{};
      final events = <String, EventSummary>{};
      final repository = ref.read(favoritesRepositoryProvider);
      for (final status in FavoriteStatus.values) {
        var page = 1;
        var total = 1;
        do {
          final result = await repository.list(page, status.value);
          if (!_current(generation)) return;
          for (final event in result.data) {
            if (event.favoriteId != null) ids[event.id] = event.favoriteId!;
            events[event.id] = event;
          }
          total = result.meta.totalPages;
          page++;
        } while (page <= total);
      }
      // A read started before a write must not undo the confirmed change.
      for (final change in _changes.entries) {
        if (change.value == null) {
          ids.remove(change.key);
        } else {
          ids[change.key] = change.value!;
        }
      }
      state = EventFavoritesState(
        ids: Map.unmodifiable(ids),
        events: Map.unmodifiable(events),
        busy: state.busy,
        loaded: true,
      );
    } catch (_) {
      if (!_current(generation)) return;
      state = EventFavoritesState(
        ids: state.ids,
        events: state.events,
        busy: state.busy,
        loaded: state.loaded,
        error: 'Não foi possível consultar seus favoritos.',
      );
    }
  }

  void recordRemoval(String eventId) => _record(eventId, null);

  void _record(String eventId, String? id) {
    _changes[eventId] = id;
    final ids = {...state.ids};
    if (id == null) {
      ids.remove(eventId);
    } else {
      ids[eventId] = id;
    }
    state = EventFavoritesState(
      ids: Map.unmodifiable(ids),
      events: state.events,
      busy: state.busy,
      loaded: state.loaded,
      loading: state.loading,
      error: state.error,
    );
  }

  Future<String?> toggle(String eventId) async {
    final generation = _generation;
    if (state.busy.contains(eventId)) return null;
    if (!state.known(eventId)) {
      await load();
      if (!_current(generation)) return null;
      if (!state.known(eventId)) return state.error ?? 'Tente novamente.';
    }
    if (state.busy.contains(eventId)) return null;
    final id = state.ids[eventId];
    _setBusy(eventId, true);
    try {
      final repository = ref.read(favoritesRepositoryProvider);
      if (id == null) {
        final created = await repository.create(eventId);
        if (!_current(generation)) return null;
        _record(eventId, created);
        ref.read(favoritesViewModelProvider.notifier).requestRefresh();
      } else {
        await repository.remove(id);
        if (!_current(generation)) return null;
        _record(eventId, null);
        ref.read(favoritesViewModelProvider.notifier).applyRemoval(id);
      }
      return null;
    } on DioException catch (error) {
      if (!_current(generation)) return null;
      if (id != null && error.response?.statusCode == 404) {
        _record(eventId, null);
        ref.read(favoritesViewModelProvider.notifier).applyRemoval(id);
        return null;
      }
      if (error.response?.statusCode == 400) {
        _changes.remove(eventId);
        await load(refresh: true);
      }
      return 'Não foi possível atualizar o favorito. Tente novamente.';
    } catch (_) {
      return 'Não foi possível atualizar o favorito. Tente novamente.';
    } finally {
      if (_current(generation)) _setBusy(eventId, false);
    }
  }

  void _setBusy(String eventId, bool busy) {
    final ids = {...state.busy};
    busy ? ids.add(eventId) : ids.remove(eventId);
    state = EventFavoritesState(
      ids: state.ids,
      events: state.events,
      busy: Set.unmodifiable(ids),
      loaded: state.loaded,
      loading: state.loading,
      error: state.error,
    );
  }
}

final eventFavoritesViewModelProvider =
    NotifierProvider<EventFavoritesViewModel, EventFavoritesState>(
      EventFavoritesViewModel.new,
    );
