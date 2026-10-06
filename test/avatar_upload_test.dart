import 'package:corevent_mobile_app/features/auth/data/auth_dtos.dart';
import 'package:corevent_mobile_app/features/auth/presentation/auth_session.dart';
import 'package:corevent_mobile_app/features/profile/data/avatar_api.dart';
import 'package:corevent_mobile_app/features/profile/data/avatar_repository.dart';
import 'package:corevent_mobile_app/features/profile/domain/avatar_image.dart';
import 'package:corevent_mobile_app/features/profile/presentation/avatar_view_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mocktail/mocktail.dart';

class MockAvatarApi extends Mock implements AvatarApi {}

class MockAvatarRepository extends Mock implements AvatarRepository {}

class MockSession extends Mock implements AuthSession {}

class UploadAdapter implements HttpClientAdapter {
  UploadAdapter({this.status = 200, this.response = ''});
  final int status;
  final String response;
  RequestOptions? request;
  Uint8List? body;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    body = Uint8List.fromList(await stream!.expand((chunk) => chunk).toList());
    return ResponseBody.fromString(response, status);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  const updated = UserProfile(
    id: 'u1',
    name: 'Ana',
    email: 'ana@example.com',
    avatarUrl: 'https://storage.test/avatar.jpg',
  );
  setUpAll(() {
    registerFallbackValue(Uint8List(1));
    registerFallbackValue((double progress) {});
    registerFallbackValue(updated);
  });

  test('upload usa bytes JPEG na URL assinada sem credencial da API', () async {
    final api = MockAvatarApi();
    final adapter = UploadAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    when(() => api.presign({'purpose': 'avatar', 'contentType': 'image/jpeg'}))
        .thenAnswer(
          (_) async => const AvatarUploadResponse(
            AvatarUpload(
              'https://storage.test/avatars/u1/foto.jpg?signature=abc',
              'avatars/u1/foto.jpg',
              'https://storage.test/foto.jpg',
              600,
            ),
          ),
        );
    final bytes = Uint8List.fromList([1, 2, 3]);
    final key = await AvatarRepository(api, dio).upload(bytes, (_) {});
    expect(key, 'avatars/u1/foto.jpg');
    expect(adapter.request!.uri.queryParameters['signature'], 'abc');
    expect(adapter.request!.headers['Authorization'], isNull);
    expect(adapter.request!.contentType, 'image/jpeg');
    expect(adapter.body, bytes);
    dio.close();
  });

  test('repetir confirmação não repete o upload', () async {
    final repository = MockAvatarRepository();
    final session = MockSession();
    final container = ProviderContainer(
      overrides: [
        avatarRepositoryProvider.overrideWithValue(repository),
        authSessionProvider.overrideWithValue(session),
      ],
    );
    addTearDown(container.dispose);
    when(() => repository.upload(any(), any())).thenAnswer((_) async => 'key');
    var attempts = 0;
    when(() => repository.confirm('key')).thenAnswer((_) async {
      if (++attempts == 1) throw Exception('offline');
      return updated;
    });
    final model = container.read(avatarViewModelProvider.notifier);
    final bytes = Uint8List(2);
    expect(await model.save(bytes), false);
    expect(container.read(avatarViewModelProvider).uploadedKey, 'key');
    expect(await model.save(bytes), true);
    verify(() => repository.upload(any(), any())).called(1);
    verify(() => repository.confirm('key')).called(2);
    verify(() => session.updateUser(updated)).called(1);
  });

  test(
    'falha do S3 mantém exceção e diagnóstico não expõe URL assinada',
    () async {
      final api = MockAvatarApi();
      final dio = Dio()
        ..httpClientAdapter = UploadAdapter(
          status: 400,
          response: '<Error><Code>BadDigest</Code><Message>checksum mismatch</Message></Error>',
        );
      addTearDown(dio.close);
      when(() => api.presign(any())).thenAnswer(
        (_) async => const AvatarUploadResponse(
          AvatarUpload(
            'https://storage.test/foto.jpg?secret=PRIVATE&x-amz-checksum-crc32=AAAAAA%3D%3D',
            'key',
            'https://storage.test/foto.jpg',
            600,
          ),
        ),
      );
      final logs = <String>[];
      final previous = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) logs.add(message);
      };
      addTearDown(() => debugPrint = previous);
      await expectLater(
        AvatarRepository(
          api,
          dio,
        ).upload(Uint8List.fromList([1, 2, 3]), (_) {}),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'status',
            400,
          ),
        ),
      );
      expect(logs.single, contains('[Avatar/upload]'));
      expect(logs.single, contains('s3Code=BadDigest'));
      expect(logs.single, contains('signedCRC32=empty'));
      expect(logs.single, isNot(contains('PRIVATE')));
      verifyNever(() => api.confirm(any()));
    },
  );

  test('valida imagem real e prepara avatar quadrado', () {
    expect(() => prepareAvatar(Uint8List(12)), throwsFormatException);
    final bytes = Uint8List.fromList(
      img.encodePng(img.Image(width: 40, height: 30)),
    );
    final prepared = prepareAvatar(bytes);
    expect(isSupportedAvatar(prepared), true);
    final avatar = img.decodeJpg(finishAvatar(prepared))!;
    expect(avatar.width, 512);
    expect(avatar.height, 512);
  });
}
