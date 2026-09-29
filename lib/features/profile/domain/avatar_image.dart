import 'dart:typed_data';

import 'package:image/image.dart' as img;

const maxAvatarSourceBytes = 10 * 1024 * 1024;

bool isSupportedAvatar(Uint8List bytes) =>
    bytes.length >= 12 &&
    ((bytes[0] == 0xff && bytes[1] == 0xd8) ||
        (bytes[0] == 0x89 &&
            bytes[1] == 0x50 &&
            bytes[2] == 0x4e &&
            bytes[3] == 0x47) ||
        (String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
            String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP'));

Uint8List prepareAvatar(Uint8List bytes) {
  if (bytes.length > maxAvatarSourceBytes) {
    throw const FormatException('Escolha uma imagem de até 10 MB.');
  }
  if (!isSupportedAvatar(bytes)) {
    throw const FormatException('Escolha uma foto JPEG, PNG ou WebP.');
  }
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw const FormatException('Não foi possível ler esta imagem.');
  }
  if (decoded.width * decoded.height > 24000000) {
    throw const FormatException(
      'A imagem é muito grande. Escolha uma foto menor.',
    );
  }
  final oriented = img.bakeOrientation(decoded);
  final resized = oriented.width > 1600 || oriented.height > 1600
      ? img.copyResize(
          oriented,
          width: oriented.width >= oriented.height ? 1600 : null,
          height: oriented.height > oriented.width ? 1600 : null,
        )
      : oriented;
  return Uint8List.fromList(img.encodeJpg(resized, quality: 90));
}

Uint8List finishAvatar(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw const FormatException('Não foi possível preparar a foto.');
  }
  return Uint8List.fromList(
    img.encodeJpg(
      img.copyResize(decoded, width: 512, height: 512),
      quality: 88,
    ),
  );
}
