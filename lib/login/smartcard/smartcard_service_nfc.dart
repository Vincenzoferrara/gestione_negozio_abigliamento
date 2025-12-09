import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:usb_serial/usb_serial.dart';
import '../../log_viewer/app_logger.dart';
import 'smartcard_service.dart';

// ignore: implementation_imports
import 'package:nfc_manager/src/nfc_manager_android/tags/ndef.dart' as android_ndef;
// ignore: implementation_imports
import 'package:nfc_manager/src/nfc_manager_ios/tags/ndef.dart' as ios_ndef;

/// Logger per l'extension
final _log = AppLogger();

/// Helper per ottenere NDEF da un tag in modo cross-platform
dynamic _getNdefFromTag(NfcTag tag) {
  if (defaultTargetPlatform == TargetPlatform.android) {
    return android_ndef.NdefAndroid.from(tag);
  } else if (defaultTargetPlatform == TargetPlatform.iOS) {
    return ios_ndef.NdefIos.from(tag);
  }
  return null;
}

/// Estensione del servizio smartcard con implementazioni NFC e USB complete
extension SmartcardNfcExtension on SmartcardService {
  /// Verifica se NFC è disponibile (versione implementata)
  Future<bool> checkNfcAvailability() async {
    try {
      final isAvailable = await NfcManager.instance.isAvailable();
      if (isAvailable) {
        _log.i('✅ NFC disponibile');
      } else {
        _log.w('❌ NFC non disponibile su questo dispositivo');
      }
      return isAvailable;
    } catch (e) {
      _log.e('Errore controllo NFC', e);
      return false;
    }
  }

  /// Verifica se lettore USB è disponibile (versione implementata)
  Future<bool> checkUsbReaderAvailability() async {
    try {
      final devices = await UsbSerial.listDevices();
      if (devices.isNotEmpty) {
        _log.i('✅ Trovati ${devices.length} lettori USB');
        return true;
      }
      _log.w('❌ Nessun lettore USB trovato');
      return false;
    } catch (e) {
      _log.e('Errore controllo USB', e);
      return false;
    }
  }

