import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manager per le impostazioni generali dell'applicazione
class AppSettings extends ChangeNotifier {
  static const String _forceDeleteKey = 'force_delete';
  static const String _confirmDeleteKey = 'confirm_delete';

  bool _forceDelete = true;
  bool _confirmDelete = true;

  bool get forceDelete => _forceDelete;
  bool get confirmDelete => _confirmDelete;

  Future<void> init() async {
    await _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _forceDelete = prefs.getBool(_forceDeleteKey) ?? true;
      _confirmDelete = prefs.getBool(_confirmDeleteKey) ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading app preferences: $e');
    }
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_forceDeleteKey, _forceDelete);
      await prefs.setBool(_confirmDeleteKey, _confirmDelete);
    } catch (e) {
      debugPrint('Error saving app preferences: $e');
    }
  }

  Future<void> setForceDelete(bool force) async {
    if (_forceDelete != force) {
      _forceDelete = force;
      await _savePreferences();
      notifyListeners();
    }
  }

  Future<void> setConfirmDelete(bool confirm) async {
    if (_confirmDelete != confirm) {
      _confirmDelete = confirm;
      await _savePreferences();
      notifyListeners();
    }
  }

  // Metodi per gestire stringhe (token API, etc.)
  Future<String?> getAiToken(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (e) {
      debugPrint('Error getting AI token for key $key: $e');
      return null;
    }
  }

  Future<void> setAiToken(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (e) {
      debugPrint('Error setting AI token for key $key: $e');
    }
  }

  // Metodi per impostazioni RFID
  Future<String?> getRFIDSetting(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('rfid_$key');
    } catch (e) {
      debugPrint('Error getting RFID setting for key $key: $e');
      return null;
    }
  }

  Future<void> setRFIDSetting(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('rfid_$key', value);
    } catch (e) {
      debugPrint('Error setting RFID setting for key $key: $e');
    }
  }
}
