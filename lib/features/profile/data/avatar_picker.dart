import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/avatar_image.dart';

class AvatarPicker {
  AvatarPicker(this.picker);
  final ImagePicker picker;
  Uint8List? recovered;

  Future<Uint8List?> pick() async {
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      requestFullMetadata: false,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    return file == null ? null : _read(file);
  }

  Future<bool> recover() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    final result = await picker.retrieveLostData();
    if (result.files?.isNotEmpty == true) {
      recovered = await _read(result.files!.first);
      return true;
    }
    return false;
  }

  Uint8List? takeRecovered() {
    final bytes = recovered;
    recovered = null;
    return bytes;
  }

  Future<Uint8List> _read(XFile file) async {
    if (await file.length() > maxAvatarSourceBytes) {
      throw const FormatException('Escolha uma imagem de até 10 MB.');
    }
    return file.readAsBytes();
  }
}

final avatarPickerProvider = Provider<AvatarPicker>(
  (ref) => AvatarPicker(ImagePicker()),
);
