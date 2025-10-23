// CSV Template Generator - Genera template CSV per import prodotti
//
// Fornisce template CSV con:
// - Header con tutti i campi disponibili
// - Righe di esempio con dati validi
// - Commenti/note su formati richiesti

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../log_viewer/app_logger.dart';

/// Generatore template CSV per import prodotti WooCommerce
class CsvTemplateGenerator {
  /// Genera template CSV base (solo header)
  static String generateBasicTemplate() {
    final headers = [
      'name',
      'sku',
      'regular_price',
      'sale_price',
      'description',
      'short_description',
      'categories',
      'tags',
      'images',
      'local_image_path',
      'stock_quantity',
      'stock_status',
      'weight',
      'length',
      'width',
      'height',
      'type',
      'published',
      'featured',
    ];

    return headers.join(',') + '\n';
  }

  /// Genera template CSV con esempi
  static String generateTemplateWithExamples() {
    final rows = <List<String>>[];

    // Header
    rows.add([
      'name',
      'sku',
      'regular_price',
      'sale_price',
      'description',
      'short_description',
      'categories',
      'tags',
      'images',
      'local_image_path',
      'stock_quantity',
      'stock_status',
      'weight',
      'length',
      'width',
      'height',
      'type',
      'published',
      'featured',
    ]);

    // Esempio 1: Prodotto semplice con prezzo normale
    rows.add([
      'Maglietta Rossa',
      'MAG-001',
      '29.99',
      '',
      'Maglietta 100% cotone, comoda e traspirante',
      'Maglietta rossa cotone',
      'Abbigliamento>Magliette',
      'cotone, estate, casual',
      'https://example.com/image1.jpg',
      '',
      '50',
      'instock',
      '0.2',
      '30',
      '40',
      '2',
      'simple',
      'yes',
      'no',
    ]);

    // Esempio 2: Prodotto in offerta con immagine locale
    rows.add([
      'Jeans Blu',
      'JEAN-002',
      '79.99',
      '59.99',
      'Jeans slim fit in denim elasticizzato',
      'Jeans blu elasticizzati',
      'Abbigliamento>Pantaloni',
      'denim, slim fit',
      '',
      '/path/to/image/jeans.jpg',
      '30',
      'instock',
      '0.5',
      '100',
      '80',
      '3',
      'simple',
      'yes',
      'yes',
    ]);

    // Esempio 3: Prodotto senza stock
    rows.add([
      'Giacca Invernale',
      'GIAC-003',
      '149.99',
      '',
      'Giacca imbottita per l\'inverno, impermeabile',
      'Giacca invernale calda',
      'Abbigliamento>Giacche',
      'inverno, impermeabile',
      'https://example.com/giacca1.jpg|https://example.com/giacca2.jpg',
      '',
      '0',
      'outofstock',
      '0.8',
      '70',
      '60',
      '10',
      'simple',
      'no',
      'no',
    ]);

    // Converti in CSV
    return _rowsToCsv(rows);
  }

  /// Genera template CSV con tutti i campi e note
  static String generateFullTemplateWithNotes() {
    final buffer = StringBuffer();

    // Note informative (come commenti, non valide in CSV standard ma utili)
    buffer.writeln('# Template Import Prodotti WooCommerce');
    buffer.writeln('# Campi obbligatori: name, sku, regular_price');
    buffer.writeln('# Formati:');
    buffer.writeln('#   - Prezzi: formato decimale con punto (es: 29.99)');
    buffer.writeln('#   - Categorie: separate da virgola o con gerarchia (es: Abbigliamento>Magliette)');
    buffer.writeln('#   - Tag: separati da virgola (es: cotone, estate)');
    buffer.writeln('#   - Immagini: URL separati da | (es: url1.jpg|url2.jpg)');
    buffer.writeln('#   - Stock status: instock, outofstock, onbackorder');
    buffer.writeln('#   - Published: yes/no, true/false, 1/0');
    buffer.writeln('#');

    // Template vero e proprio
    buffer.write(generateTemplateWithExamples());

    return buffer.toString();
  }

  /// Salva template CSV su file
  static Future<File> saveTemplateToFile({
    bool withExamples = true,
    bool withNotes = false,
    String? customPath,
  }) async {
    try {
      // Genera contenuto
      String content;
      if (withNotes) {
        content = generateFullTemplateWithNotes();
      } else if (withExamples) {
        content = generateTemplateWithExamples();
      } else {
        content = generateBasicTemplate();
      }

      // Determina path
      final File file;
      if (customPath != null) {
        file = File(customPath);
      } else {
        final directory = await getDownloadsDirectory() ??
                         await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        file = File('${directory.path}/woocommerce_import_template_$timestamp.csv');
      }

      // Scrivi file
      await file.writeAsString(content, flush: true);

      log.i('✅ Template CSV salvato: ${file.path}');
      return file;

    } catch (e, stack) {
      log.e('❌ Errore salvataggio template CSV', e, stack);
      rethrow;
    }
  }

  /// Converte lista di righe in formato CSV
  static String _rowsToCsv(List<List<String>> rows) {
    final buffer = StringBuffer();

    for (final row in rows) {
      // Escape virgolette e wrappa campi con virgola/newline
      final escapedRow = row.map((field) {
        if (field.contains(',') || field.contains('"') || field.contains('\n')) {
          return '"${field.replaceAll('"', '""')}"';
        }
        return field;
      }).join(',');

      buffer.writeln(escapedRow);
    }

    return buffer.toString();
  }

  /// Genera template per categoria specifica
  static String generateCategoryTemplate(String category) {
    switch (category.toLowerCase()) {
      case 'abbigliamento':
        return _generateClothingTemplate();
      case 'elettronica':
        return _generateElectronicsTemplate();
      case 'libri':
        return _generateBooksTemplate();
      default:
        return generateTemplateWithExamples();
    }
  }

  static String _generateClothingTemplate() {
    final rows = <List<String>>[];

    rows.add([
      'name',
      'sku',
      'regular_price',
      'sale_price',
      'description',
      'short_description',
      'categories',
      'tags',
      'stock_quantity',
      'weight',
    ]);

    rows.add([
      'Maglietta Cotone Bianca',
      'MAG-WHT-001',
      '19.99',
      '',
      'Maglietta in cotone 100% organico',
      'Maglietta bianca cotone',
      'Abbigliamento>Magliette',
      'cotone, bio, casual',
      '100',
      '0.15',
    ]);

    return _rowsToCsv(rows);
  }

  static String _generateElectronicsTemplate() {
    final rows = <List<String>>[];

    rows.add([
      'name',
      'sku',
      'regular_price',
      'description',
      'categories',
      'stock_quantity',
      'weight',
      'length',
      'width',
      'height',
    ]);

    rows.add([
      'Cuffie Bluetooth Pro',
      'CUFF-BT-001',
      '89.99',
      'Cuffie wireless con cancellazione del rumore',
      'Elettronica>Audio',
      '25',
      '0.3',
      '20',
      '18',
      '8',
    ]);

    return _rowsToCsv(rows);
  }

  static String _generateBooksTemplate() {
    final rows = <List<String>>[];

    rows.add([
      'name',
      'sku',
      'regular_price',
      'description',
      'short_description',
      'categories',
      'tags',
      'weight',
    ]);

    rows.add([
      'Guida alla Programmazione Flutter',
      'BOOK-FLUTTER-001',
      '29.99',
      'Guida completa allo sviluppo app con Flutter',
      'Libro Flutter',
      'Libri>Programmazione',
      'flutter, dart, mobile',
      '0.5',
    ]);

    return _rowsToCsv(rows);
  }
}
