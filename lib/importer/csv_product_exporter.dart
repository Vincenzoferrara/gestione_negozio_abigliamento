// CSV Product Exporter - Esporta prodotti WooCommerce in formato CSV
//
// Permette di:
// - Esportare tutti i prodotti o una selezione
// - Scegliere quali campi includere
// - Gestire encoding e formati
// - Esportare con gerarchia categorie

import 'dart:io';
import 'package:csv/csv.dart';
import '../prodotti/class_prodotti.dart';
import '../login/jwt_api/query_woocommerce/woo_query_prodotti.dart';
import '../log_viewer/app_logger.dart';

/// Opzioni export CSV
class CsvExportOptions {
  final List<String> fieldsToInclude; // Campi da includere (vuoto = tutti)
  final bool includeVariations; // Include varianti prodotto
  final bool includeCategories; // Include categorie
  final bool includeTags; // Include tag
  final bool useHierarchicalCategories; // Usa formato Parent>Child per categorie
  final String fieldDelimiter; // Delimitatore campi (default: ,)
  final String textDelimiter; // Delimitatore testo (default: ")
  final bool includeHeaders; // Include intestazioni

  const CsvExportOptions({
    this.fieldsToInclude = const [],
    this.includeVariations = false,
    this.includeCategories = true,
    this.includeTags = true,
    this.useHierarchicalCategories = true,
    this.fieldDelimiter = ',',
    this.textDelimiter = '"',
    this.includeHeaders = true,
  });
}

/// Risultato export
class CsvExportResult {
  final String filePath;
  final int productsExported;
  final int rowsGenerated;
  final List<String> errors;

  CsvExportResult({
    required this.filePath,
    required this.productsExported,
    required this.rowsGenerated,
    required this.errors,
  });

  bool get hasErrors => errors.isNotEmpty;
}

/// CSV Product Exporter
class CsvProductExporter {
  final WooQueryProdotti _productQuery = WooQueryProdotti();

  /// Esporta prodotti in CSV
  Future<CsvExportResult> exportProducts({
    List<ProdottoWoo>? products, // Se null, scarica tutti i prodotti
    required String outputPath,
    CsvExportOptions options = const CsvExportOptions(),
    void Function(int current, int total)? onProgress,
  }) async {
    try {
      log.i('📤 Inizio export prodotti in CSV: $outputPath');

      // 1. Ottieni lista prodotti
      List<ProdottoWoo> productsToExport;
      if (products != null) {
        productsToExport = products;
      } else {
        log.i('📥 Download prodotti da WooCommerce...');
        productsToExport = await _downloadAllProducts(onProgress);
      }

      if (productsToExport.isEmpty) {
        throw Exception('Nessun prodotto da esportare');
      }

      log.i('📊 Esporto ${productsToExport.length} prodotti');

      // 2. Converti prodotti in righe CSV
      final csvData = await _convertProductsToCsv(
        productsToExport,
        options,
        onProgress,
      );

      // 3. Genera CSV string
      final csvString = const ListToCsvConverter(
        fieldDelimiter: ',',
        textDelimiter: '"',
        eol: '\n',
      ).convert(csvData);

      // 4. Scrivi file
      final file = File(outputPath);
      await file.writeAsString(csvString, flush: true);

      log.i('✅ Export completato: ${productsToExport.length} prodotti → ${csvData.length - 1} righe');

      return CsvExportResult(
        filePath: outputPath,
        productsExported: productsToExport.length,
        rowsGenerated: csvData.length - 1, // -1 per header
        errors: [],
      );

    } catch (e, stack) {
      log.e('❌ Errore export CSV', e, stack);
      return CsvExportResult(
        filePath: outputPath,
        productsExported: 0,
        rowsGenerated: 0,
        errors: [e.toString()],
      );
    }
  }

  /// Download tutti i prodotti da WooCommerce
  Future<List<ProdottoWoo>> _downloadAllProducts(
    void Function(int current, int total)? onProgress,
  ) async {
    final allProducts = <ProdottoWoo>[];
    int page = 1;
    const perPage = 100;
    bool hasMore = true;

    while (hasMore) {
      try {
        final products = await _productQuery.getProducts(
          page: page,
          perPage: perPage,
        );

        if (products.isEmpty) {
          hasMore = false;
        } else {
          allProducts.addAll(products);
          onProgress?.call(allProducts.length, allProducts.length);

          log.d('📥 Scaricati ${allProducts.length} prodotti (pagina $page)');
          page++;

          // Se ricevuti meno di perPage, è l'ultima pagina
          if (products.length < perPage) {
            hasMore = false;
          }
        }
      } catch (e) {
        log.e('❌ Errore download prodotti pagina $page', e);
        hasMore = false;
      }
    }

    return allProducts;
  }

