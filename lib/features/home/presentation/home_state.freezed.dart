// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HomeState {

 List<EventSummary> get events; int get page; bool get hasMore; bool get loading; bool get refreshing; bool get loadingMore; String? get error; String? get refreshError; String? get loadMoreError;
/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeStateCopyWith<HomeState> get copyWith => _$HomeStateCopyWithImpl<HomeState>(this as HomeState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as HomeState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeState&&const DeepCollectionEquality().equals(other.events, _this.events)&&(identical(other.page, _this.page) || other.page == _this.page)&&(identical(other.hasMore, _this.hasMore) || other.hasMore == _this.hasMore)&&(identical(other.loading, _this.loading) || other.loading == _this.loading)&&(identical(other.refreshing, _this.refreshing) || other.refreshing == _this.refreshing)&&(identical(other.loadingMore, _this.loadingMore) || other.loadingMore == _this.loadingMore)&&(identical(other.error, _this.error) || other.error == _this.error)&&(identical(other.refreshError, _this.refreshError) || other.refreshError == _this.refreshError)&&(identical(other.loadMoreError, _this.loadMoreError) || other.loadMoreError == _this.loadMoreError));
}


@override
int get hashCode {
  final _this = this as HomeState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.events),_this.page,_this.hasMore,_this.loading,_this.refreshing,_this.loadingMore,_this.error,_this.refreshError,_this.loadMoreError);
}

@override
String toString() {
  final _this = this as HomeState;
  return 'HomeState(events: ${_this.events}, page: ${_this.page}, hasMore: ${_this.hasMore}, loading: ${_this.loading}, refreshing: ${_this.refreshing}, loadingMore: ${_this.loadingMore}, error: ${_this.error}, refreshError: ${_this.refreshError}, loadMoreError: ${_this.loadMoreError})';
}


}

/// @nodoc
abstract mixin class $HomeStateCopyWith<$Res>  {
  factory $HomeStateCopyWith(HomeState value, $Res Function(HomeState) _then) = _$HomeStateCopyWithImpl;
@useResult
$Res call({
 List<EventSummary> events, int page, bool hasMore, bool loading, bool refreshing, bool loadingMore, String? error, String? refreshError, String? loadMoreError
});




}
/// @nodoc
class _$HomeStateCopyWithImpl<$Res>
    implements $HomeStateCopyWith<$Res> {
  _$HomeStateCopyWithImpl(this._self, this._then);

  final HomeState _self;
  final $Res Function(HomeState) _then;

/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? events = null,Object? page = null,Object? hasMore = null,Object? loading = null,Object? refreshing = null,Object? loadingMore = null,Object? error = freezed,Object? refreshError = freezed,Object? loadMoreError = freezed,}) {
  return _then(HomeState(
events: null == events ? _self.events : events // ignore: cast_nullable_to_non_nullable
as List<EventSummary>,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
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


/// Adds pattern-matching-related methods to [HomeState].
extension HomeStatePatterns on HomeState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HomeState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HomeState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HomeState value)  $default,){
final _that = this;
switch (_that) {
case _HomeState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HomeState value)?  $default,){
final _that = this;
switch (_that) {
case _HomeState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<EventSummary> events,  int page,  bool hasMore,  bool loading,  bool refreshing,  bool loadingMore,  String? error,  String? refreshError,  String? loadMoreError)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HomeState() when $default != null:
return $default(_that.events,_that.page,_that.hasMore,_that.loading,_that.refreshing,_that.loadingMore,_that.error,_that.refreshError,_that.loadMoreError);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<EventSummary> events,  int page,  bool hasMore,  bool loading,  bool refreshing,  bool loadingMore,  String? error,  String? refreshError,  String? loadMoreError)  $default,) {final _that = this;
switch (_that) {
case _HomeState():
return $default(_that.events,_that.page,_that.hasMore,_that.loading,_that.refreshing,_that.loadingMore,_that.error,_that.refreshError,_that.loadMoreError);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<EventSummary> events,  int page,  bool hasMore,  bool loading,  bool refreshing,  bool loadingMore,  String? error,  String? refreshError,  String? loadMoreError)?  $default,) {final _that = this;
switch (_that) {
case _HomeState() when $default != null:
return $default(_that.events,_that.page,_that.hasMore,_that.loading,_that.refreshing,_that.loadingMore,_that.error,_that.refreshError,_that.loadMoreError);case _:
  return null;

}
}

}

/// @nodoc


class _HomeState implements HomeState {
  const _HomeState({ List<EventSummary> events = const [], this.page = 0, this.hasMore = false, this.loading = true, this.refreshing = false, this.loadingMore = false, this.error, this.refreshError, this.loadMoreError}): _events = events;
  

 final  List<EventSummary> _events;
@override@JsonKey() List<EventSummary> get events {
  if (_events is EqualUnmodifiableListView) return _events;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_events);
}

@override@JsonKey() final  int page;
@override@JsonKey() final  bool hasMore;
@override@JsonKey() final  bool loading;
@override@JsonKey() final  bool refreshing;
@override@JsonKey() final  bool loadingMore;
@override final  String? error;
@override final  String? refreshError;
@override final  String? loadMoreError;

/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HomeStateCopyWith<_HomeState> get copyWith => __$HomeStateCopyWithImpl<_HomeState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HomeState&&const DeepCollectionEquality().equals(other.events, _events)&&(identical(other.page, page) || other.page == page)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.refreshing, refreshing) || other.refreshing == refreshing)&&(identical(other.loadingMore, loadingMore) || other.loadingMore == loadingMore)&&(identical(other.error, error) || other.error == error)&&(identical(other.refreshError, refreshError) || other.refreshError == refreshError)&&(identical(other.loadMoreError, loadMoreError) || other.loadMoreError == loadMoreError));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_events),page,hasMore,loading,refreshing,loadingMore,error,refreshError,loadMoreError);
}

@override
String toString() {
    return 'HomeState(events: $events, page: $page, hasMore: $hasMore, loading: $loading, refreshing: $refreshing, loadingMore: $loadingMore, error: $error, refreshError: $refreshError, loadMoreError: $loadMoreError)';
}


}

/// @nodoc
abstract mixin class _$HomeStateCopyWith<$Res> implements $HomeStateCopyWith<$Res> {
  factory _$HomeStateCopyWith(_HomeState value, $Res Function(_HomeState) _then) = __$HomeStateCopyWithImpl;
@override @useResult
$Res call({
 List<EventSummary> events, int page, bool hasMore, bool loading, bool refreshing, bool loadingMore, String? error, String? refreshError, String? loadMoreError
});




}
/// @nodoc
class __$HomeStateCopyWithImpl<$Res>
    implements _$HomeStateCopyWith<$Res> {
  __$HomeStateCopyWithImpl(this._self, this._then);

  final _HomeState _self;
  final $Res Function(_HomeState) _then;

/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? events = null,Object? page = null,Object? hasMore = null,Object? loading = null,Object? refreshing = null,Object? loadingMore = null,Object? error = freezed,Object? refreshError = freezed,Object? loadMoreError = freezed,}) {
  return _then(_HomeState(
events: null == events ? _self._events : events // ignore: cast_nullable_to_non_nullable
as List<EventSummary>,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
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
