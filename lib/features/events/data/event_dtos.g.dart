// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventPage _$EventPageFromJson(Map<String, dynamic> json) => EventPage(
  data: (json['data'] as List<dynamic>)
      .map((e) => EventSummary.fromJson(e as Map<String, dynamic>))
      .toList(),
  meta: EventPageMeta.fromJson(json['meta'] as Map<String, dynamic>),
);

EventPageMeta _$EventPageMetaFromJson(Map<String, dynamic> json) =>
    EventPageMeta(
      totalPages: _readInt(json['totalPages']),
      page: _readInt(json['currentPage']),
    );

EventOrganizer _$EventOrganizerFromJson(Map<String, dynamic> json) =>
    EventOrganizer(name: json['name'] as String? ?? '');

EventSummary _$EventSummaryFromJson(Map<String, dynamic> json) => EventSummary(
  id: json['id'] as String,
  title: json['title'] as String,
  startDate: DateTime.parse(json['startDate'] as String),
  endDate: DateTime.parse(json['endDate'] as String),
  category: json['category'] as String? ?? '',
  isAdultOnly: json['isAdultOnly'] as bool,
  locationName: json['locationName'] as String? ?? '',
  organizer: _readOrganizer(json['organizer']),
  locationType: json['locationType'] as String?,
  cityName: json['cityName'] as String?,
  stateAcronym: json['stateAcronym'] as String?,
  bannerUrl: json['bannerUrl'] as String?,
  favoriteId: json['favoriteId'] as String?,
  averageRating: json['averageRating'] == null
      ? 0
      : _readRating(json['averageRating']),
  ratingCount: _readRatingCount(json['ratingCount']),
);

EventDetail _$EventDetailFromJson(Map<String, dynamic> json) => EventDetail(
  id: json['id'] as String,
  title: json['title'] as String,
  startDate: DateTime.parse(json['startDate'] as String),
  endDate: DateTime.parse(json['endDate'] as String),
  category: json['category'] as String? ?? '',
  isAdultOnly: json['isAdultOnly'] as bool,
  locationName: json['locationName'] as String? ?? '',
  organizer: _readOrganizer(json['organizer']),
  description: json['description'] as String?,
  locationType: json['locationType'] as String?,
  cityName: json['cityName'] as String?,
  stateAcronym: json['stateAcronym'] as String?,
  bannerUrl: json['bannerUrl'] as String?,
  status: json['status'] as String?,
  averageRating: json['averageRating'] == null
      ? 0
      : _readRating(json['averageRating']),
  ratingCount: _readRatingCount(json['ratingCount']),
);

EventDetailResponse _$EventDetailResponseFromJson(Map<String, dynamic> json) =>
    EventDetailResponse(
      data: EventDetail.fromJson(json['data'] as Map<String, dynamic>),
    );
