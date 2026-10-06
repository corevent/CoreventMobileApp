import 'package:freezed_annotation/freezed_annotation.dart';

import '../../events/data/event_dtos.dart';
import '../../events/domain/event_discovery_filter.dart';

part 'explore_state.freezed.dart';

@freezed
abstract class ExploreState with _$ExploreState {
  const factory ExploreState({
    @Default([]) List<EventSummary> events,
    @Default('') String search,
    String? category,
    @Default(EventDiscoveryFilter()) EventDiscoveryFilter discovery,
    @Default(0) int page,
    @Default(false) bool hasMore,
    @Default(true) bool loading,
    @Default(false) bool refreshing,
    @Default(false) bool loadingMore,
    String? error,
    String? refreshError,
    String? loadMoreError,
  }) = _ExploreState;
}
