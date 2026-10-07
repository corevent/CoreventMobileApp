import 'package:json_annotation/json_annotation.dart';

part 'rating_dtos.g.dart';

@JsonSerializable()
class RatingRequest {
  const RatingRequest(this.rating);
  final int rating;
  Map<String, dynamic> toJson() => _$RatingRequestToJson(this);
  factory RatingRequest.fromJson(Map<String, dynamic> json) =>
      _$RatingRequestFromJson(json);
}

@JsonSerializable(createToJson: false)
class RatingResponse {
  const RatingResponse(this.data);
  final RatingData data;
  factory RatingResponse.fromJson(Map<String, dynamic> json) =>
      _$RatingResponseFromJson(json);
}

@JsonSerializable(createToJson: false)
class RatingData {
  const RatingData(this.id, this.eventId, this.rating);
  final String id;
  final String eventId;
  final int rating;
  factory RatingData.fromJson(Map<String, dynamic> json) =>
      _$RatingDataFromJson(json);
}

@JsonSerializable(createToJson: false)
class RatedEvent {
  const RatedEvent({
    required this.eventId,
    required this.eventTitle,
    required this.userRating,
    this.averageRating = 0,
    this.ratingCount,
    this.bannerUrl,
    this.ratingId,
  });
  final String eventId;
  final String eventTitle;
  final int userRating;
  @JsonKey(fromJson: _average)
  final double averageRating;
  @JsonKey(fromJson: _count)
  final int? ratingCount;
  final String? bannerUrl;
  // Optional until the list endpoint exposes the identifier.
  final String? ratingId;
  RatedEvent withRating(int rating, String? id) => RatedEvent(
    eventId: eventId,
    eventTitle: eventTitle,
    userRating: rating,
    averageRating: averageRating,
    ratingCount: ratingCount,
    bannerUrl: bannerUrl,
    ratingId: id,
  );
  factory RatedEvent.fromJson(Map<String, dynamic> json) =>
      _$RatedEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class RatedEventPage {
  const RatedEventPage(this.data, this.meta);
  final List<RatedEvent> data;
  final RatingPageMeta meta;
  factory RatedEventPage.fromJson(Map<String, dynamic> json) =>
      _$RatedEventPageFromJson(json);
}

@JsonSerializable(createToJson: false)
class RatingPageMeta {
  const RatingPageMeta(this.currentPage, this.totalPages);
  final int currentPage;
  final int totalPages;
  factory RatingPageMeta.fromJson(Map<String, dynamic> json) =>
      _$RatingPageMetaFromJson(json);
}

double _average(Object? value) => switch (value) {
  final num value => value.toDouble(),
  final String value => double.tryParse(value) ?? 0,
  _ => 0,
};

int? _count(Object? value) {
  final count = value is int ? value : int.tryParse('$value');
  return count != null && count >= 0 ? count : null;
}
