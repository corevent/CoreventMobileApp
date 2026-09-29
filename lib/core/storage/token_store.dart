import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'storage_providers.dart';

class TokenStore extends ChangeNotifier {
  TokenStore(this._storage);

  static const accessKey = 'access_token';
  static const refreshKey = 'refresh_token';

  final FlutterSecureStorage _storage;

  Future<String?> readAccess() => _storage.read(key: accessKey);
  Future<String?> readRefresh() => _storage.read(key: refreshKey);

  Future<void> save(String access, String refresh) async {
    await _storage.write(key: accessKey, value: access);
    await _storage.write(key: refreshKey, value: refresh);
    notifyListeners();
  }

  Future<void> clear() async {
    await _storage.delete(key: accessKey);
    await _storage.delete(key: refreshKey);
    notifyListeners();
  }
}

final tokenStoreProvider = Provider<TokenStore>((ref) {
  final store = TokenStore(ref.watch(secureStorageProvider));
  ref.onDispose(store.dispose);
  return store;
});
