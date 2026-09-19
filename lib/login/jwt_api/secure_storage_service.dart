import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'jwt_connect.dart';
import '../wp_admin_api/wordpress_session.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _sessionKey = 'user_session';
  static const _siteUrlKey = 'site_url';
  static const _lastEndpointKey = 'last_jwt_endpoint';
  // Identificativo non segreto dell'utente loggato via JWT (solo username,
  // mai password o token): serve aModules come la cassa per attribuire
  // l'operatore senza toccare i segreti di sessione.
  static const _loginUsernameKey = 'login_username';

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

  static Future<void> saveLoginUsername(String username) async {
    final normalized = username.trim();
    if (normalized.isEmpty) return;
    await _storage.write(key: _loginUsernameKey, value: normalized);
  }

  static Future<String?> loadLoginUsername() async {
    return await _storage.read(key: _loginUsernameKey);
  }

  // ── WordPress session persistence ──

  static const _wpSessionKey = 'wp_application_password_session';

  static Future<void> saveWpSession(WordPressSession session) async {
    await _storage.write(
      key: _wpSessionKey,
      value: jsonEncode(session.toJson()),
    );
  }

  static Future<WordPressSession?> loadWpSession() async {
    final raw = await _storage.read(key: _wpSessionKey);
    if (raw == null) return null;
    try {
      return WordPressSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      await _storage.delete(key: _wpSessionKey);
      return null;
    }
  }

  static Future<void> clearWpSession() async {
    await _storage.delete(key: _wpSessionKey);
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
