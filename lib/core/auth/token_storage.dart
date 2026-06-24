import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'token_storage_web.dart' if (dart.library.io) 'token_storage_stub.dart'
    as platform;

final tokenStorageProvider =
    Provider<TokenStorage>((_) => const TokenStorage());

class TokenStorage {
  const TokenStorage();

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<String?> getAccessToken() async {
    if (kIsWeb) return platform.read(_accessKey);
    return _secureStorage.read(key: _accessKey);
  }

  Future<String?> getRefreshToken() async {
    if (kIsWeb) return platform.read(_refreshKey);
    return _secureStorage.read(key: _refreshKey);
  }

  Future<void> save({
    required String access,
    required String refresh,
  }) async {
    if (kIsWeb) {
      platform.write(_accessKey, access);
      platform.write(_refreshKey, refresh);
      return;
    }
    await Future.wait([
      _secureStorage.write(key: _accessKey, value: access),
      _secureStorage.write(key: _refreshKey, value: refresh),
    ]);
  }

  Future<void> clear() async {
    if (kIsWeb) {
      platform.remove(_accessKey);
      platform.remove(_refreshKey);
      return;
    }
    await Future.wait([
      _secureStorage.delete(key: _accessKey),
      _secureStorage.delete(key: _refreshKey),
    ]);
  }
}
