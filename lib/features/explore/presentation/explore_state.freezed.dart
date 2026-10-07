// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'explore_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ExploreState {

 List<EventSummary> get events; String get search; String? get category; EventDiscoveryFilter get discovery; int get page; bool get hasMore; bool get loading; bool get refreshing; bool get loadingMore; String? get error; String? get refreshError; String? get loadMoreError;
/// Create a copy of ExploreState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExploreStateCopyWith<ExploreState> get copyWith => _$ExploreStateCopyWithImpl<ExploreState>(this as ExploreState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ExploreState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExploreState&&const DeepCollectionEquality().equals(other.events, _this.events)&&(identical(other.search, _this.search) || other.search == _this.search)&&(identical(other.category, _this.category) || other.category == _this.category)&&(identical(other.discovery, _this.discovery) || other.discovery == _this.discovery)&&(identical(other.page, _this.page) || other.page == _this.page)&&(identical(other.hasMore, _this.hasMore) || other.hasMore == _this.hasMore)&&(identical(other.loading, _this.loading) || other.loading == _this.loading)&&(identical(other.refreshing, _this.refreshing) || other.refreshing == _this.refreshing)&&(identical(other.loadingMore, _this.loadingMore) || other.loadingMore == _this.loadingMore)&&(identical(other.error, _this.error) || other.error == _this.error)&&(identical(other.refreshError, _this.refreshError) || other.refreshError == _this.refreshError)&&(identical(other.loadMoreError, _this.loadMoreError) || other.loadMoreError == _this.loadMoreError));
}


@override
int get hashCode {
  final _this = this as ExploreState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.events),_this.search,_this.category,_this.discovery,_this.page,_this.hasMore,_this.loading,_this.refreshing,_this.loadingMore,_this.error,_this.refreshError,_this.loadMoreError);
}

@override
String toString() {
  final _this = this as ExploreState;
  return 'ExploreState(events: ${_this.events}, search: ${_this.search}, category: ${_this.category}, discovery: ${_this.discovery}, page: ${_this.page}, hasMore: ${_this.hasMore}, loading: ${_this.loading}, refreshing: ${_this.refreshing}, loadingMore: ${_this.loadingMore}, error: ${_this.error}, refreshError: ${_this.refreshError}, loadMoreError: ${_this.loadMoreError})';
}


}

/// @nodoc
abstract mixin class $ExploreStateCopyWith<$Res>  {
  factory $ExploreStateCopyWith(ExploreState value, $Res Function(ExploreState) _then) = _$ExploreStateCopyWithImpl;
@useResult
$Res call({
 List<EventSummary> events, String search, String? category, EventDiscoveryFilter discovery, int page, bool hasMore, bool loading, bool refreshing, bool loadingMore, String? error, String? refreshError, String? loadMoreError
});




}
/// @nodoc
class _$ExploreStateCopyWithImpl<$Res>
    implements $ExploreStateCopyWith<$Res> {
  _$ExploreStateCopyWithImpl(this._self, this._then);

  final ExploreState _self;
  final $Res Function(ExploreState) _then;

/// Create a copy of ExploreState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? events = null,Object? search = null,Object? category = freezed,Object? discovery = null,Object? page = null,Object? hasMore = null,Object? loading = null,Object? refreshing = null,Object? loadingMore = null,Object? error = freezed,Object? refreshError = freezed,Object? loadMoreError = freezed,}) {
  return _then(ExploreState(
events: null == events ? _self.events : events // ignore: cast_nullable_to_non_nullable
as List<EventSummary>,search: null == search ? _self.search : search // ignore: cast_nullable_to_non_nullable
as String,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,discovery: null == discovery ? _self.discovery : discovery // ignore: cast_nullable_to_non_nullable
as EventDiscoveryFilter,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,refreshing: null == refreshing ? _self.refreshing : refreshing // ignore: cast_nullable_to_non_nullable
as bool,loadingMore: null == loadingMore ? _self.loadingMore : loadingMore // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,refreshError: freezed == refreshError ? _self.refreshError : refreshError // ignore: cast_nullable_to_non_nullable
as String?,loadMoreError: freezed == loadMoreError ? _self.loadMoreError : loadMoreError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ExploreState].
extension ExploreStatePatterns on ExploreState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExploreState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExploreState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExploreState value)  $default,){
final _that = this;
switch (_that) {
case _ExploreState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExploreState value)?  $default,){
final _that = this;
switch (_that) {
case _ExploreState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<EventSummary> events,  String search,  String? category,  EventDiscoveryFilter discovery,  int page,  bool hasMore,  bool loading,  bool refreshing,  bool loadingMore,  String? error,  String? refreshError,  String? loadMoreError)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExploreState() when $default != null:
return $default(_that.events,_that.search,_that.category,_that.discovery,_that.page,_that.hasMore,_that.loading,_that.refreshing,_that.loadingMore,_that.error,_that.refreshError,_that.loadMoreError);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<EventSummary> events,  String search,  String? category,  EventDiscoveryFilter discovery,  int page,  bool hasMore,  bool loading,  bool refreshing,  bool loadingMore,  String? error,  String? refreshError,  String? loadMoreError)  $default,) {final _that = this;
switch (_that) {
case _ExploreState():
return $default(_that.events,_that.search,_that.category,_that.discovery,_that.page,_that.hasMore,_that.loading,_that.refreshing,_that.loadingMore,_that.error,_that.refreshError,_that.loadMoreError);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<EventSummary> events,  String search,  String? category,  EventDiscoveryFilter discovery,  int page,  bool hasMore,  bool loading,  bool refreshing,  bool loadingMore,  String? error,  String? refreshError,  String? loadMoreError)?  $default,) {final _that = this;
switch (_that) {
case _ExploreState() when $default != null:
return $default(_that.events,_that.search,_that.category,_that.discovery,_that.page,_that.hasMore,_that.loading,_that.refreshing,_that.loadingMore,_that.error,_that.refreshError,_that.loadMoreError);case _:
  return null;

}
}

}

