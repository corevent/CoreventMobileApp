import 'package:json_annotation/json_annotation.dart';

part 'favorite_dtos.g.dart';

@JsonSerializable(createToJson: false)
class FavoriteResponse {
  const FavoriteResponse(this.data);
  final FavoriteData data;
  factory FavoriteResponse.fromJson(Map<String, dynamic> json) =>
      _$FavoriteResponseFromJson(json);
}

@JsonSerializable(createToJson: false)
class FavoriteData {
  const FavoriteData(this.id, this.eventId);
  final String id;
  final String eventId;
  factory FavoriteData.fromJson(Map<String, dynamic> json) =>
      _$FavoriteDataFromJson(json);
}
