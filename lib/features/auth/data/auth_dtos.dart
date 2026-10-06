import 'package:json_annotation/json_annotation.dart';

part 'auth_dtos.g.dart';

@JsonSerializable(createFactory: false)
class LoginRequest {
  const LoginRequest(this.email, this.password);
  final String email;
  final String password;
  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

@JsonSerializable(createFactory: false)
class EmailRequest {
  const EmailRequest(this.email);
  final String email;
  Map<String, dynamic> toJson() => _$EmailRequestToJson(this);
}

@JsonSerializable(createFactory: false)
class RefreshRequest {
  const RefreshRequest(this.refreshToken);
  final String refreshToken;
  Map<String, dynamic> toJson() => _$RefreshRequestToJson(this);
}

@JsonSerializable(createFactory: false)
class ResetPasswordRequest {
  const ResetPasswordRequest(this.email, this.code, this.newPassword);
  final String email;
  final String code;
  final String newPassword;
  Map<String, dynamic> toJson() => _$ResetPasswordRequestToJson(this);
}

@JsonSerializable(createFactory: false)
class RegisterRequest {
  const RegisterRequest({
    required this.name,
    required this.phoneNumber,
    required this.avatarUrl,
    required this.email,
    required this.password,
    required this.birthDate,
    required this.documentType,
    required this.document,
    required this.verifyEmailCode,
  });

  final String name;
  final String phoneNumber;
  final String avatarUrl;
  final String email;
  final String password;
  final String birthDate;
  final String documentType;
  final String document;
  final String verifyEmailCode;
  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);
}

@JsonSerializable(createToJson: false)
class MessageResponse {
  const MessageResponse(this.message);
  final String message;
  factory MessageResponse.fromJson(Map<String, dynamic> json) =>
      _$MessageResponseFromJson(json);
}

@JsonSerializable(createToJson: false)
class ProfileResponse {
  const ProfileResponse(this.data);
  final UserProfile data;
  factory ProfileResponse.fromJson(Map<String, dynamic> json) =>
      _$ProfileResponseFromJson(json);
}

@JsonSerializable(createToJson: false)
class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.birthDate,
    this.createdAt,
    this.phoneNumber,
    this.documentType,
    this.document,
    this.avatarUrl,
  });
  final String id;
  final String name;
  final String email;
  final String? birthDate;
  @JsonKey(fromJson: _optionalDate)
  final DateTime? createdAt;
  final String? phoneNumber;
  final String? documentType;
  final String? document;
  final String? avatarUrl;
  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}

DateTime? _optionalDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
