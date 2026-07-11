import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manager per le impostazioni generali dell'applicazione
class AppSettings extends ChangeNotifier {
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

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
  static const String _shortcutToggleEditKey = 'shortcut_toggle_edit';
  static const String _shortcutSaveKey = 'shortcut_save';
  static const String _shortcutSelectAllKey = 'shortcut_select_all';
  static const String _shortcutDeleteKey = 'shortcut_delete';
  static const String _shortcutEscapeKey = 'shortcut_escape';
  static const String _persistProductFiltersKey = 'persist_product_filters';
  static const String _hideOutOfStockProductsKey = 'hide_out_of_stock_products';
  static const String _defaultPageSizeKey = 'default_page_size';
  static const String _visibleProductGridColumnsKey =
      'visible_product_grid_columns';
  bool _forceDelete = false;
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
  String _shortcutToggleEdit = 'Ctrl+E';
  String _shortcutSave = 'Ctrl+S';
  String _shortcutSelectAll = 'Ctrl+A';
  String _shortcutDelete = 'Delete';
  String _shortcutEscape = 'Esc';
  bool _persistProductFilters = false;
  bool _hideOutOfStockProducts = false;
  int _defaultPageSize = 20;
  List<String> _visibleProductGridColumns = <String>[];
  static const Set<String> _secureAiKeys = {
    'ai_openai_token',
    'ai_anthropic_token',
    'ai_google_token',
    'ai_mistral_token',
    'ai_cohere_token',
  };

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
  String get shortcutToggleEdit => _shortcutToggleEdit;
  String get shortcutSave => _shortcutSave;
  String get shortcutSelectAll => _shortcutSelectAll;
  String get shortcutDelete => _shortcutDelete;
  String get shortcutEscape => _shortcutEscape;
  bool get persistProductFilters => _persistProductFilters;
  bool get hideOutOfStockProducts => _hideOutOfStockProducts;
  int get defaultPageSize => _defaultPageSize;
  List<String> get visibleProductGridColumns =>
      List.unmodifiable(_visibleProductGridColumns);
  Future<void> init() async {
    await _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _forceDelete = prefs.getBool(_forceDeleteKey) ?? false;
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
      _imageBackgroundApiKey =
          await _readSecureValue(_imgBgApiKeyKey, legacyPrefs: prefs) ?? '';
      _attributeCaseMode = _normalizeAttributeCaseMode(
        prefs.getString(_attributeCaseModeKey) ?? 'upper',
      );
      _shortcutToggleEdit = prefs.getString(_shortcutToggleEditKey) ?? 'Ctrl+E';
      _shortcutSave = prefs.getString(_shortcutSaveKey) ?? 'Ctrl+S';
      _shortcutSelectAll = prefs.getString(_shortcutSelectAllKey) ?? 'Ctrl+A';
      _shortcutDelete = prefs.getString(_shortcutDeleteKey) ?? 'Delete';
      _shortcutEscape = prefs.getString(_shortcutEscapeKey) ?? 'Esc';
      _persistProductFilters =
          prefs.getBool(_persistProductFiltersKey) ?? false;
      _hideOutOfStockProducts =
          prefs.getBool(_hideOutOfStockProductsKey) ?? false;
      _defaultPageSize = _normalizeDefaultPageSize(
        prefs.getInt(_defaultPageSizeKey) ?? 20,
      );
      _visibleProductGridColumns =
          prefs.getStringList(_visibleProductGridColumnsKey) ?? <String>[];
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
      await _writeSecureValue(_imgBgApiKeyKey, _imageBackgroundApiKey);
      await prefs.setString(_attributeCaseModeKey, _attributeCaseMode);
      await prefs.setString(_shortcutToggleEditKey, _shortcutToggleEdit);
      await prefs.setString(_shortcutSaveKey, _shortcutSave);
      await prefs.setString(_shortcutSelectAllKey, _shortcutSelectAll);
      await prefs.setString(_shortcutDeleteKey, _shortcutDelete);
      await prefs.setString(_shortcutEscapeKey, _shortcutEscape);
      await prefs.setBool(_persistProductFiltersKey, _persistProductFilters);
      await prefs.setBool(_hideOutOfStockProductsKey, _hideOutOfStockProducts);
      await prefs.setInt(_defaultPageSizeKey, _defaultPageSize);
      await prefs.setStringList(
        _visibleProductGridColumnsKey,
        _visibleProductGridColumns,
      );
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

  Future<void> setShortcutToggleEdit(String value) async {
    final normalized = value.trim();
    if (normalized.isEmpty || _shortcutToggleEdit == normalized) return;
    _shortcutToggleEdit = normalized;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setShortcutSave(String value) async {
    final normalized = value.trim();
    if (normalized.isEmpty || _shortcutSave == normalized) return;
    _shortcutSave = normalized;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setShortcutSelectAll(String value) async {
    final normalized = value.trim();
    if (normalized.isEmpty || _shortcutSelectAll == normalized) return;
    _shortcutSelectAll = normalized;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setShortcutDelete(String value) async {
    final normalized = value.trim();
    if (normalized.isEmpty || _shortcutDelete == normalized) return;
    _shortcutDelete = normalized;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setShortcutEscape(String value) async {
    final normalized = value.trim();
    if (normalized.isEmpty || _shortcutEscape == normalized) return;
    _shortcutEscape = normalized;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> resetShortcutsToDefault() async {
    _shortcutToggleEdit = 'Ctrl+E';
    _shortcutSave = 'Ctrl+S';
    _shortcutSelectAll = 'Ctrl+A';
    _shortcutDelete = 'Delete';
    _shortcutEscape = 'Esc';
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setPersistProductFilters(bool value) async {
    if (_persistProductFilters == value) return;
    _persistProductFilters = value;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setHideOutOfStockProducts(bool value) async {
    if (_hideOutOfStockProducts == value) return;
    _hideOutOfStockProducts = value;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setDefaultPageSize(int value) async {
    final normalized = _normalizeDefaultPageSize(value);
    if (_defaultPageSize == normalized) return;
    _defaultPageSize = normalized;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setVisibleProductGridColumns(List<String> values) async {
    final normalized = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    if (_listEquals(_visibleProductGridColumns, normalized)) return;
    _visibleProductGridColumns = normalized;
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

  static int _normalizeDefaultPageSize(int value) {
    if (value <= 0) return 20;
    return value;
  }

  static bool _listEquals(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (int i = 0; i < left.length; i++) {
      if (left[i] != right[i]) return false;
    }
    return true;
  }

  // Metodi per gestire stringhe (token API, etc.)
  Future<String?> getAiToken(String key) async {
    try {
      if (_isSecureKey(key)) {
        return await _readSecureValue(key);
      }

      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (e) {
      debugPrint('Error getting AI token for key $key: $e');
      return null;
    }
  }

  Future<void> setAiToken(String key, String value) async {
    try {
      if (_isSecureKey(key)) {
        await _writeSecureValue(key, value);
        return;
      }

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

  bool _isSecureKey(String key) {
    return _secureAiKeys.contains(key) || key == _imgBgApiKeyKey;
  }

  Future<String?> _readSecureValue(
    String key, {
    SharedPreferences? legacyPrefs,
  }) async {
    final secureValue = await _secureStorage.read(key: key);
    if (secureValue != null) {
      return secureValue;
    }

    final prefs = legacyPrefs ?? await SharedPreferences.getInstance();
    final legacyValue = prefs.getString(key);
    if (legacyValue == null || legacyValue.isEmpty) {
      return null;
    }

    await _secureStorage.write(key: key, value: legacyValue);
    await prefs.remove(key);
    return legacyValue;
  }

  Future<void> _writeSecureValue(String key, String value) async {
    final normalized = value.trim();
    final prefs = await SharedPreferences.getInstance();

    if (normalized.isEmpty) {
      await _secureStorage.delete(key: key);
      await prefs.remove(key);
      return;
    }

    await _secureStorage.write(key: key, value: normalized);
    await prefs.remove(key);
  }
}
