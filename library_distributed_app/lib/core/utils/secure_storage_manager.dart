import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorage = SecureStorageManager.instance;

class SecureStorageManager {
  SecureStorageManager._();
  static final SecureStorageManager instance = SecureStorageManager._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _keyAccessToken = 'ACCESS_TOKEN';

  Future<void> writeAccessToken(String token) async {
    await _storage.write(key: _keyAccessToken, value: token);
  }

  Future<String?> readAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
