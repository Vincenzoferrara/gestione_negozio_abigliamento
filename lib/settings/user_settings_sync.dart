import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../login/jwt_api/adapter/platform_manager.dart';

class UserSettingsSync {
  UserSettingsSync._();

  static final UserSettingsSync instance = UserSettingsSync._();

  static const Set<String> _exactSensitiveKeys = <String>{
    'jwt_token',
    'access_token',
    'refresh_token',
    'consumer_secret',
    'woocommerce_consumer_secret',
  };

  static const List<String> _sensitiveFragments = <String>[
    'password',
    'passwd',
    'secret',
    'token',
    'cookie',
    'authorization',
    'app_password',
    'consumer_secret',
    'api_secret',
    'api_key',
    'private_key',
    'caldav_password',
    'carddav_password',
  ];

  bool _syncing = false;

  Future<void> syncAfterLogin() async {
    if (_syncing || !PlatformManager.isMgwsAvailable) return;
    _syncing = true;
    try {
      final remote = await PlatformManager.userSettings.getMySettings();
      final settings = _asMap(remote['settings']);
      if (settings.isEmpty) {
        await pushAllLocalPreferences();
      } else {
        await _applyRemoteSettings(settings);
      }
    } catch (error) {
      debugPrint('MGWS user settings sync skipped: $error');
    } finally {
      _syncing = false;
    }
  }

  Future<void> pushAllLocalPreferences() async {
    if (!PlatformManager.isMgwsAvailable) return;
    final prefs = await SharedPreferences.getInstance();
    final payload = <String, dynamic>{};
    for (final key in prefs.getKeys()) {
      if (_isSensitiveKey(key)) continue;
      final value = prefs.get(key);
      if (_isSyncableValue(value)) payload[key] = value;
    }
    if (payload.isEmpty) return;
    try {
      await PlatformManager.userSettings.patchMySettings(payload);
    } catch (error) {
      debugPrint('MGWS user settings push skipped: $error');
    }
  }

  Future<void> _applyRemoteSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in settings.entries) {
      final key = entry.key.trim();
      if (key.isEmpty || _isSensitiveKey(key)) continue;
      final value = entry.value;
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      } else if (value is List) {
        final strings = value
            .where((item) => item != null)
            .map((item) => item.toString())
            .toList(growable: false);
        await prefs.setStringList(key, strings);
      }
    }
  }

  bool _isSensitiveKey(String key) {
    final normalized = key.trim().toLowerCase();
    if (_exactSensitiveKeys.contains(normalized)) return true;
    return _sensitiveFragments.any(normalized.contains);
  }

  bool _isSyncableValue(Object? value) {
    return value is bool ||
        value is int ||
        value is double ||
        value is String ||
        value is List<String>;
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const <String, dynamic>{};
  }
}
