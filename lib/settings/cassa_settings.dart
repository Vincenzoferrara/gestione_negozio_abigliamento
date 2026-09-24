import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../login/jwt_api/adapter/platform_manager.dart';

/// Impostazioni del modulo Cassa: nome/numero cassa fisica e sede.
/// Restano opzionali: se vuote, lo storico POS usa i fallback neutri e la
/// giornata operativa non inventa ubicazioni.
final cassaSettings = CassaSettings();

class CassaSettings extends ChangeNotifier {
  static const _nomeCassaKey = 'cassa_nome_cassa';
  static const _sedeKey = 'cassa_sede';
  static const _turnoObbligatorioKey = 'cassa_turno_obbligatorio';

  String _nomeCassa = '';
  String _sede = '';
  bool _turnoObbligatorio = true;
  bool _initialized = false;

  String get nomeCassa => _nomeCassa;
  String get sede => _sede;
  bool get turnoObbligatorio => _turnoObbligatorio;
  bool get hasCassa => _nomeCassa.trim().isNotEmpty;
  bool get hasSede => _sede.trim().isNotEmpty;

  Future<void> init({bool force = false}) async {
    if (_initialized && !force) return;
    final prefs = await SharedPreferences.getInstance();
    _nomeCassa = (prefs.getString(_nomeCassaKey) ?? '').trim();
    _sede = (prefs.getString(_sedeKey) ?? '').trim();
    _turnoObbligatorio = prefs.getBool(_turnoObbligatorioKey) ?? true;
    _initialized = true;
    await syncTurnoObbligatorioFromServer();
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

  Future<void> setTurnoObbligatorio(
    bool value, {
    bool syncServer = true,
  }) async {
    final previousValue = _turnoObbligatorio;
    var effectiveValue = value;
    final prefs = await SharedPreferences.getInstance();

    if (syncServer && (await PlatformManager.refreshCanUseMgws())) {
      try {
        final response = await PlatformManager.pos.updateSettings(
          turnoObbligatorio: value,
        );
        if (response['success'] == false || response['ok'] == false) {
          throw Exception(
            response['message']?.toString() ??
                'Impostazione turno cassa non salvata sul server',
          );
        }
        final remoteValue = response['turno_obbligatorio'];
        if (remoteValue is bool) {
          effectiveValue = remoteValue;
        }
      } catch (error) {
        _turnoObbligatorio = previousValue;
        await prefs.setBool(_turnoObbligatorioKey, previousValue);
        notifyListeners();
        debugPrint('Sync turno cassa obbligatorio fallita: $error');
        rethrow;
      }
    }

    _turnoObbligatorio = effectiveValue;
    await prefs.setBool(_turnoObbligatorioKey, effectiveValue);
    notifyListeners();
  }

  Future<void> syncTurnoObbligatorioFromServer() async {
    if (!(await PlatformManager.refreshCanUseMgws())) return;
    try {
      final response = await PlatformManager.pos.getSettings();
      final remoteValue = response['turno_obbligatorio'];
      if (remoteValue is! bool) return;
      _turnoObbligatorio = remoteValue;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_turnoObbligatorioKey, remoteValue);
    } catch (error) {
      debugPrint('Lettura impostazioni POS MGWS saltata: $error');
    }
  }
}
