import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();

  static Future<void> saveAccessToken(String token) async {
    await _storage.write(key: "accessToken", value: token);
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: "accessToken");
  }
  static Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: "refreshToken", value: token);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: "refreshToken");
  }

  static Future<void> deleteAccessToken() async {
    await _storage.delete(key: "accessToken");
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: "refreshToken");
    await _storage.delete(key: "accessToken");
  }
}
