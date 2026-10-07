import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ticket_dtos.dart';
import '../data/tickets_repository.dart';

class TicketsState {
  const TicketsState({
    this.items = const [],
    this.page = 0,
    this.hasMore = false,
    this.loading = true,
    this.refreshing = false,
    this.loadingMore = false,
    this.error,
    this.refreshError,
    this.loadMoreError,
  });

  final List<UserTicket> items;
  final int page;
  final bool hasMore;
  final bool loading;
  final bool refreshing;
  final bool loadingMore;
  final String? error;
  final String? refreshError;
  final String? loadMoreError;

  TicketsState copyWith({
    List<UserTicket>? items,
    int? page,
    bool? hasMore,
    bool? loading,
    bool? refreshing,
    bool? loadingMore,
    String? error,
    String? refreshError,
    String? loadMoreError,
  }) => TicketsState(
    items: items ?? this.items,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    loading: loading ?? this.loading,
    refreshing: refreshing ?? this.refreshing,
    loadingMore: loadingMore ?? this.loadingMore,
    error: error,
    refreshError: refreshError,
    loadMoreError: loadMoreError,
  );
}

class TicketsViewModel extends Notifier<TicketsState> {
  int _generation = 0;

  @override
  TicketsState build() {
    ref.onDispose(() => _generation++);
    return const TicketsState();
  }

  Future<void> load() async {
    final generation = ++_generation;
    state = state.copyWith(loading: true);
    try {
      final result = await ref.read(ticketsRepositoryProvider).list(page: 1);
      if (!ref.mounted || generation != _generation) return;
      state = TicketsState(
        items: _unique(result.data),
        page: 1,
        hasMore: result.meta.totalPages > 1,
        loading: false,
      );
    } catch (_) {
      if (!ref.mounted || generation != _generation) return;
      state = const TicketsState(
        loading: false,
        error: 'Não foi possível carregar seus ingressos.',
      );
    }
  }

  Future<void> refresh() async {
    final generation = ++_generation;
    state = state.copyWith(refreshing: true);
    try {
      final result = await ref.read(ticketsRepositoryProvider).list(page: 1);
      if (!ref.mounted || generation != _generation) return;
      state = TicketsState(
        items: _unique(result.data),
        page: 1,
        hasMore: result.meta.totalPages > 1,
        loading: false,
      );
    } catch (_) {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(
        refreshing: false,
        refreshError: 'Não foi possível atualizar seus ingressos.',
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
    state = state.copyWith(loadingMore: true);
    try {
      final result = await ref
          .read(ticketsRepositoryProvider)
          .list(page: nextPage);
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(
        items: _unique([...state.items, ...result.data]),
        page: nextPage,
        hasMore: nextPage < result.meta.totalPages,
        loadingMore: false,
      );
    } catch (_) {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(
        loadingMore: false,
        loadMoreError: 'Não foi possível carregar mais ingressos.',
      );
    }
  }

  List<UserTicket> _unique(Iterable<UserTicket> tickets) =>
      {for (final ticket in tickets) ticket.id: ticket}.values.toList();
}

final ticketsViewModelProvider =
    NotifierProvider<TicketsViewModel, TicketsState>(TicketsViewModel.new);
