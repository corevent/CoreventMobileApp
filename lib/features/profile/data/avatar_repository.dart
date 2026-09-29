import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_dtos.dart';
import '../../auth/data/auth_providers.dart';
import 'avatar_api.dart';

class AvatarRepository {
  const AvatarRepository(this.api, this.uploadDio);
  final AvatarApi api;
  final Dio uploadDio;

  Future<String> upload(
    Uint8List bytes,
    void Function(double) onProgress,
  ) async {
    var stage = 'presign';
    try {
      final upload = (await api.presign({
        'purpose': 'avatar',
        'contentType': 'image/jpeg',
      })).data;
      final url = Uri.tryParse(upload.uploadUrl);
      if (url == null ||
          !url.hasAuthority ||
          !{'http', 'https'}.contains(url.scheme)) {
        throw const FormatException('URL de envio inválida.');
      }
      stage = 'upload';
      await uploadDio.put<void>(
        upload.uploadUrl,
        data: bytes,
        options: Options(
          contentType: 'image/jpeg',
          responseType: ResponseType.plain,
        ),
        onSendProgress: (sent, total) {
          if (total > 0) onProgress(sent / total);
        },
      );
      return upload.key;
    } catch (error) {
      _logFailure(stage, error);
      rethrow;
    }
  }

  Future<UserProfile> confirm(String key) async {
    try {
      return (await api.confirm({'key': key})).data;
    } catch (error) {
      _logFailure('confirm', error);
      rethrow;
    }
  }

  // Evita imprimir tokens e os parâmetros da URL assinada no console.
  void _logFailure(String stage, Object error) {
    if (!kDebugMode) return;
    if (error is DioException) {
      final data = error.response?.data;
      final s3Code = data is String
          ? RegExp(r'<Code>([A-Za-z0-9]+)</Code>').firstMatch(data)?.group(1)
          : null;
      final emptyChecksum =
          stage == 'upload' &&
          error.requestOptions.uri.queryParameters['x-amz-checksum-crc32'] ==
              'AAAAAA==';
      debugPrint(
        '[Avatar/$stage] type=${error.type.name} '
        'http=${error.response?.statusCode ?? "sem resposta"} '
        's3Code=${s3Code ?? "não informado"}'
        '${emptyChecksum ? " signedCRC32=empty" : ""}',
      );
    } else {
      debugPrint('[Avatar/$stage] exception=${error.runtimeType}');
    }
  }
}

// O PUT vai para o storage e não pode levar o Bearer token da API.
final avatarUploadDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  ref.onDispose(() => dio.close(force: true));
  return dio;
});

final avatarRepositoryProvider = Provider<AvatarRepository>(
  (ref) => AvatarRepository(
    AvatarApi(ref.watch(authorizedDioProvider)),
    ref.watch(avatarUploadDioProvider),
  ),
);
