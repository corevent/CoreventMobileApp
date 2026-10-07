// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FavoriteResponse _$FavoriteResponseFromJson(Map<String, dynamic> json) =>
    FavoriteResponse(
      FavoriteData.fromJson(json['data'] as Map<String, dynamic>),
    );

FavoriteData _$FavoriteDataFromJson(Map<String, dynamic> json) =>
    FavoriteData(json['id'] as String, json['eventId'] as String);
