import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/theme.dart';

/// Manager per le impostazioni del tema
/// Gestisce la modalità tema (light/dark/system) e i colori personalizzati
class ThemeSettings extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _primaryColorKey = 'primary_color';
  static const String _useDockingOnMobileKey = 'use_docking_on_mobile';
  static const String _showHomeReportKey = 'show_home_report';

  ThemeMode _themeMode = ThemeMode.system;
  Color _primaryColor = AppTheme.primaryColor;
  bool _useDockingOnMobile = false; // Default: disabilitato su smartphone
  bool _showHomeReport = true; // Default: mostra il report nella home

  ThemeMode get themeMode => _themeMode;
  Color get primaryColor => _primaryColor;
  bool get useDockingOnMobile => _useDockingOnMobile;
  bool get showHomeReport => _showHomeReport;

  /// Inizializza il theme manager caricando le preferenze salvate
  Future<void> init() async {
    await _loadPreferences();
  }

  /// Carica le preferenze dal storage
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Carica theme mode
      final themeModeIndex = prefs.getInt(_themeModeKey);
      if (themeModeIndex != null) {
        _themeMode = ThemeMode.values[themeModeIndex];
      }

      // Carica colore primario
      final primaryColorValue = prefs.getInt(_primaryColorKey);
      if (primaryColorValue != null) {
        _primaryColor = Color(primaryColorValue);
      }

      // Carica impostazione docking su mobile
      _useDockingOnMobile = prefs.getBool(_useDockingOnMobileKey) ?? false;

      // Carica impostazione visualizzazione report nella home
      _showHomeReport = prefs.getBool(_showHomeReportKey) ?? true;

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme preferences: $e');
    }
  }

  /// Salva le preferenze nel storage
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeModeKey, _themeMode.index);
      await prefs.setInt(_primaryColorKey, _primaryColor.toARGB32());
      await prefs.setBool(_useDockingOnMobileKey, _useDockingOnMobile);
      await prefs.setBool(_showHomeReportKey, _showHomeReport);
    } catch (e) {
      debugPrint('Error saving theme preferences: $e');
    }
  }

  /// Cambia la modalità del tema
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      await _savePreferences();
      notifyListeners();
    }
  }

  /// Toggle rapido tra light e dark
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }

  /// Imposta il colore primario personalizzato
  Future<void> setPrimaryColor(Color color) async {
    if (_primaryColor != color) {
      _primaryColor = color;
      await _savePreferences();
      notifyListeners();
    }
  }

  /// Ripristina il colore predefinito
  Future<void> resetColor() async {
    _primaryColor = AppTheme.primaryColor;
    await _savePreferences();
    notifyListeners();
  }

  /// Imposta la visualizzazione del report nella home
  Future<void> setShowHomeReport(bool show) async {
    if (_showHomeReport != show) {
      _showHomeReport = show;
      await _savePreferences();
      notifyListeners();
    }
  }

  /// Ottiene il tema light con il colore personalizzato
  ThemeData get customLightTheme {
    return AppTheme.lightTheme.copyWith(
      primaryColor: _primaryColor,
      colorScheme: AppTheme.lightTheme.colorScheme.copyWith(
        primary: _primaryColor,
      ),
      appBarTheme: AppTheme.lightTheme.appBarTheme.copyWith(
        backgroundColor: _primaryColor,
      ),
      // Aggiorna InputDecorationTheme con il nuovo colore primario
      inputDecorationTheme: AppTheme.lightTheme.inputDecorationTheme.copyWith(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _primaryColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
      ),
      // Aggiorna TextSelectionTheme con il nuovo colore primario
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: _primaryColor,
        selectionColor: _primaryColor.withValues(alpha: 0.3),
        selectionHandleColor: _primaryColor,
      ),
      // IMPORTANTE: Mantieni le estensioni del tema base
      extensions: AppTheme.lightTheme.extensions.values,
    );
  }

  /// Ottiene il tema dark con il colore personalizzato
  ThemeData get customDarkTheme {
    return AppTheme.darkTheme.copyWith(
      primaryColor: _primaryColor,
      colorScheme: AppTheme.darkTheme.colorScheme.copyWith(
        primary: _primaryColor,
      ),
      appBarTheme: AppTheme.darkTheme.appBarTheme.copyWith(
        backgroundColor: _primaryColor.withValues(alpha: 0.9),
      ),
      // Aggiorna InputDecorationTheme con il nuovo colore primario
      inputDecorationTheme: AppTheme.darkTheme.inputDecorationTheme.copyWith(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _primaryColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
      ),
      // Aggiorna TextSelectionTheme con il nuovo colore primario
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: _primaryColor,
        selectionColor: _primaryColor.withValues(alpha: 0.3),
        selectionHandleColor: _primaryColor,
      ),
      // IMPORTANTE: Mantieni le estensioni del tema base
      extensions: AppTheme.darkTheme.extensions.values,
    );
  }
}