/// @nodoc


class _ExploreState implements ExploreState {
  const _ExploreState({ List<EventSummary> events = const [], this.search = '', this.category, this.discovery = const EventDiscoveryFilter(), this.page = 0, this.hasMore = false, this.loading = true, this.refreshing = false, this.loadingMore = false, this.error, this.refreshError, this.loadMoreError}): _events = events;
  

 final  List<EventSummary> _events;
@override@JsonKey() List<EventSummary> get events {
  if (_events is EqualUnmodifiableListView) return _events;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_events);
}

@override@JsonKey() final  String search;
@override final  String? category;
@override@JsonKey() final  EventDiscoveryFilter discovery;
@override@JsonKey() final  int page;
@override@JsonKey() final  bool hasMore;
@override@JsonKey() final  bool loading;
@override@JsonKey() final  bool refreshing;
@override@JsonKey() final  bool loadingMore;
@override final  String? error;
@override final  String? refreshError;
@override final  String? loadMoreError;

/// Create a copy of ExploreState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExploreStateCopyWith<_ExploreState> get copyWith => __$ExploreStateCopyWithImpl<_ExploreState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExploreState&&const DeepCollectionEquality().equals(other.events, _events)&&(identical(other.search, search) || other.search == search)&&(identical(other.category, category) || other.category == category)&&(identical(other.discovery, discovery) || other.discovery == discovery)&&(identical(other.page, page) || other.page == page)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.refreshing, refreshing) || other.refreshing == refreshing)&&(identical(other.loadingMore, loadingMore) || other.loadingMore == loadingMore)&&(identical(other.error, error) || other.error == error)&&(identical(other.refreshError, refreshError) || other.refreshError == refreshError)&&(identical(other.loadMoreError, loadMoreError) || other.loadMoreError == loadMoreError));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_events),search,category,discovery,page,hasMore,loading,refreshing,loadingMore,error,refreshError,loadMoreError);
}

@override
String toString() {
    return 'ExploreState(events: $events, search: $search, category: $category, discovery: $discovery, page: $page, hasMore: $hasMore, loading: $loading, refreshing: $refreshing, loadingMore: $loadingMore, error: $error, refreshError: $refreshError, loadMoreError: $loadMoreError)';
}


}

/// @nodoc
abstract mixin class _$ExploreStateCopyWith<$Res> implements $ExploreStateCopyWith<$Res> {
  factory _$ExploreStateCopyWith(_ExploreState value, $Res Function(_ExploreState) _then) = __$ExploreStateCopyWithImpl;
@override @useResult
$Res call({
 List<EventSummary> events, String search, String? category, EventDiscoveryFilter discovery, int page, bool hasMore, bool loading, bool refreshing, bool loadingMore, String? error, String? refreshError, String? loadMoreError
});




}
/// @nodoc
class __$ExploreStateCopyWithImpl<$Res>
    implements _$ExploreStateCopyWith<$Res> {
  __$ExploreStateCopyWithImpl(this._self, this._then);

  final _ExploreState _self;
  final $Res Function(_ExploreState) _then;

/// Create a copy of ExploreState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? events = null,Object? search = null,Object? category = freezed,Object? discovery = null,Object? page = null,Object? hasMore = null,Object? loading = null,Object? refreshing = null,Object? loadingMore = null,Object? error = freezed,Object? refreshError = freezed,Object? loadMoreError = freezed,}) {
  return _then(_ExploreState(
events: null == events ? _self._events : events // ignore: cast_nullable_to_non_nullable
as List<EventSummary>,search: null == search ? _self.search : search // ignore: cast_nullable_to_non_nullable
as String,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,discovery: null == discovery ? _self.discovery : discovery // ignore: cast_nullable_to_non_nullable
as EventDiscoveryFilter,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,refreshing: null == refreshing ? _self.refreshing : refreshing // ignore: cast_nullable_to_non_nullable
as bool,loadingMore: null == loadingMore ? _self.loadingMore : loadingMore // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,refreshError: freezed == refreshError ? _self.refreshError : refreshError // ignore: cast_nullable_to_non_nullable
as String?,loadMoreError: freezed == loadMoreError ? _self.loadMoreError : loadMoreError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
