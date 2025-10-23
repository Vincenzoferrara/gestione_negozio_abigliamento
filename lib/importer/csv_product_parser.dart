// CSV Product Parser - Equivalente a WC_Product_CSV_Importer di WooCommerce
//
// Gestisce il parsing dei file CSV per l'importazione prodotti
// Implementa la stessa logica di WooCommerce:
// - Lettura e validazione CSV
// - Mapping colonne flessibile
// - Parse campi specializzati
// - Gestione encoding UTF-8

import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import '../log_viewer/app_logger.dart';

/// Errore di validazione per una specifica riga
class RowValidationError {
  final int rowNumber;
  final String field;
  final String error;
  final String? value;
  final ValidationSeverity severity;

  RowValidationError({
    required this.rowNumber,
    required this.field,
    required this.error,
    this.value,
    this.severity = ValidationSeverity.error,
  });

  @override
  String toString() => 'Riga $rowNumber - $field: $error${value != null ? ' (valore: "$value")' : ''}';
}

/// Severità errore validazione
enum ValidationSeverity {
  error,   // Blocca import
  warning, // Avviso ma può procedere
  info,    // Solo informativo
}

/// Risultato del parsing CSV
class CsvParseResult {
  final List<String> headers;
  final List<Map<String, dynamic>> rows;
  final List<String> errors; // Errori parsing generici
  final List<RowValidationError> validationErrors; // Errori validazione specifici
  final int totalRows;
  final int validRows; // Righe che passano validazione
  final int invalidRows; // Righe con errori bloccanti

  CsvParseResult({
    required this.headers,
    required this.rows,
    required this.errors,
    required this.validationErrors,
    required this.totalRows,
  }) : validRows = rows.length - validationErrors.where((e) => e.severity == ValidationSeverity.error).length,
       invalidRows = validationErrors.where((e) => e.severity == ValidationSeverity.error).length;

  /// Controlla se ci sono errori bloccanti
  bool get hasBlockingErrors => validationErrors.any((e) => e.severity == ValidationSeverity.error);

  /// Ottiene errori per una specifica riga
  List<RowValidationError> getErrorsForRow(int rowNumber) {
    return validationErrors.where((e) => e.rowNumber == rowNumber).toList();
  }
}

/// Mapping colonna CSV → campo prodotto WooCommerce
class ColumnMapping {
  final Map<String, String> mapping;

  ColumnMapping(this.mapping);

  /// Mapping predefinito (auto-detect)
  static final Map<String, List<String>> defaultMappings = {
    'name': ['nome', 'name', 'product name', 'titolo', 'title'],
    'sku': ['sku', 'codice', 'code', 'product code'],
    'regular_price': ['prezzo', 'price', 'regular price', 'prezzo normale', 'regular_price'],
    'sale_price': ['prezzo scontato', 'sale price', 'sconto', 'sale_price'],
    'description': ['descrizione', 'description', 'descrizione completa', 'full description'],
    'short_description': ['descrizione breve', 'short description', 'short_description'],
    'categories': ['categoria', 'categories', 'category', 'categorie'],
    'tags': ['tag', 'tags', 'etichette'],
    'images': ['immagine', 'image', 'images', 'foto', 'immagini'],
    'stock_quantity': ['stock', 'quantità', 'quantity', 'stock_quantity', 'giacenza'],
    'stock_status': ['stato stock', 'stock status', 'stock_status', 'disponibilità'],
    'weight': ['peso', 'weight'],
    'length': ['lunghezza', 'length'],
    'width': ['larghezza', 'width'],
    'height': ['altezza', 'height'],
    'type': ['tipo', 'type', 'product type'],
    'published': ['pubblicato', 'published', 'status', 'stato'],
    'featured': ['in evidenza', 'featured'],
    'manage_stock': ['gestisci stock', 'manage stock', 'manage_stock'],
    'local_image_path': ['path immagine', 'local image', 'image path', 'foto locale'],
  };

  /// Auto-detect mapping da headers CSV
  static ColumnMapping autoDetect(List<String> headers) {
    final Map<String, String> detected = {};

    for (final header in headers) {
      final normalized = header.trim().toLowerCase();

      // Cerca corrispondenza nei mapping predefiniti
      for (final entry in defaultMappings.entries) {
        if (entry.value.contains(normalized)) {
          detected[header] = entry.key;
          log.d('📋 Auto-mapped: "$header" → "${entry.key}"');
          break;
        }
      }

      // Se non trovato, mantieni header originale
      if (!detected.containsKey(header)) {
        detected[header] = header.toLowerCase().replaceAll(' ', '_');
      }
    }

    return ColumnMapping(detected);
  }
}

