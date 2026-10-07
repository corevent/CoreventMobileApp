import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../../core/network/auth_tokens.dart';
import 'auth_dtos.dart';

part 'auth_api.g.dart';

@RestApi()
abstract class AuthApi {
  factory AuthApi(Dio dio, {String? baseUrl}) = _AuthApi;

  @POST('/api/auth/login')
  Future<AuthTokens> login(@Body() LoginRequest request);

  @POST('/api/auth/verify-email')
  Future<MessageResponse> verifyEmail(@Body() EmailRequest request);

  @POST('/api/auth/register')
  Future<void> register(@Body() RegisterRequest request);

  @POST('/api/auth/forgot-password')
  Future<MessageResponse> forgotPassword(@Body() EmailRequest request);

  @POST('/api/auth/reset-password')
  Future<MessageResponse> resetPassword(@Body() ResetPasswordRequest request);

  @POST('/api/auth/refresh')
  Future<AuthTokens> refresh(@Body() RefreshRequest request);

  @POST('/api/auth/logout')
  Future<void> logout(@Body() RefreshRequest request);
}

@RestApi()
abstract class ProfileApi {
  factory ProfileApi(Dio dio, {String? baseUrl}) = _ProfileApi;

  @GET('/api/users/me')
  Future<ProfileResponse> me();

  @PATCH('/api/users')
  Future<ProfileResponse> update(@Body() Map<String, dynamic> body);

  @PATCH('/api/users/pass')
  Future<MessageResponse> changePassword(@Body() Map<String, dynamic> body);
}
