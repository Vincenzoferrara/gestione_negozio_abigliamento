import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'jwt_connect.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _sessionKey = 'user_session';
  static const _siteUrlKey = 'site_url';
  static const _lastEndpointKey = 'last_jwt_endpoint';

  static Future<void> saveSession(UserSession session, String siteUrl) async {
    final sessionJson = session.toJson();
    // Hardening: do not persist Woo API key material to disk.
    if (sessionJson['woo_config'] is Map) {
      final woo = Map<String, dynamic>.from(sessionJson['woo_config'] as Map);
      woo.remove('consumer_key');
      woo.remove('consumer_secret');
      sessionJson['woo_config'] = woo;
    }
    await _storage.write(key: _sessionKey, value: jsonEncode(sessionJson));
    await _storage.write(key: _siteUrlKey, value: siteUrl);
  }

  static Future<(UserSession, String)?> loadSession() async {
    final sessionString = await _storage.read(key: _sessionKey);
    final siteUrl = await _storage.read(key: _siteUrlKey);
    if (sessionString != null && siteUrl != null) {
      try {
        final session = UserSession.fromJson(jsonDecode(sessionString));
        return (session, siteUrl);
      } catch (e) {
        await clearAll();
        return null;
      }
    }
    return null;
  }

  static Future<void> saveLastUsedEndpoint(String endpoint) async {
    await _storage.write(key: _lastEndpointKey, value: endpoint);
  }

  static Future<String?> getLastUsedEndpoint() async {
    return await _storage.read(key: _lastEndpointKey);
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
