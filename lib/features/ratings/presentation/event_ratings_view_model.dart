import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/rating_dtos.dart';
import '../data/ratings_repository.dart';

class EventRatingsState {
  const EventRatingsState({
    this.events = const {},
    this.busy = const {},
    this.loaded = false,
    this.loading = false,
    this.error,
    this.revision = 0,
  });
  final Map<String, RatedEvent> events;
  final Set<String> busy;
  final bool loaded;
  final bool loading;
  final String? error;
  final int revision;
}

class EventRatingsViewModel extends Notifier<EventRatingsState> {
  final _changes = <String, RatedEvent?>{};
  Future<void>? _loading;
  int _generation = 0;
  @override
  EventRatingsState build() {
    _generation++;
    _changes.clear();
    _loading = null;
    ref.onDispose(() => _generation++);
    return const EventRatingsState();
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
    _emit(loading: true);
    try {
      final events = <String, RatedEvent>{};
      var page = 1;
      var total = 1;
      do {
        final result = await ref.read(ratingsRepositoryProvider).list(page);
        if (!_current(generation)) return;
        for (final event in result.data) {
          events[event.eventId] = event.withRating(
            event.userRating,
            event.ratingId ?? state.events[event.eventId]?.ratingId,
          );
        }
        total = result.meta.totalPages;
        page++;
      } while (page <= total);
      for (final change in _changes.entries) {
        if (change.value == null) {
          events.remove(change.key);
        } else {
          events[change.key] = change.value!;
        }
      }
      _emit(events: events, loaded: true);
    } catch (_) {
      if (_current(generation)) {
        _emit(error: 'Não foi possível consultar suas avaliações.');
      }
    }
  }

  Future<String?> save(RatedEvent event, int rating) async {
    final generation = _generation;
    if (rating < 1 || rating > 5) return 'Escolha uma nota de 1 a 5.';
    if (state.busy.contains(event.eventId)) {
      return 'Aguarde o envio da avaliação.';
    }
    if (!state.loaded) {
      await load();
      if (!_current(generation)) return null;
      if (!state.loaded) {
        return state.error ?? 'Não foi possível consultar suas avaliações.';
      }
    }
    if (state.busy.contains(event.eventId)) {
      return 'Aguarde o envio da avaliação.';
    }
    final existing = state.events[event.eventId];
    if (existing != null && existing.ratingId == null) {
      return 'Esta avaliação está disponível apenas para consulta.';
    }
    _busy(event.eventId, true);
    try {
      final result = await ref
          .read(ratingsRepositoryProvider)
          .save(event.eventId, rating, id: existing?.ratingId);
      if (!_current(generation)) return null;
      _record(event.eventId, event.withRating(result.rating, result.id));
      return null;
    } on DioException catch (error) {
      if (!_current(generation)) return null;
      if (error.response?.statusCode == 400 ||
          error.response?.statusCode == 404) {
        if (error.response?.statusCode == 404 && existing != null) {
          _emit(
            events: {
              ...state.events,
              event.eventId: existing.withRating(existing.userRating, null),
            },
            loading: state.loading,
          );
        }
        await load(refresh: true);
      }
      return 'Não foi possível salvar a avaliação. Tente novamente.';
    } catch (_) {
      return 'Não foi possível salvar a avaliação. Tente novamente.';
    } finally {
      if (_current(generation)) _busy(event.eventId, false);
    }
  }

  Future<String?> remove(String eventId) async {
    final generation = _generation;
    final existing = state.events[eventId];
    if (existing?.ratingId == null) {
      return 'Esta avaliação está disponível apenas para consulta.';
    }
    if (state.busy.contains(eventId)) return 'Aguarde o envio da avaliação.';
    _busy(eventId, true);
    try {
      await ref.read(ratingsRepositoryProvider).remove(existing!.ratingId!);
      if (!_current(generation)) return null;
      _record(eventId, null);
      return null;
    } on DioException catch (error) {
      if (!_current(generation)) return null;
      if (error.response?.statusCode == 404) {
        _record(eventId, null);
        return null;
      }
      return 'Não foi possível remover a avaliação. Tente novamente.';
    } catch (_) {
      return 'Não foi possível remover a avaliação. Tente novamente.';
    } finally {
      if (_current(generation)) _busy(eventId, false);
    }
  }

  void _record(String id, RatedEvent? event) {
    _changes[id] = event;
    final events = {...state.events};
    if (event == null) {
      events.remove(id);
    } else {
      events[id] = event;
    }
    _emit(events: events, loading: state.loading, revision: state.revision + 1);
  }

  void _busy(String id, bool busy) {
    final ids = {...state.busy};
    busy ? ids.add(id) : ids.remove(id);
    _emit(busy: ids, loading: state.loading, error: state.error);
  }

  void _emit({
    Map<String, RatedEvent>? events,
    Set<String>? busy,
    bool? loaded,
    bool loading = false,
    String? error,
    int? revision,
  }) {
    state = EventRatingsState(
      events: Map.unmodifiable(events ?? state.events),
      busy: Set.unmodifiable(busy ?? state.busy),
      loaded: loaded ?? state.loaded,
      loading: loading,
      error: error,
      revision: revision ?? state.revision,
    );
  }
}

final eventRatingsViewModelProvider =
    NotifierProvider<EventRatingsViewModel, EventRatingsState>(
      EventRatingsViewModel.new,
    );
