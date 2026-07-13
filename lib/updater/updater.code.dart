import 'package:flutter/material.dart';

import 'updater_service.dart';

enum UpdaterStatus {
  idle,
  unsupported,
  checking,
  updateAvailable,
  upToDate,
  installing,
  error,
}

class UpdaterLogic extends ChangeNotifier {
  final UpdaterService _service;

  UpdaterStatus _status = UpdaterStatus.idle;
  String _installedVersion = '';
  String _message = '';
  String? _error;

  UpdaterLogic({UpdaterService? service})
    : _service = service ?? UpdaterService();

  UpdaterStatus get status => _status;
  String get installedVersion => _installedVersion;
  String get message => _message;
  String? get error => _error;
  String get platformLabel => UpdaterService.platformLabel;
  String get updateUrl => UpdaterService.updateUrl;
  bool get isSupported => UpdaterService.isDesktopUpdateSupported;
  bool get isBusy =>
      _status == UpdaterStatus.checking || _status == UpdaterStatus.installing;

  Future<void> init() async {
    try {
      _installedVersion = await _service.installedVersion();
    } catch (_) {
      _installedVersion = 'Sconosciuta';
    }

    if (!isSupported) {
      _status = UpdaterStatus.unsupported;
      _message =
          'Aggiornamenti automatici disponibili solo su Windows e Linux.';
    } else {
      _status = UpdaterStatus.idle;
      _message = 'Pronto per controllare aggiornamenti desktop.';
    }
    notifyListeners();
  }

  Future<void> checkForUpdates() async {
    if (!isSupported || isBusy) return;
    _status = UpdaterStatus.checking;
    _message = 'Controllo aggiornamenti in corso...';
    _error = null;
    notifyListeners();

    try {
      final available = await _service.checkForUpdates();
      if (available) {
        _status = UpdaterStatus.updateAvailable;
        _message = 'Nuovo aggiornamento disponibile.';
      } else {
        _status = UpdaterStatus.upToDate;
        _message = 'L\'app e aggiornata.';
      }
    } catch (error) {
      _status = UpdaterStatus.error;
      _error = error.toString();
      _message = 'Controllo aggiornamenti non riuscito.';
    }
    notifyListeners();
  }

  Future<void> installAndRestart() async {
    if (!isSupported || isBusy) return;
    _status = UpdaterStatus.installing;
    _message = 'Installazione aggiornamento e riavvio in corso...';
    _error = null;
    notifyListeners();

    try {
      await _service.installAndRestart();
    } catch (error) {
      _status = UpdaterStatus.error;
      _error = error.toString();
      _message = 'Installazione aggiornamento non riuscita.';
      notifyListeners();
    }
  }
}
