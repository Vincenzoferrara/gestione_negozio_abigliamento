import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manager per le impostazioni generali dell'applicazione
class AppSettings extends ChangeNotifier {
  static const String _forceDeleteKey = 'force_delete';
  static const String _confirmDeleteKey = 'confirm_delete';
  static const String _imgResizeEnabledKey = 'img_resize_enabled';
  static const String _imgBgRemoveEnabledKey = 'img_bg_remove_enabled';
  static const String _imgFormatEnabledKey = 'img_format_enabled';
  static const String _imgResizeWidthKey = 'img_resize_width';
  static const String _imgResizeHeightKey = 'img_resize_height';
  static const String _imgOutputFormatKey = 'img_output_format';
  static const String _imgBgModeKey = 'img_bg_mode';
  static const String _imgBgApiEndpointKey = 'img_bg_api_endpoint';
  static const String _imgBgApiKeyKey = 'img_bg_api_key';
  static const String _attributeCaseModeKey = 'attribute_case_mode';

  bool _forceDelete = true;
  bool _confirmDelete = true;
  bool _imageResizeEnabled = true;
  bool _imageBackgroundRemoveEnabled = true;
  bool _imageFormatChangeEnabled = true;
  int _imageResizeWidth = 720;
  int _imageResizeHeight = 1080;
  String _imageOutputFormat = 'webp';
  String _imageBackgroundMode = 'auto';
  String _imageBackgroundApiEndpoint = 'https://api.remove.bg/v1.0/removebg';
  String _imageBackgroundApiKey = '';
  String _attributeCaseMode = 'upper';

  bool get forceDelete => _forceDelete;
  bool get confirmDelete => _confirmDelete;
  bool get imageResizeEnabled => _imageResizeEnabled;
  bool get imageBackgroundRemoveEnabled => _imageBackgroundRemoveEnabled;
  bool get imageFormatChangeEnabled => _imageFormatChangeEnabled;
  int get imageResizeWidth => _imageResizeWidth;
  int get imageResizeHeight => _imageResizeHeight;
  String get imageOutputFormat => _imageOutputFormat;
  String get imageBackgroundMode => _imageBackgroundMode;
  String get imageBackgroundApiEndpoint => _imageBackgroundApiEndpoint;
  String get imageBackgroundApiKey => _imageBackgroundApiKey;
  String get attributeCaseMode => _attributeCaseMode;

  Future<void> init() async {
    await _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _forceDelete = prefs.getBool(_forceDeleteKey) ?? true;
      _confirmDelete = prefs.getBool(_confirmDeleteKey) ?? true;
      _imageResizeEnabled = prefs.getBool(_imgResizeEnabledKey) ?? true;
      _imageBackgroundRemoveEnabled =
          prefs.getBool(_imgBgRemoveEnabledKey) ?? true;
      _imageFormatChangeEnabled = prefs.getBool(_imgFormatEnabledKey) ?? true;
      _imageResizeWidth = prefs.getInt(_imgResizeWidthKey) ?? 720;
      _imageResizeHeight = prefs.getInt(_imgResizeHeightKey) ?? 1080;
      _imageOutputFormat = prefs.getString(_imgOutputFormatKey) ?? 'webp';
      _imageBackgroundMode = prefs.getString(_imgBgModeKey) ?? 'auto';
      _imageBackgroundApiEndpoint =
          prefs.getString(_imgBgApiEndpointKey) ??
          'https://api.remove.bg/v1.0/removebg';
      _imageBackgroundApiKey = prefs.getString(_imgBgApiKeyKey) ?? '';
      _attributeCaseMode = _normalizeAttributeCaseMode(
        prefs.getString(_attributeCaseModeKey) ?? 'upper',
      );
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
      await prefs.setBool(_imgResizeEnabledKey, _imageResizeEnabled);
      await prefs.setBool(
        _imgBgRemoveEnabledKey,
        _imageBackgroundRemoveEnabled,
      );
      await prefs.setBool(_imgFormatEnabledKey, _imageFormatChangeEnabled);
      await prefs.setInt(_imgResizeWidthKey, _imageResizeWidth);
      await prefs.setInt(_imgResizeHeightKey, _imageResizeHeight);
      await prefs.setString(_imgOutputFormatKey, _imageOutputFormat);
      await prefs.setString(_imgBgModeKey, _imageBackgroundMode);
      await prefs.setString(_imgBgApiEndpointKey, _imageBackgroundApiEndpoint);
      await prefs.setString(_imgBgApiKeyKey, _imageBackgroundApiKey);
      await prefs.setString(_attributeCaseModeKey, _attributeCaseMode);
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

  Future<void> setImageResizeEnabled(bool value) async {
    if (_imageResizeEnabled == value) return;
    _imageResizeEnabled = value;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setImageBackgroundRemoveEnabled(bool value) async {
    if (_imageBackgroundRemoveEnabled == value) return;
    _imageBackgroundRemoveEnabled = value;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setImageFormatChangeEnabled(bool value) async {
    if (_imageFormatChangeEnabled == value) return;
    _imageFormatChangeEnabled = value;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setImageResizeWidth(int value) async {
    final safe = value < 0 ? 0 : value;
    if (_imageResizeWidth == safe) return;
    _imageResizeWidth = safe;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setImageResizeHeight(int value) async {
    final safe = value < 0 ? 0 : value;
    if (_imageResizeHeight == safe) return;
    _imageResizeHeight = safe;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setImageOutputFormat(String format) async {
    final normalized = format.trim().toLowerCase();
    if (normalized != 'webp' && normalized != 'jpg' && normalized != 'png') {
      return;
    }
    if (_imageOutputFormat == normalized) return;
    _imageOutputFormat = normalized;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setImageBackgroundMode(String mode) async {
    final normalized = mode.trim().toLowerCase();
    if (normalized != 'auto' && normalized != 'local' && normalized != 'api') {
      return;
    }
    if (_imageBackgroundMode == normalized) return;
    _imageBackgroundMode = normalized;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setImageBackgroundApiEndpoint(String endpoint) async {
    final normalized = endpoint.trim();
    if (normalized.isEmpty) return;
    if (_imageBackgroundApiEndpoint == normalized) return;
    _imageBackgroundApiEndpoint = normalized;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setImageBackgroundApiKey(String apiKey) async {
    final normalized = apiKey.trim();
    if (_imageBackgroundApiKey == normalized) return;
    _imageBackgroundApiKey = normalized;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setAttributeCaseMode(String mode) async {
    final normalized = _normalizeAttributeCaseMode(mode);
    if (_attributeCaseMode == normalized) return;
    _attributeCaseMode = normalized;
    await _savePreferences();
    notifyListeners();
  }

  String normalizeAttributeParameter(String input) {
    return normalizeAttributeParameterWithMode(input, _attributeCaseMode);
  }

  static String normalizeAttributeParameterWithMode(String input, String mode) {
    var normalized = input.replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '');
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) return '';

    final caseMode = _normalizeAttributeCaseMode(mode);
    if (caseMode == 'lower') {
      return normalized.toLowerCase();
    }
    return normalized.toUpperCase();
  }

  static String _normalizeAttributeCaseMode(String mode) {
    final normalized = mode.trim().toLowerCase();
    if (normalized == 'lower') return 'lower';
    return 'upper';
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
