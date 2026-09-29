import 'package:dio/dio.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:retrofit/retrofit.dart';

import '../../auth/data/auth_dtos.dart';

part 'avatar_api.g.dart';

@RestApi()
abstract class AvatarApi {
  factory AvatarApi(Dio dio, {String? baseUrl}) = _AvatarApi;

  @POST('/api/storage/presign')
  Future<AvatarUploadResponse> presign(@Body() Map<String, dynamic> body);

  @PATCH('/api/users/me/avatar')
  Future<ProfileResponse> confirm(@Body() Map<String, dynamic> body);
}

@JsonSerializable(createToJson: false)
class AvatarUploadResponse {
  const AvatarUploadResponse(this.data);
  final AvatarUpload data;
  factory AvatarUploadResponse.fromJson(Map<String, dynamic> json) =>
      _$AvatarUploadResponseFromJson(json);
}

@JsonSerializable(createToJson: false)
class AvatarUpload {
  const AvatarUpload(this.uploadUrl, this.key, this.publicUrl, this.expiresIn);
  final String uploadUrl;
  final String key;
  final String publicUrl;
  final int expiresIn;
  factory AvatarUpload.fromJson(Map<String, dynamic> json) =>
      _$AvatarUploadFromJson(json);
}
