import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_session.dart';
import '../../events/data/events_repository.dart';
import '../../events/domain/event_visibility.dart';
import 'home_state.dart';

class HomeViewModel extends Notifier<HomeState> {
  int _generation = 0;

  @override
  HomeState build() {
    ref.onDispose(() {
      _generation++;
    });
    return const HomeState();
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
      final result = await ref
          .read(eventsRepositoryProvider)
          .list(page: 1, limit: 50);
      if (!ref.mounted || generation != _generation) return;
      final birthDate = ref.read(authSessionProvider).user?.birthDate;
      state = state.copyWith(
        events: visibleEvents(
          result.data,
          birthDate: birthDate,
          now: DateTime.now(),
        ),
        page: 1,
        hasMore: result.meta.totalPages > 1,
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
    final generation = ++_generation;
    state = state.copyWith(
      refreshing: true,
      loadingMore: false,
      refreshError: null,
      loadMoreError: null,
    );
    try {
      final result = await ref
          .read(eventsRepositoryProvider)
          .list(page: 1, limit: 50);
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(
        events: visibleEvents(
          result.data,
          birthDate: ref.read(authSessionProvider).user?.birthDate,
          now: DateTime.now(),
        ),
        page: 1,
        hasMore: result.meta.totalPages > 1,
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
      final result = await ref
          .read(eventsRepositoryProvider)
          .list(page: nextPage, limit: 50);
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(
        events: visibleEvents(
          [...state.events, ...result.data],
          birthDate: ref.read(authSessionProvider).user?.birthDate,
          now: DateTime.now(),
        ),
        page: nextPage,
        hasMore: nextPage < result.meta.totalPages,
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

final homeViewModelProvider = NotifierProvider<HomeViewModel, HomeState>(
  HomeViewModel.new,
);
