import 'package:json_annotation/json_annotation.dart';

part 'event_dtos.g.dart';

@JsonSerializable(createToJson: false)
class EventPage {
  const EventPage({required this.data, required this.meta});

  final List<EventSummary> data;
  final EventPageMeta meta;

  factory EventPage.fromJson(Map<String, dynamic> json) =>
      _$EventPageFromJson(json);
}

@JsonSerializable(createToJson: false)
class EventPageMeta {
  const EventPageMeta({required this.totalPages, required this.page});

  @JsonKey(fromJson: _readInt)
  final int totalPages;
  @JsonKey(name: 'currentPage', fromJson: _readInt)
  final int page;

  factory EventPageMeta.fromJson(Map<String, dynamic> json) =>
      _$EventPageMetaFromJson(json);
}

@JsonSerializable(createToJson: false)
class EventOrganizer {
  const EventOrganizer({required this.name});

  @JsonKey(defaultValue: '')
  final String name;

  factory EventOrganizer.fromJson(Map<String, dynamic> json) =>
      _$EventOrganizerFromJson(json);
}

@JsonSerializable(createToJson: false)
class EventSummary {
  const EventSummary({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.category,
    required this.isAdultOnly,
    required this.locationName,
    required this.organizer,
    this.locationType,
    this.cityName,
    this.stateAcronym,
    this.bannerUrl,
    this.favoriteId,
    this.averageRating = 0,
    this.ratingCount,
  });

  final String id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  @JsonKey(defaultValue: '')
  final String category;
  final bool isAdultOnly;
  @JsonKey(defaultValue: '')
  final String locationName;
  @JsonKey(fromJson: _readOrganizer)
  final EventOrganizer organizer;
  final String? locationType;
  final String? cityName;
  final String? stateAcronym;
  final String? bannerUrl;
  final String? favoriteId;
  @JsonKey(fromJson: _readRating)
  final double averageRating;
  // Optional: the current API exposes the average but not the total.
  @JsonKey(fromJson: _readRatingCount)
  final int? ratingCount;

  factory EventSummary.fromJson(Map<String, dynamic> json) =>
      _$EventSummaryFromJson(json);
}

@JsonSerializable(createToJson: false)
class EventDetail {
  const EventDetail({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.category,
    required this.isAdultOnly,
    required this.locationName,
    required this.organizer,
    this.description,
    this.locationType,
    this.cityName,
    this.stateAcronym,
    this.bannerUrl,
    this.status,
    this.averageRating = 0,
    this.ratingCount,
  });

  final String id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  @JsonKey(defaultValue: '')
  final String category;
  final bool isAdultOnly;
  @JsonKey(defaultValue: '')
  final String locationName;
  @JsonKey(fromJson: _readOrganizer)
  final EventOrganizer organizer;
  final String? description;
  final String? locationType;
  final String? cityName;
  final String? stateAcronym;
  final String? bannerUrl;
  final String? status;
  @JsonKey(fromJson: _readRating)
  final double averageRating;
  @JsonKey(fromJson: _readRatingCount)
  final int? ratingCount;

  factory EventDetail.fromJson(Map<String, dynamic> json) =>
      _$EventDetailFromJson(json);
}

@JsonSerializable(createToJson: false)
class EventDetailResponse {
  const EventDetailResponse({required this.data});

  final EventDetail data;

  factory EventDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$EventDetailResponseFromJson(json);
}

int _readInt(Object? value) => switch (value) {
  final int number => number,
  final num number => number.toInt(),
  final String text => int.parse(text),
  _ => throw FormatException('Valor numérico de paginação inválido: $value'),
};

double _readRating(Object? value) => switch (value) {
  final num number => number.toDouble(),
  final String text => double.tryParse(text) ?? 0,
  _ => 0,
};

int? _readRatingCount(Object? value) {
  final count = value is int ? value : int.tryParse('$value');
  return count != null && count >= 0 ? count : null;
}

EventOrganizer _readOrganizer(Object? value) => value is Map
    ? EventOrganizer.fromJson(Map<String, dynamic>.from(value))
    : const EventOrganizer(name: 'Organizador');
