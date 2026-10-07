// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$LoginRequestToJson(LoginRequest instance) =>
    <String, dynamic>{'email': instance.email, 'password': instance.password};

Map<String, dynamic> _$EmailRequestToJson(EmailRequest instance) =>
    <String, dynamic>{'email': instance.email};

Map<String, dynamic> _$RefreshRequestToJson(RefreshRequest instance) =>
    <String, dynamic>{'refreshToken': instance.refreshToken};

Map<String, dynamic> _$ResetPasswordRequestToJson(
  ResetPasswordRequest instance,
) => <String, dynamic>{
  'email': instance.email,
  'code': instance.code,
  'newPassword': instance.newPassword,
};

Map<String, dynamic> _$RegisterRequestToJson(RegisterRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'phoneNumber': instance.phoneNumber,
      'avatarUrl': instance.avatarUrl,
      'email': instance.email,
      'password': instance.password,
      'birthDate': instance.birthDate,
      'documentType': instance.documentType,
      'document': instance.document,
      'verifyEmailCode': instance.verifyEmailCode,
    };

MessageResponse _$MessageResponseFromJson(Map<String, dynamic> json) =>
    MessageResponse(json['message'] as String);

ProfileResponse _$ProfileResponseFromJson(Map<String, dynamic> json) =>
    ProfileResponse(UserProfile.fromJson(json['data'] as Map<String, dynamic>));

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => UserProfile(
  id: json['id'] as String,
  name: json['name'] as String,
  email: json['email'] as String,
  birthDate: json['birthDate'] as String?,
  createdAt: _optionalDate(json['createdAt']),
  phoneNumber: json['phoneNumber'] as String?,
  documentType: json['documentType'] as String?,
  document: json['document'] as String?,
  avatarUrl: json['avatarUrl'] as String?,
);