  /// Converte prodotti in righe CSV
  Future<List<List<String>>> _convertProductsToCsv(
    List<ProdottoWoo> products,
    CsvExportOptions options,
    void Function(int current, int total)? onProgress,
  ) async {
    final rows = <List<String>>[];

    // Determina campi da includere
    final fields = options.fieldsToInclude.isNotEmpty
        ? options.fieldsToInclude
        : _getAllFields();

    // 1. Header
    if (options.includeHeaders) {
      rows.add(fields);
    }

    // 2. Righe dati
    for (int i = 0; i < products.length; i++) {
      final product = products[i];
      onProgress?.call(i + 1, products.length);

      try {
        final row = _convertProductToRow(product, fields, options);
        rows.add(row);

        // TODO: Gestione varianti se richiesto
        // if (options.includeVariations && product.varianti.isNotEmpty) {
        //   for (final variation in product.varianti) {
        //     final varRow = _convertVariationToRow(product, variation, fields, options);
        //     rows.add(varRow);
        //   }
        // }
      } catch (e) {
        log.w('⚠️ Errore conversione prodotto ${product.id}: $e');
      }
    }

    return rows;
  }

  /// Converte singolo prodotto in riga CSV
  List<String> _convertProductToRow(
    ProdottoWoo product,
    List<String> fields,
    CsvExportOptions options,
  ) {
    final row = <String>[];

    for (final field in fields) {
      final value = _getFieldValue(product, field, options);
      row.add(value);
    }

    return row;
  }

  /// Ottiene valore campo dal prodotto
  String _getFieldValue(
    ProdottoWoo product,
    String field,
    CsvExportOptions options,
  ) {
    switch (field) {
      case 'id':
        return product.id.toString();

      case 'name':
        return product.nome;

      case 'sku':
        return product.sku;

      case 'regular_price':
        return product.prezzoNormale.toString();

      case 'sale_price':
        return product.prezzoScontato?.toString() ?? '';

      case 'description':
        return product.descrizioneCompleta ?? '';

      case 'short_description':
        return product.descrizioneBreve;

      case 'categories':
        if (!options.includeCategories) return '';
        // Formato semplice o gerarchico
        return product.categoria; // TODO: Implementare gerarchia se necessario

      case 'tags':
        if (!options.includeTags) return '';
        return product.tag.join(', ');

      case 'images':
        final images = <String>[];
        if (product.immagineUrl.isNotEmpty) {
          images.add(product.immagineUrl);
        }
        images.addAll(product.immaginiAggiuntive);
        return images.join('|');

      case 'stock_quantity':
        return product.quantitaTotale?.toString() ?? '';

      case 'stock_status':
        return product.inStock ? 'instock' : 'outofstock';

      case 'manage_stock':
        return product.quantitaTotale != null ? 'yes' : 'no';

      case 'weight':
        return product.peso ?? '';

      case 'length':
        return product.dimensioni?.lunghezza.toString() ?? '';

      case 'width':
        return product.dimensioni?.larghezza.toString() ?? '';

      case 'height':
        return product.dimensioni?.altezza.toString() ?? '';

      case 'type':
        return 'simple'; // TODO: Gestire prodotti variabili

      case 'status':
        return product.status ?? 'publish';

      case 'published':
        return product.status == 'publish' ? 'yes' : 'no';

      case 'featured':
        return 'no'; // TODO: Aggiungere campo featured in ProdottoWoo

      default:
        return '';
    }
  }

  /// Ottiene lista di tutti i campi disponibili
  List<String> _getAllFields() {
    return [
      'id',
      'name',
      'sku',
      'regular_price',
      'sale_price',
      'description',
      'short_description',
      'categories',
      'tags',
      'images',
      'stock_quantity',
      'stock_status',
      'manage_stock',
      'weight',
      'length',
      'width',
      'height',
      'type',
      'status',
      'published',
      'featured',
    ];
  }

  /// Export rapido (tutti i prodotti, tutti i campi)
  Future<CsvExportResult> quickExport(String outputPath) async {
    return await exportProducts(
      outputPath: outputPath,
      options: const CsvExportOptions(),
    );
  }

  /// Export custom con selezione prodotti
  Future<CsvExportResult> exportSelectedProducts(
    List<int> productIds,
    String outputPath, {
    CsvExportOptions options = const CsvExportOptions(),
  }) async {
    // Download prodotti selezionati
    final products = <ProdottoWoo>[];
    for (final id in productIds) {
      try {
        final product = await _productQuery.getProductById(id);
        products.add(product);
      } catch (e) {
        log.w('⚠️ Impossibile scaricare prodotto $id: $e');
      }
    }

    return await exportProducts(
      products: products,
      outputPath: outputPath,
      options: options,
    );
  }
}
