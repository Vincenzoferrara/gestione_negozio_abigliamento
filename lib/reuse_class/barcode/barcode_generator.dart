import 'dart:math';

import 'package:barcode/barcode.dart';

/// Generatore di codici barcode interni per i prodotti.
///
/// Produce un valore numerico compatibile con la simbologia Code128 (la
/// stessa usata dal sistema di etichette in `lib/report`), composto da:
///
/// - una parte casuale di [lunghezzaParteCasuale] cifre;
/// - la data/ora attuale in cifre fisse `DDMMYYYYHHMMSS` + `SSS`
///   (giorno, mese, anno, ore, minuti, secondi e millisecondi).
///
/// La data/ora incorporata rende il codice praticamente univoco anche tra
/// generazioni ravvicinate e su dispositivi diversi; la parte casuale copre
/// il caso estremo di due generazioni nello stesso istante (stesso
/// millisecondo). Il generatore esclude i valori gia in uso nel modulo.
///
/// La validazione del valore avviene tramite il plugin `barcode`
/// (`Barcode.code128().isValid(...)`), lo stesso pacchetto usato da
/// `pdf`/`printing` per stampare i barcode sulle etichette.
class BarcodeGenerator {
  BarcodeGenerator._();

  /// Cifre della parte casuale del codice.
  static const int lunghezzaParteCasuale = 13;

  /// Cifre della data/ora: 8 (`DDMMYYYY`) + 6 (`HHMMSS`) + 3 (millisecondi).
  static const int lunghezzaDataOra = 17;

  /// Lunghezza totale del codice generato.
  static const int lunghezza = lunghezzaParteCasuale + lunghezzaDataOra;

  /// Numero massimo di tentativi prima di rinunciare.
  static const int _maxTentativi = 50;

  /// Genera un codice Code128 unico rispetto a [esclusi].
  ///
  /// [esclusi] contiene i valori gia in uso nel modulo; i valori vuoti o
  /// composti solo da spazi vengono ignorati. Restituisce `null` se non
  /// trova un valore libero valido entro [_maxTentativi] tentativi.
  ///
  /// [random] e [now] permettono di iniettare un generatore e un orologio
  /// deterministici nei test.
  static String? generaCode128({
    required Set<String> esclusi,
    Random? random,
    DateTime? now,
  }) {
    final usati = esclusi
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();

    final rng = random ?? Random.secure();
    final code128 = Barcode.code128();
    final suffissoDataOra = _suffissoDataOra(now ?? DateTime.now());

    for (int tentativo = 0; tentativo < _maxTentativi; tentativo++) {
      final parteCasuale = List.generate(
        lunghezzaParteCasuale,
        (_) => rng.nextInt(10),
      ).join();
      final value = '$parteCasuale$suffissoDataOra';
      if (usati.contains(value)) continue;
      if (!code128.isValid(value)) continue;
      return value;
    }

    return null;
  }

  /// Data/ora in cifre fisse: `DDMMYYYYHHMMSS` + `SSS` millisecondi.
  static String _suffissoDataOra(DateTime now) {
    String due(int value) => value.toString().padLeft(2, '0');
    return '${due(now.day)}${due(now.month)}${now.year.toString().padLeft(4, '0')}'
        '${due(now.hour)}${due(now.minute)}${due(now.second)}'
        '${now.millisecond.toString().padLeft(3, '0')}';
  }
}
