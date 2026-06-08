import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Przechowywanie tokenu JWT w szyfrowanym magazynie systemowym
// (Android Keystore / iOS Keychain) z jednorazową migracją starego tokenu
// z SharedPreferences.
class TokenStorage {
  static const String _key = 'jwt_token';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _key, value: token);
  }

  static Future<String?> getToken() async {
    final secureToken = await _storage.read(key: _key);
    if (secureToken != null) return secureToken;

    // Migracja ze starego, niezabezpieczonego magazynu (jednorazowo).
    final prefs = await SharedPreferences.getInstance();
    final legacyToken = prefs.getString(_key);
    if (legacyToken != null) {
      await _storage.write(key: _key, value: legacyToken);
      await prefs.remove(_key);
      return legacyToken;
    }
    return null;
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _key);
    // Czyścimy też ewentualną starą kopię w SharedPreferences.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