  /// Scrivi su NFC (implementazione completa)
  Future<bool> writeNfc(SmartcardData data) async {
    try {
      _log.i('📝 Scrittura su NFC...');

      bool success = false;

      await NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
        onDiscovered: (NfcTag tag) async {
          try {
            final ndef = _getNdefFromTag(tag);
            if (ndef == null) {
              _log.w('Card non supporta NDEF');
              return;
            }

            if (!ndef.isWritable) {
              _log.w('Card protetta da scrittura');
              return;
            }

            // Prepara dati
            final dataString = data.toEncryptedString();
            final dataBytes = utf8.encode(dataString);

            if (ndef.maxSize < dataBytes.length) {
              _log.w('Dati troppo grandi (${dataBytes.length}/${ndef.maxSize} bytes)');
              return;
            }

            // Scrivi
            final record = NdefRecord(
              typeNameFormat: TypeNameFormat.wellKnown,
              type: Uint8List.fromList([0x54]), // 'T' for Text
              identifier: Uint8List(0),
              payload: Uint8List.fromList([
                0x02, // Status byte: UTF-8, language code length = 2
                0x65, 0x6E, // 'en'
                ...utf8.encode(dataString),
              ]),
            );

            final message = NdefMessage(records: [record]);

            await ndef.write(message);
            _log.i('✅ ${dataBytes.length} bytes scritti su NFC');
            success = true;
            await NfcManager.instance.stopSession();
          } catch (e) {
            _log.e('Errore scrittura NFC', e);
            await NfcManager.instance.stopSession();
          }
        },
      );

      return success;
    } catch (e) {
      _log.e('Errore write NFC', e);
      return false;
    }
  }

  /// Leggi da NFC (implementazione completa)
  Future<SmartcardData?> readNfc() async {
    try {
      _log.i('📖 Lettura da NFC...');

      SmartcardData? result;

      await NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
        onDiscovered: (NfcTag tag) async {
          try {
            final ndef = _getNdefFromTag(tag);
            if (ndef == null) {
              _log.w('Card non NDEF formattata');
              return;
            }

            final message = ndef.cachedNdefMessage;
            if (message == null || message.records.isEmpty) {
              _log.w('Nessun dato sulla card');
              return;
            }

            // Estrai testo dal primo record
            final record = message.records.first;
            final languageCodeLength = record.payload[0] & 0x3F;
            final textBytes = record.payload.sublist(1 + languageCodeLength);
            final dataString = utf8.decode(textBytes);

            // Decodifica
            result = SmartcardData.fromEncryptedString(dataString);
            _log.i('✅ Dati letti da NFC');
            await NfcManager.instance.stopSession();
          } catch (e) {
            _log.e('Errore lettura NFC', e);
            await NfcManager.instance.stopSession();
          }
        },
      );

      return result;
    } catch (e) {
      _log.e('Errore read NFC', e);
      return null;
    }
  }

  /// Scrivi su USB (implementazione completa)
  Future<bool> writeUsb(SmartcardData data) async {
    try {
      _log.i('📝 Scrittura su USB...');

      final devices = await UsbSerial.listDevices();
      if (devices.isEmpty) {
        _log.e('Nessun lettore USB');
        return false;
      }

      final device = devices.first;
      final port = await device.create();
      if (port == null) {
        _log.e('Impossibile creare porta USB');
        return false;
      }

      if (!await port.open()) {
        _log.e('Impossibile aprire porta');
        return false;
      }

      // Configura porta
      await port.setDTR(true);
      await port.setRTS(true);
      await port.setPortParameters(
        9600,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );

      // Prepara comando
      final dataString = data.toEncryptedString();
      final dataBytes = utf8.encode(dataString);
      final command = Uint8List.fromList([
        0x02, // CMD: WRITE
        (dataBytes.length >> 8) & 0xFF,
        dataBytes.length & 0xFF,
        ...dataBytes,
      ]);

      // Invia
      await port.write(command);

      // Attendi risposta (leggi dallo stream)
      final responseList = <int>[];
      await for (final data in port.inputStream!.timeout(
        const Duration(seconds: 2),
        onTimeout: (sink) => sink.close(),
      )) {
        responseList.addAll(data);
        if (responseList.isNotEmpty) break; // Abbiamo la risposta
      }

      await port.close();

      if (responseList.isNotEmpty && responseList[0] == 0x06) {
        _log.i('✅ Dati scritti su USB');
        return true;
      }

      _log.e('Nessuna conferma dal lettore');
      return false;
    } catch (e) {
      _log.e('Errore write USB', e);
      return false;
    }
  }

  /// Leggi da USB (implementazione completa)
  Future<SmartcardData?> readUsb() async {
    try {
      _log.i('📖 Lettura da USB...');

      final devices = await UsbSerial.listDevices();
      if (devices.isEmpty) return null;

      final device = devices.first;
      final port = await device.create();
      if (port == null || !await port.open()) return null;

      await port.setDTR(true);
      await port.setRTS(true);
      await port.setPortParameters(
        9600,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );

      // Comando READ
      await port.write(Uint8List.fromList([0x01]));

      // Leggi risposta dallo stream
      final responseList = <int>[];
      await for (final data in port.inputStream!.timeout(
        const Duration(seconds: 2),
        onTimeout: (sink) => sink.close(),
      )) {
        responseList.addAll(data);
        // Continua a leggere finché non abbiamo almeno header + length
        if (responseList.length >= 3) {
          final expectedLength = (responseList[1] << 8) | responseList[2];
          if (responseList.length >= 3 + expectedLength) break;
        }
      }

      await port.close();

      if (responseList.isEmpty || responseList[0] != 0x06) {
        _log.e('Errore lettura USB');
        return null;
      }

      final length = (responseList[1] << 8) | responseList[2];
      final dataBytes = responseList.sublist(3, 3 + length);
      final dataString = utf8.decode(dataBytes);

      final result = SmartcardData.fromEncryptedString(dataString);
      _log.i('✅ Dati letti da USB');
      return result;
    } catch (e) {
      _log.e('Errore read USB', e);
      return null;
    }
  }
}
