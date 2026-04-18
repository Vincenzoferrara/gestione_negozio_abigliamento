import 'dart:async';
import 'dart:io';
import 'package:usb_serial/usb_serial.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as blue;
import 'package:shared_preferences/shared_preferences.dart';
import '../log_viewer/app_logger.dart';
import '../inventory/inventory_global.dart';

/// Classe principale per gestire la logica RFID
class RFIDManager {
  static final RFIDManager _instance = RFIDManager._internal();
  factory RFIDManager() => _instance;
  RFIDManager._internal();

  UsbPort? _usbPort;
  blue.BluetoothDevice? _btDevice;
  Socket? _wifiSocket;
  StreamSubscription? _usbSubscription;
  StreamSubscription? _btSubscription;

  bool _isConnected = false;
  String _connectionType = 'USB';
  String _selectedDevice = 'Nessuno';

  // Getter
  bool get isConnected => _isConnected;
  String get connectionType => _connectionType;

  /// Inizializza le impostazioni RFID
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _connectionType = prefs.getString('rfid_connection_type') ?? 'USB';
    _selectedDevice = prefs.getString('rfid_selected_device') ?? 'Nessuno';
    log.i(
      'RFID Manager inizializzato con tipo: $_connectionType, dispositivo: $_selectedDevice',
    );
  }

  /// Connette al dispositivo RFID selezionato
  Future<bool> connect() async {
    try {
      switch (_connectionType) {
        case 'USB':
          return await _connectUSB();
        case 'Bluetooth':
          return await _connectBluetooth();
        case 'WiFi':
          return await _connectWiFi();
        default:
          return false;
      }
    } catch (e) {
      log.e('Errore connessione RFID: $e');
      return false;
    }
  }

  /// Disconnette dal dispositivo
  Future<void> disconnect() async {
    try {
      await _usbSubscription?.cancel();
      await _btSubscription?.cancel();
      await _wifiSocket?.close();
      _usbPort = null;
      _btDevice = null;
      _wifiSocket = null;
      _isConnected = false;
      log.i('Disconnesso da dispositivo RFID');
    } catch (e) {
      log.e('Errore disconnessione: $e');
    }
  }

  /// Legge tag RFID e aggiorna inventario
  Future<List<String>> readTags() async {
    if (!_isConnected) {
      throw Exception('Dispositivo RFID non connesso');
    }

    List<String> tags = [];

    try {
      switch (_selectedDevice) {
        case 'Zebra FX7500':
          tags = await _readZebraTags();
          break;
        case 'Chainway C72':
          tags = await _readC72Tags();
          break;
        default:
          tags = await _readGenericTags();
      }

      // Aggiorna inventario
      await _updateInventory(tags);
      log.i('Letti ${tags.length} tag RFID');
    } catch (e) {
      log.e('Errore lettura tag: $e');
      rethrow;
    }

    return tags;
  }

  /// Scrive dati su tag RFID (placeholder - implementare metodi reali)
  Future<bool> writeTag(String tagId, String data) async {
    if (!_isConnected) {
      throw Exception('Dispositivo RFID non connesso');
    }

    try {
      // Placeholder: implementare metodi reali dei plugin
      log.i('Scrittura tag $tagId con dati: $data (placeholder)');
      return true; // Simula successo
    } catch (e) {
      log.e('Errore scrittura tag: $e');
      return false;
    }
  }

  // Implementazioni private per connessioni
  Future<bool> _connectUSB() async {
    // Placeholder: implementare connessione USB reale
    log.i('Connessione USB (placeholder)');
    return false; // Simula fallimento per ora
  }

  Future<bool> _connectBluetooth() async {
    // Placeholder: implementare connessione Bluetooth reale
    log.i('Connessione Bluetooth (placeholder)');
    return false; // Simula fallimento per ora
  }

  Future<bool> _connectWiFi() async {
    // Placeholder: implementare connessione WiFi reale
    log.i('Connessione WiFi (placeholder)');
    return false; // Simula fallimento per ora
  }

  // Implementazioni private per lettura tag
  Future<List<String>> _readZebraTags() async {
    try {
      // Placeholder: implementare metodo reale Zebra
      log.i('Lettura tag Zebra (placeholder)');
      return ['ZEBRA001', 'ZEBRA002']; // Simula tag
    } catch (e) {
      log.e('Errore lettura Zebra: $e');
      return [];
    }
  }

  Future<List<String>> _readC72Tags() async {
    try {
      // Placeholder: implementare metodo reale C72
      log.i('Lettura tag C72 (placeholder)');
      return ['C72001', 'C72002']; // Simula tag
    } catch (e) {
      log.e('Errore lettura C72: $e');
      return [];
    }
  }

  Future<List<String>> _readGenericTags() async {
    // Implementazione generica usando NFC o USB raw
    List<String> tags = [];

    try {
      if (_connectionType == 'USB' && _usbPort != null) {
        // Lettura raw da USB
        // Implementazione semplificata
        tags = ['TAG001', 'TAG002']; // Placeholder
      } else {
        // NFC disabled for now
        tags = ['NFC001', 'NFC002']; // Placeholder
      }
    } catch (e) {
      log.e('Errore lettura generica: $e');
    }

    return tags;
  }

  // Aggiorna inventario basato sui tag letti
  Future<void> _updateInventory(List<String> tags) async {
    try {
      final result = await InventoryGlobal().updateFromRFIDScan(tags);
      if (result.success) {
        log.i(
          'Inventario aggiornato con successo: ${result.syncedProducts} prodotti',
        );
      } else {
        log.w('Aggiornamento inventario fallito: ${result.errors.join(', ')}');
      }
    } catch (e) {
      log.e('Errore aggiornamento inventario: $e');
    }
  }

  /// Test connessione
  Future<bool> testConnection() async {
    if (!_isConnected) return false;
    try {
      final tags = await readTags();
      return tags.isNotEmpty;
    } catch (e) {
      log.e('Errore test connessione: $e');
      return false;
    }
  }
}
