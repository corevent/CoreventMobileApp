import 'package:freezed_annotation/freezed_annotation.dart';

import '../../events/data/event_dtos.dart';

part 'home_state.freezed.dart';

@freezed
abstract class HomeState with _$HomeState {
  const factory HomeState({
    @Default([]) List<EventSummary> events,
    @Default(0) int page,
    @Default(false) bool hasMore,
    @Default(true) bool loading,
    @Default(false) bool refreshing,
    @Default(false) bool loadingMore,
    String? error,
    String? refreshError,
    String? loadMoreError,
  }) = _HomeState;
}
