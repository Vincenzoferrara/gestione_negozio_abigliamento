import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Impostazioni del modulo Cassa: nome/numero cassa fisica e sede.
/// Restano opzionali: se vuote, lo storico POS usa i fallback neutri e la
/// giornata operativa non inventa ubicazioni.
final cassaSettings = CassaSettings();

class CassaSettings extends ChangeNotifier {
  static const _nomeCassaKey = 'cassa_nome_cassa';
  static const _sedeKey = 'cassa_sede';

  String _nomeCassa = '';
  String _sede = '';
  bool _initialized = false;

  String get nomeCassa => _nomeCassa;
  String get sede => _sede;
  bool get hasCassa => _nomeCassa.trim().isNotEmpty;
  bool get hasSede => _sede.trim().isNotEmpty;

  Future<void> init({bool force = false}) async {
    if (_initialized && !force) return;
    final prefs = await SharedPreferences.getInstance();
    _nomeCassa = (prefs.getString(_nomeCassaKey) ?? '').trim();
    _sede = (prefs.getString(_sedeKey) ?? '').trim();
    _initialized = true;
    notifyListeners();
  }

  Future<void> setValori({String? nomeCassa, String? sede}) async {
    _nomeCassa = (nomeCassa ?? _nomeCassa).trim();
    _sede = (sede ?? _sede).trim();
    final prefs = await SharedPreferences.getInstance();
    if (_nomeCassa.isEmpty) {
      await prefs.remove(_nomeCassaKey);
    } else {
      await prefs.setString(_nomeCassaKey, _nomeCassa);
    }
    if (_sede.isEmpty) {
      await prefs.remove(_sedeKey);
    } else {
      await prefs.setString(_sedeKey, _sede);
    }
    notifyListeners();
  }
}
