// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rating_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RatingRequest _$RatingRequestFromJson(Map<String, dynamic> json) =>
    RatingRequest((json['rating'] as num).toInt());

Map<String, dynamic> _$RatingRequestToJson(RatingRequest instance) =>
    <String, dynamic>{'rating': instance.rating};

RatingResponse _$RatingResponseFromJson(Map<String, dynamic> json) =>
    RatingResponse(RatingData.fromJson(json['data'] as Map<String, dynamic>));

RatingData _$RatingDataFromJson(Map<String, dynamic> json) => RatingData(
  json['id'] as String,
  json['eventId'] as String,
  (json['rating'] as num).toInt(),
);

RatedEvent _$RatedEventFromJson(Map<String, dynamic> json) => RatedEvent(
  eventId: json['eventId'] as String,
  eventTitle: json['eventTitle'] as String,
  userRating: (json['userRating'] as num).toInt(),
  averageRating: json['averageRating'] == null
      ? 0
      : _average(json['averageRating']),
  ratingCount: _count(json['ratingCount']),
  bannerUrl: json['bannerUrl'] as String?,
  ratingId: json['ratingId'] as String?,
);

RatedEventPage _$RatedEventPageFromJson(Map<String, dynamic> json) =>
    RatedEventPage(
      (json['data'] as List<dynamic>)
          .map((e) => RatedEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      RatingPageMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );

RatingPageMeta _$RatingPageMetaFromJson(Map<String, dynamic> json) =>
    RatingPageMeta(
      (json['currentPage'] as num).toInt(),
      (json['totalPages'] as num).toInt(),
    );
