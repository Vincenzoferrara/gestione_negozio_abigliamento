import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:usb_serial/usb_serial.dart';
import '../../log_viewer/app_logger.dart';
import 'smartcard_service.dart';

/// Estensione del servizio smartcard con implementazioni NFC e USB complete
extension SmartcardNfcExtension on SmartcardService {
  /// Verifica se NFC è disponibile (versione implementata)
  Future<bool> checkNfcAvailability() async {
    try {
      final isAvailable = await NfcManager.instance.isAvailable();
      if (isAvailable) {
        log.i('✅ NFC disponibile');
      } else {
        log.w('❌ NFC non disponibile su questo dispositivo');
      }
      return isAvailable;
    } catch (e) {
      log.e('Errore controllo NFC', e);
      return false;
    }
  }

  /// Verifica se lettore USB è disponibile (versione implementata)
  Future<bool> checkUsbReaderAvailability() async {
    try {
      final devices = await UsbSerial.listDevices();
      if (devices.isNotEmpty) {
        log.i('✅ Trovati ${devices.length} lettori USB');
        return true;
      }
      log.w('❌ Nessun lettore USB trovato');
      return false;
    } catch (e) {
      log.e('Errore controllo USB', e);
      return false;
    }
  }

  /// Scrivi su NFC (implementazione completa)
  Future<bool> writeNfc(SmartcardData data) async {
    try {
      log.i('📝 Scrittura su NFC...');

      bool success = false;
      String? errorMsg;

      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            final ndef = Ndef.from(tag);
            if (ndef == null) {
              errorMsg = 'Card non supporta NDEF';
              return;
            }

            if (!ndef.isWritable) {
              errorMsg = 'Card protetta da scrittura';
              return;
            }

            // Prepara dati
            final dataString = data.toEncryptedString();
            final dataBytes = utf8.encode(dataString);

            if (ndef.maxSize < dataBytes.length) {
              errorMsg = 'Dati troppo grandi (${dataBytes.length}/${ndef.maxSize} bytes)';
              return;
            }

            // Scrivi
            final message = NdefMessage([
              NdefRecord.createText(dataString),
            ]);

            await ndef.write(message);
            log.i('✅ ${dataBytes.length} bytes scritti su NFC');
            success = true;
          } catch (e) {
            errorMsg = e.toString();
            log.e('Errore scrittura NFC', e);
          } finally {
            await NfcManager.instance.stopSession(errorMessage: errorMsg);
          }
        },
      );

      return success;
    } catch (e) {
      log.e('Errore write NFC', e);
      return false;
    }
  }

  /// Leggi da NFC (implementazione completa)
  Future<SmartcardData?> readNfc() async {
    try {
      log.i('📖 Lettura da NFC...');

      SmartcardData? result;
      String? errorMsg;

      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            final ndef = Ndef.from(tag);
            if (ndef == null) {
              errorMsg = 'Card non NDEF formattata';
              return;
            }

            final message = await ndef.read();
            if (message.records.isEmpty) {
              errorMsg = 'Nessun dato sulla card';
              return;
            }

            // Estrai testo dal primo record
            final record = message.records.first;
            final languageCodeLength = record.payload[0] & 0x3F;
            final textBytes = record.payload.sublist(1 + languageCodeLength);
            final dataString = utf8.decode(textBytes);

            // Decodifica
            result = SmartcardData.fromEncryptedString(dataString);
            log.i('✅ Dati letti da NFC');
          } catch (e) {
            errorMsg = e.toString();
            log.e('Errore lettura NFC', e);
          } finally {
            await NfcManager.instance.stopSession(errorMessage: errorMsg);
          }
        },
      );

      return result;
    } catch (e) {
      log.e('Errore read NFC', e);
      return null;
    }
  }

  /// Scrivi su USB (implementazione completa)
  Future<bool> writeUsb(SmartcardData data) async {
    try {
      log.i('📝 Scrittura su USB...');

      final devices = await UsbSerial.listDevices();
      if (devices.isEmpty) {
        log.e('Nessun lettore USB');
        return false;
      }

      final device = devices.first;
      final port = await device.create();
      if (port == null) {
        log.e('Impossibile creare porta USB');
        return false;
      }

      if (!await port.open()) {
        log.e('Impossibile aprire porta');
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
      await Future.delayed(const Duration(milliseconds: 500));
      final response = await port.read();
      await port.close();

      if (response.isNotEmpty && response[0] == 0x06) {
        log.i('✅ Dati scritti su USB');
        return true;
      }

      log.e('Nessuna conferma dal lettore');
      return false;
    } catch (e) {
      log.e('Errore write USB', e);
      return false;
    }
  }

  /// Leggi da USB (implementazione completa)
  Future<SmartcardData?> readUsb() async {
    try {
      log.i('📖 Lettura da USB...');

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
      await Future.delayed(const Duration(milliseconds: 500));
      final response = await port.read();
      await port.close();

      if (response.isEmpty || response[0] != 0x06) {
        log.e('Errore lettura USB');
        return null;
      }

      final length = (response[1] << 8) | response[2];
      final dataBytes = response.sublist(3, 3 + length);
      final dataString = utf8.decode(dataBytes);

      final result = SmartcardData.fromEncryptedString(dataString);
      log.i('✅ Dati letti da USB');
      return result;
    } catch (e) {
      log.e('Errore read USB', e);
      return null;
    }
  }
}