/// Parser CSV per prodotti WooCommerce
/// Implementa la stessa logica di WC_Product_CSV_Importer
class CsvProductParser {
  final String filePath;
  ColumnMapping? _mapping;

  // Configurazione parsing
  String fieldDelimiter;
  String textDelimiter;
  String? textEnclosure;

  // Stato parsing
  int _currentPosition = 0;
  int _totalBytes = 0;

  CsvProductParser({
    required this.filePath,
    this.fieldDelimiter = ',',
    this.textDelimiter = '"',
    this.textEnclosure,
  });

  /// Ottiene la posizione corrente nel file (per progress tracking)
  int get currentPosition => _currentPosition;

  /// Ottiene la dimensione totale del file
  int get totalBytes => _totalBytes;

  /// Calcola percentuale completamento
  double getPercentComplete() {
    if (_totalBytes == 0) return 0;
    return (_currentPosition / _totalBytes) * 100;
  }

  /// Legge e parsea il file CSV
  /// Equivalente a WC_Product_CSV_Importer::read_file()
  Future<CsvParseResult> parse({ColumnMapping? customMapping}) async {
    try {
      log.i('📄 Inizio parsing CSV: $filePath');

      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File non trovato: $filePath');
      }

      _totalBytes = await file.length();
      log.d('📊 Dimensione file: $_totalBytes bytes');

      // Leggi contenuto file
      String content = await _readFileWithEncoding(file);

      // Rimuovi UTF-8 BOM se presente (come fa WooCommerce)
      content = _removeUtf8Bom(content);

      _currentPosition = content.length;

      // Parse CSV
      final List<List<dynamic>> csvData = const CsvToListConverter().convert(
        content,
        fieldDelimiter: fieldDelimiter,
        textDelimiter: textDelimiter,
        textEndDelimiter: textDelimiter,
        eol: '\n',
      );

      if (csvData.isEmpty) {
        throw Exception('File CSV vuoto');
      }

      // Prima riga = headers
      final List<String> headers = csvData.first.map((e) => e.toString().trim()).toList();
      log.i('📋 Headers trovati: ${headers.length}');

      // Auto-detect mapping se non fornito
      _mapping = customMapping ?? ColumnMapping.autoDetect(headers);

      // Parse righe dati
      final List<Map<String, dynamic>> rows = [];
      final List<String> errors = [];
      final List<RowValidationError> validationErrors = [];

      for (int i = 1; i < csvData.length; i++) {
        try {
          final rowNumber = i + 1; // +1 per mostrare numero riga nel file (incluso header)
          final row = _parseRow(headers, csvData[i]);

          if (row.isNotEmpty) {
            // Valida riga
            final rowErrors = _validateRow(row, rowNumber);
            validationErrors.addAll(rowErrors);

            // Aggiungi sempre la riga (anche se ha errori)
            // Sarà il ProductImporter a decidere se saltarla
            rows.add(row);
          }
        } catch (e) {
          final errorMsg = 'Errore riga ${i + 1}: $e';
          log.w(errorMsg);
          errors.add(errorMsg);
        }
      }

      log.i('✅ Parsing completato: ${rows.length} righe totali, ${validationErrors.length} errori validazione');

      return CsvParseResult(
        headers: headers,
        rows: rows,
        errors: errors,
        validationErrors: validationErrors,
        totalRows: csvData.length - 1, // Esclude header
      );

    } catch (e, stack) {
      log.e('❌ Errore parsing CSV', e, stack);
      rethrow;
    }
  }

  /// Legge file gestendo encoding
  /// Equivalente a WC_Product_CSV_Importer::adjust_character_encoding()
  Future<String> _readFileWithEncoding(File file) async {
    try {
      // Prova UTF-8
      return await file.readAsString(encoding: utf8);
    } catch (e) {
      log.w('⚠️ Encoding UTF-8 fallito, provo Latin1');
      // Fallback a Latin1
      final bytes = await file.readAsBytes();
      return latin1.decode(bytes);
    }
  }

  /// Rimuove UTF-8 BOM (Byte Order Mark)
  /// Equivalente a remove_utf8_bom in WooCommerce
  String _removeUtf8Bom(String content) {
    if (content.isNotEmpty && content.codeUnitAt(0) == 0xFEFF) {
      log.d('🔧 Rimosso UTF-8 BOM');
      return content.substring(1);
    }
    return content;
  }

  /// Parsea una singola riga CSV
  Map<String, dynamic> _parseRow(List<String> headers, List<dynamic> values) {
    final Map<String, dynamic> row = {};

    for (int i = 0; i < headers.length && i < values.length; i++) {
      final header = headers[i];
      final mappedKey = _mapping?.mapping[header] ?? header;
      final rawValue = values[i]?.toString().trim() ?? '';

      if (rawValue.isEmpty) continue;

      // Parse valore in base al tipo di campo
      row[mappedKey] = _parseFieldValue(mappedKey, rawValue);
    }

    return row;
  }

  /// Parse valore campo in base al tipo
  /// Implementa i metodi parse_*_field di WooCommerce
  dynamic _parseFieldValue(String fieldName, String value) {
    // Bool fields
    if (fieldName == 'published' || fieldName == 'featured' ||
        fieldName == 'manage_stock' || fieldName.endsWith('?')) {
      return parseBoolField(value);
    }

    // Float/Decimal fields
    if (fieldName.contains('price') || fieldName == 'weight' ||
        fieldName == 'length' || fieldName == 'width' || fieldName == 'height') {
      return parseFloatField(value);
    }

    // Integer fields
    if (fieldName == 'stock_quantity' || fieldName == 'id') {
      return parseIntField(value);
    }

    // Array fields (comma separated)
    if (fieldName == 'images' || fieldName == 'tags' || fieldName == 'categories') {
      return parseCommaSeparatedField(value);
    }

    // Categories con gerarchia (Cat1>Cat2)
    if (fieldName == 'categories') {
      return parseCategoriesField(value);
    }

    // Default: string
    return value;
  }

  // ========================================================================
  // METODI DI PARSING SPECIALIZZATI (come WooCommerce)
  // ========================================================================

  /// Parse campo booleano
  /// Equivalente a WC_Product_CSV_Importer::parse_bool_field()
  bool parseBoolField(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized == '1' ||
           normalized == 'true' ||
           normalized == 'yes' ||
           normalized == 'si' ||
           normalized == 'sì';
  }

  /// Parse campo float/decimal
  /// Equivalente a WC_Product_CSV_Importer::parse_float_field()
  double parseFloatField(String value) {
    // Rimuovi simboli valuta
    String cleaned = value.replaceAll(RegExp(r'[€$£¥]'), '').trim();

    // Sostituisci virgola con punto (formato italiano → internazionale)
    cleaned = cleaned.replaceAll(',', '.');

    // Rimuovi spazi
    cleaned = cleaned.replaceAll(' ', '');

    return double.tryParse(cleaned) ?? 0.0;
  }

  /// Parse campo intero
  int parseIntField(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^\d-]'), '');
    return int.tryParse(cleaned) ?? 0;
  }

  /// Parse campo separato da virgole
  /// Equivalente a WC_Product_CSV_Importer::parse_comma_field()
  List<String> parseCommaSeparatedField(String value) {
    return value
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// Parse categorie con supporto gerarchia (Cat1>Cat2>Cat3)
  /// Equivalente a WC_Product_CSV_Importer::parse_categories_field()
  /// Supporta sia liste semplici ("Cat1, Cat2") che gerarchie ("Parent>Child>Subchild")
  List<String> parseCategoriesField(String value) {
    final categories = value
        .split(',')
        .map((cat) => cat.trim())
        .where((cat) => cat.isNotEmpty)
        .toList();

    // Espandi categorie gerarchiche
    final expandedCategories = <String>[];

    for (final category in categories) {
      if (category.contains('>')) {
        // Categoria gerarchica: "Parent>Child>Subchild"
        // Aggiungi tutte le parti della gerarchia
        final parts = category.split('>').map((p) => p.trim()).toList();

        // Costruisci path incrementale: "Parent", "Parent>Child", "Parent>Child>Subchild"
        for (int i = 0; i < parts.length; i++) {
          final hierarchyPath = parts.sublist(0, i + 1).join('>');
          if (!expandedCategories.contains(hierarchyPath)) {
            expandedCategories.add(hierarchyPath);
          }
        }
      } else {
        // Categoria semplice
        if (!expandedCategories.contains(category)) {
          expandedCategories.add(category);
        }
      }
    }

    return expandedCategories;
  }

  /// Parse immagini (URLs o path locali separati da virgola o |)
  /// Equivalente a WC_Product_CSV_Importer::parse_images_field()
  List<String> parseImagesField(String value) {
    // Supporta sia virgola che pipe come separatore
    final separator = value.contains('|') ? '|' : ',';

    return value
        .split(separator)
        .map((img) => img.trim())
        .where((img) => img.isNotEmpty)
        .toList();
  }

  /// Parse campo relativo (id:123 o SKU)
  /// Equivalente a WC_Product_CSV_Importer::parse_relative_field()
  dynamic parseRelativeField(String value) {
    if (value.startsWith('id:')) {
      return int.tryParse(value.substring(3));
    }
    return value; // SKU
  }

  /// Valida dati riga per campi obbligatori e best practices
  /// Restituisce lista di errori di validazione
  List<RowValidationError> _validateRow(Map<String, dynamic> row, int rowNumber) {
    final List<RowValidationError> errors = [];

    // Nome obbligatorio
    if (!row.containsKey('name') || row['name'].toString().trim().isEmpty) {
      errors.add(RowValidationError(
        rowNumber: rowNumber,
        field: 'name',
        error: 'Nome prodotto mancante o vuoto',
        value: row['name']?.toString(),
        severity: ValidationSeverity.error,
      ));
    } else {
      // Verifica lunghezza minima nome
      final name = row['name'].toString();
      if (name.length < 3) {
        errors.add(RowValidationError(
          rowNumber: rowNumber,
          field: 'name',
          error: 'Nome prodotto troppo corto (minimo 3 caratteri)',
          value: name,
          severity: ValidationSeverity.warning,
        ));
      }
    }

    // SKU obbligatorio (WooCommerce può auto-generarlo, ma meglio averlo)
    if (!row.containsKey('sku') || row['sku'].toString().trim().isEmpty) {
      errors.add(RowValidationError(
        rowNumber: rowNumber,
        field: 'sku',
        error: 'SKU mancante (verrà auto-generato)',
        value: row['sku']?.toString(),
        severity: ValidationSeverity.warning,
      ));
    }

    // Prezzo obbligatorio
    if (!row.containsKey('regular_price')) {
      errors.add(RowValidationError(
        rowNumber: rowNumber,
        field: 'regular_price',
        error: 'Prezzo mancante',
        severity: ValidationSeverity.error,
      ));
    } else {
      final price = row['regular_price'];
      if (price is num && price <= 0) {
        errors.add(RowValidationError(
          rowNumber: rowNumber,
          field: 'regular_price',
          error: 'Prezzo deve essere maggiore di zero',
          value: price.toString(),
          severity: ValidationSeverity.error,
        ));
      }
    }

    // Prezzo scontato non può essere maggiore del prezzo normale
    if (row.containsKey('sale_price') && row.containsKey('regular_price')) {
      final salePrice = row['sale_price'];
      final regularPrice = row['regular_price'];

      if (salePrice is num && regularPrice is num && salePrice > regularPrice) {
        errors.add(RowValidationError(
          rowNumber: rowNumber,
          field: 'sale_price',
          error: 'Prezzo scontato ($salePrice) maggiore del prezzo normale ($regularPrice)',
          value: '$salePrice > $regularPrice',
          severity: ValidationSeverity.error,
        ));
      }
    }

    // Validazione stock
    if (row.containsKey('stock_quantity')) {
      final stock = row['stock_quantity'];
      if (stock is num && stock < 0) {
        errors.add(RowValidationError(
          rowNumber: rowNumber,
          field: 'stock_quantity',
          error: 'Quantità stock non può essere negativa',
          value: stock.toString(),
          severity: ValidationSeverity.error,
        ));
      }
    }

    // Validazione peso
    if (row.containsKey('weight')) {
      final weight = row['weight'];
      if (weight is num && weight < 0) {
        errors.add(RowValidationError(
          rowNumber: rowNumber,
          field: 'weight',
          error: 'Peso non può essere negativo',
          value: weight.toString(),
          severity: ValidationSeverity.warning,
        ));
      }
    }

    // Validazione dimensioni
    for (final dimension in ['length', 'width', 'height']) {
      if (row.containsKey(dimension)) {
        final value = row[dimension];
        if (value is num && value < 0) {
          errors.add(RowValidationError(
            rowNumber: rowNumber,
            field: dimension,
            error: 'Dimensione non può essere negativa',
            value: value.toString(),
            severity: ValidationSeverity.warning,
          ));
        }
      }
    }

    // Info: Prodotto senza immagini
    if (!row.containsKey('images') && !row.containsKey('local_image_path')) {
      errors.add(RowValidationError(
        rowNumber: rowNumber,
        field: 'images',
        error: 'Nessuna immagine specificata',
        severity: ValidationSeverity.info,
      ));
    }

    // Info: Prodotto senza categoria
    if (!row.containsKey('categories') || row['categories'].toString().isEmpty) {
      errors.add(RowValidationError(
        rowNumber: rowNumber,
        field: 'categories',
        error: 'Nessuna categoria specificata (verrà usata "Senza categoria")',
        severity: ValidationSeverity.info,
      ));
    }

    return errors;
  }

  /// Valida dati riga (metodo pubblico per compatibilità)
  @Deprecated('Usare _validateRow invece')
  bool validateRow(Map<String, dynamic> row, List<String> errors) {
    final validationErrors = _validateRow(row, 0);
    final blockingErrors = validationErrors.where((e) => e.severity == ValidationSeverity.error);

    for (final error in blockingErrors) {
      errors.add(error.toString());
    }

    return blockingErrors.isEmpty;
  }
}
