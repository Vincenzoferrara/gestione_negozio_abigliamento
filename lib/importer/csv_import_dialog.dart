// CSV Import Dialog - Interfaccia per importazione prodotti da CSV
//
// Dialog modale che permette di:
// - Selezionare file CSV
// - Configurare opzioni import
// - Monitorare progresso
// - Visualizzare risultati

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'csv_product_parser.dart';
import 'product_importer.dart';
import '../log_viewer/app_logger.dart';

class CsvImportDialog extends StatefulWidget {
  const CsvImportDialog({super.key});

  @override
  State<CsvImportDialog> createState() => _CsvImportDialogState();
}

class _CsvImportDialogState extends State<CsvImportDialog> {
  // Stati del dialog
  ImportStep _currentStep = ImportStep.selectFile;
  String? _selectedFilePath;
  CsvParseResult? _parseResult;
  ImportOptions _options = const ImportOptions();
  ImportStats? _importStats;
  bool _isProcessing = false;
  Map<String, String>? _customMapping; // Mapping personalizzato dall'utente

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 700,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            Expanded(child: _buildContent()),
            const SizedBox(height: 16),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.upload_file,
          color: Theme.of(context).primaryColor,
          size: 32,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Importa Prodotti da CSV',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                _getStepDescription(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  String _getStepDescription() {
    switch (_currentStep) {
      case ImportStep.selectFile:
        return 'Passo 1: Seleziona il file CSV';
      case ImportStep.mapColumns:
        return 'Passo 2: Mapping colonne';
      case ImportStep.configure:
        return 'Passo 3: Configura opzioni import';
      case ImportStep.preview:
        return 'Passo 4: Anteprima dati';
      case ImportStep.importing:
        return 'Import in corso...';
      case ImportStep.complete:
        return 'Import completato!';
    }
  }

  Widget _buildContent() {
    switch (_currentStep) {
      case ImportStep.selectFile:
        return _buildFileSelection();
      case ImportStep.mapColumns:
        return _buildColumnMapping();
      case ImportStep.configure:
        return _buildOptionsConfiguration();
      case ImportStep.preview:
        return _buildDataPreview();
      case ImportStep.importing:
        return _buildImportProgress();
      case ImportStep.complete:
        return _buildImportResults();
    }
  }

  Widget _buildColumnMapping() {
    if (_parseResult == null) return const Center(child: CircularProgressIndicator());

    // Inizializza mapping se non presente
    _customMapping ??= Map<String, String>.from(
      ColumnMapping.autoDetect(_parseResult!.headers).mapping
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Mapping Colonne CSV',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Le colonne sono state mappate automaticamente. Puoi modificare il mapping se necessario.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Mapping Colonne:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          // Lista colonne CSV con dropdown per scegliere campo WooCommerce
          ..._parseResult!.headers.map((header) {
            final currentMapping = _customMapping![header] ?? 'non_mappato';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Colonna CSV
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Colonna CSV',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            header,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.arrow_forward, size: 20),
                    const SizedBox(width: 16),
                    // Campo WooCommerce (dropdown)
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        value: currentMapping,
                        decoration: const InputDecoration(
                          labelText: 'Campo prodotto',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _getWooCommerceFields().map((field) {
                          return DropdownMenuItem(
                            value: field.key,
                            child: Text(
                              field.label,
                              style: TextStyle(
                                fontSize: 13,
                                color: field.required ? Colors.red.shade700 : null,
                                fontWeight: field.required ? FontWeight.bold : null,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _customMapping![header] = newValue!;
                          });
                        },
                        isExpanded: true,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 16),
          // Pulsanti preset
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _resetMapping,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reset Auto'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _clearMapping,
                icon: const Icon(Icons.clear, size: 18),
                label: const Text('Pulisci Tutti'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Ottiene lista campi WooCommerce disponibili
  List<WooCommerceField> _getWooCommerceFields() {
    return [
      WooCommerceField('non_mappato', '(Non mappare)', required: false),
      WooCommerceField('name', 'Nome prodotto *', required: true),
      WooCommerceField('sku', 'SKU', required: false),
      WooCommerceField('regular_price', 'Prezzo normale *', required: true),
      WooCommerceField('sale_price', 'Prezzo scontato', required: false),
      WooCommerceField('description', 'Descrizione completa', required: false),
      WooCommerceField('short_description', 'Descrizione breve', required: false),
      WooCommerceField('categories', 'Categorie', required: false),
      WooCommerceField('tags', 'Tag', required: false),
      WooCommerceField('images', 'URL Immagini', required: false),
      WooCommerceField('local_image_path', 'Path Immagini Locali', required: false),
      WooCommerceField('stock_quantity', 'Quantità stock', required: false),
      WooCommerceField('stock_status', 'Stato stock', required: false),
      WooCommerceField('manage_stock', 'Gestisci stock', required: false),
      WooCommerceField('weight', 'Peso', required: false),
      WooCommerceField('length', 'Lunghezza', required: false),
      WooCommerceField('width', 'Larghezza', required: false),
      WooCommerceField('height', 'Altezza', required: false),
      WooCommerceField('type', 'Tipo prodotto', required: false),
      WooCommerceField('published', 'Pubblicato', required: false),
      WooCommerceField('featured', 'In evidenza', required: false),
    ];
  }

  /// Reset mapping all'auto-detect
  void _resetMapping() {
    setState(() {
      _customMapping = Map<String, String>.from(
        ColumnMapping.autoDetect(_parseResult!.headers).mapping
      );
    });
  }

  /// Pulisce tutto il mapping
  void _clearMapping() {
    setState(() {
      _customMapping = Map<String, String>.fromIterables(
        _parseResult!.headers,
        List.filled(_parseResult!.headers.length, 'non_mappato'),
      );
    });
  }

  Widget _buildFileSelection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.file_upload_outlined,
            size: 80,
            color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 20),
          if (_selectedFilePath != null) ...[
            Text(
              'File selezionato:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _selectedFilePath!.split('/').last,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Text(
              'Nessun file selezionato',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _selectFile,
            icon: const Icon(Icons.folder_open),
            label: const Text('Seleziona File CSV'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
          if (_selectedFilePath != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _isProcessing ? null : _parseFile,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward),
              label: Text(_isProcessing ? 'Analisi in corso...' : 'Continua'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionsConfiguration() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Opzioni Import',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildOptionTile(
            'Aggiorna prodotti esistenti',
            'Se un prodotto con lo stesso SKU esiste già, aggiornalo',
            _options.updateExisting,
            (value) => setState(() {
              _options = ImportOptions(
                updateExisting: value,
                skipDuplicates: _options.skipDuplicates,
                uploadImages: _options.uploadImages,
                publishProducts: _options.publishProducts,
                batchSize: _options.batchSize,
                maxConcurrent: _options.maxConcurrent,
                timeoutSeconds: _options.timeoutSeconds,
              );
            }),
          ),
          _buildOptionTile(
            'Salta duplicati',
            'Ignora prodotti con SKU già esistente',
            _options.skipDuplicates,
            (value) => setState(() {
              _options = ImportOptions(
                updateExisting: _options.updateExisting,
                skipDuplicates: value,
                uploadImages: _options.uploadImages,
                publishProducts: _options.publishProducts,
                batchSize: _options.batchSize,
                maxConcurrent: _options.maxConcurrent,
                timeoutSeconds: _options.timeoutSeconds,
              );
            }),
          ),
          _buildOptionTile(
            'Carica immagini automaticamente',
            'Upload immagini da path locali (colonna "local_image_path")',
            _options.uploadImages,
            (value) => setState(() {
              _options = ImportOptions(
                updateExisting: _options.updateExisting,
                skipDuplicates: _options.skipDuplicates,
                uploadImages: value,
                publishProducts: _options.publishProducts,
                batchSize: _options.batchSize,
                maxConcurrent: _options.maxConcurrent,
                timeoutSeconds: _options.timeoutSeconds,
              );
            }),
          ),
          _buildOptionTile(
            'Pubblica prodotti',
            'Rendi i prodotti visibili sul sito (altrimenti salvati come bozze)',
            _options.publishProducts,
            (value) => setState(() {
              _options = ImportOptions(
                updateExisting: _options.updateExisting,
                skipDuplicates: _options.skipDuplicates,
                uploadImages: _options.uploadImages,
                publishProducts: value,
                batchSize: _options.batchSize,
                maxConcurrent: _options.maxConcurrent,
                timeoutSeconds: _options.timeoutSeconds,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildDataPreview() {
    if (_parseResult == null) return const Center(child: CircularProgressIndicator());

    final hasBlockingErrors = _parseResult!.hasBlockingErrors;
    final validationErrors = _parseResult!.validationErrors;
    final errorsByRow = <int, List<RowValidationError>>{};

    // Raggruppa errori per riga
    for (final error in validationErrors) {
      errorsByRow.putIfAbsent(error.rowNumber, () => []).add(error);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: hasBlockingErrors ? Colors.red.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: hasBlockingErrors ? Colors.red : Colors.blue),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    hasBlockingErrors ? Icons.error : Icons.info,
                    color: hasBlockingErrors ? Colors.red : Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Riepilogo Validazione',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: hasBlockingErrors ? Colors.red : Colors.blue,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Totale righe: ${_parseResult!.totalRows}'),
              Text('Righe valide: ${_parseResult!.validRows}',
                  style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
              if (_parseResult!.invalidRows > 0)
                Text('Righe con errori: ${_parseResult!.invalidRows}',
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              Text('Avvisi: ${validationErrors.where((e) => e.severity == ValidationSeverity.warning).length}',
                  style: const TextStyle(color: Colors.orange)),
              Text('Info: ${validationErrors.where((e) => e.severity == ValidationSeverity.info).length}',
                  style: const TextStyle(color: Colors.grey)),
              Text('Colonne: ${_parseResult!.headers.length}'),
              if (hasBlockingErrors) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Attenzione: Alcune righe contengono errori bloccanti. Questi prodotti non verranno importati.',
                          style: TextStyle(fontSize: 11, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Prime 5 righe:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            child: DataTable(
              columns: _parseResult!.headers
                  .take(5)
                  .map((h) => DataColumn(label: Text(h, style: const TextStyle(fontWeight: FontWeight.bold))))
                  .toList(),
              rows: _parseResult!.rows.take(5).map((row) {
                return DataRow(
                  cells: _parseResult!.headers.take(5).map((h) {
                    return DataCell(Text(row[h]?.toString() ?? '-'));
                  }).toList(),
                );
              }).toList(),
            ),
          ),
        ),
        if (validationErrors.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Errori di Validazione:',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView(
              shrinkWrap: true,
              children: errorsByRow.entries.take(10).map((entry) {
                final rowNumber = entry.key;
                final errors = entry.value;
                final hasError = errors.any((e) => e.severity == ValidationSeverity.error);

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: hasError ? Colors.red.withValues(alpha: 0.05) : Colors.orange.withValues(alpha: 0.05),
                  child: ExpansionTile(
                    leading: Icon(
                      hasError ? Icons.error : Icons.warning,
                      color: hasError ? Colors.red : Colors.orange,
                      size: 20,
                    ),
                    title: Text(
                      'Riga $rowNumber (${errors.length} ${errors.length == 1 ? 'problema' : 'problemi'})',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: hasError ? Colors.red : Colors.orange,
                      ),
                    ),
                    children: errors.map((error) {
                      Color color;
                      IconData icon;
                      switch (error.severity) {
                        case ValidationSeverity.error:
                          color = Colors.red;
                          icon = Icons.error;
                          break;
                        case ValidationSeverity.warning:
                          color = Colors.orange;
                          icon = Icons.warning;
                          break;
                        case ValidationSeverity.info:
                          color = Colors.blue;
                          icon = Icons.info;
                          break;
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(icon, color: color, size: 14),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${error.field}: ${error.error}',
                                    style: TextStyle(fontSize: 11, color: color),
                                  ),
                                  if (error.value != null)
                                    Text(
                                      'Valore: "${error.value}"',
                                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
            ),
          ),
          if (errorsByRow.length > 10)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '... e altre ${errorsByRow.length - 10} righe con errori',
                style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ),
        ],
        if (_parseResult!.errors.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    const Text('Errori di parsing:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                ..._parseResult!.errors.take(3).map((e) => Text('• $e', style: const TextStyle(fontSize: 11))),
                if (_parseResult!.errors.length > 3)
                  Text('... e altri ${_parseResult!.errors.length - 3} errori', style: const TextStyle(fontSize: 11)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImportProgress() {
    final stats = _importStats;
    if (stats == null) return const Center(child: CircularProgressIndicator());

    final progress = stats.total > 0 ? (stats.imported + stats.updated + stats.failed + stats.skipped) / stats.total : 0.0;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 12,
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '${(progress * 100).toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '${stats.imported + stats.updated + stats.failed + stats.skipped} / ${stats.total} prodotti',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatChip('Importati', stats.imported, Colors.green),
              const SizedBox(width: 8),
              _buildStatChip('Aggiornati', stats.updated, Colors.blue),
              const SizedBox(width: 8),
              _buildStatChip('Saltati', stats.skipped, Colors.orange),
              const SizedBox(width: 8),
              _buildStatChip('Errori', stats.failed, Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
          ),
          Text(
            value.toString(),
            style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildImportResults() {
    final stats = _importStats;
    if (stats == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green),
            ),
            child: Column(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 64),
                const SizedBox(height: 16),
                Text(
                  'Import Completato!',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tasso di successo: ${stats.successRate.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildStatRow('Totale prodotti:', stats.total.toString()),
          _buildStatRow('Importati:', stats.imported.toString(), color: Colors.green),
          _buildStatRow('Aggiornati:', stats.updated.toString(), color: Colors.blue),
          _buildStatRow('Saltati:', stats.skipped.toString(), color: Colors.orange),
          _buildStatRow('Errori:', stats.failed.toString(), color: Colors.red),
          const Divider(height: 32),
          _buildStatRow('Tempo impiegato:', '${stats.elapsedTime.inSeconds}s'),
          _buildStatRow('Velocità:', '${stats.productsPerSecond.toStringAsFixed(2)} prod/s'),
          if (stats.errors.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Errori (primi 5):',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
            ),
            const SizedBox(height: 8),
            ...stats.errors.take(5).map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $e', style: const TextStyle(fontSize: 12, color: Colors.red)),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep != ImportStep.selectFile && _currentStep != ImportStep.importing && _currentStep != ImportStep.complete)
          TextButton.icon(
            onPressed: _goBack,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Indietro'),
          )
        else
          const SizedBox.shrink(),
        Row(
          children: [
            if (_currentStep == ImportStep.complete)
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(true), // Indica che l'import è avvenuto
                child: const Text('Chiudi'),
              )
            else if (_currentStep != ImportStep.selectFile && _currentStep != ImportStep.importing) ...[
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annulla'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _goNext,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_forward),
                label: Text(_getNextButtonLabel()),
              ),
            ],
          ],
        ),
      ],
    );
  }

  String _getNextButtonLabel() {
    if (_isProcessing) return 'Elaborazione...';

    switch (_currentStep) {
      case ImportStep.mapColumns:
        return 'Applica Mapping';
      case ImportStep.preview:
        return 'Avvia Import';
      default:
        return 'Continua';
    }
  }

  Future<void> _selectFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      dialogTitle: 'Seleziona file CSV',
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFilePath = result.files.single.path;
      });
    }
  }


  Future<void> _parseFile() async {
    if (_selectedFilePath == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final parser = CsvProductParser(filePath: _selectedFilePath!);
      final result = await parser.parse();

      setState(() {
        _parseResult = result;
        _currentStep = ImportStep.mapColumns; // Vai al mapping colonne
        _isProcessing = false;
      });

      log.i('File CSV parsato: ${result.rows.length} righe valide');
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore parsing CSV: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      log.e('Errore parsing CSV', e);
    }
  }

  void _goBack() {
    setState(() {
      if (_currentStep == ImportStep.mapColumns) {
        _currentStep = ImportStep.selectFile;
      } else if (_currentStep == ImportStep.configure) {
        _currentStep = ImportStep.mapColumns;
      } else if (_currentStep == ImportStep.preview) {
        _currentStep = ImportStep.configure;
      }
    });
  }

  void _goNext() {
    setState(() {
      if (_currentStep == ImportStep.mapColumns) {
        // Riparse con mapping personalizzato
        _reparseWithCustomMapping();
      } else if (_currentStep == ImportStep.configure) {
        _currentStep = ImportStep.preview;
      } else if (_currentStep == ImportStep.preview) {
        _startImport();
      }
    });
  }

  /// Riparse CSV con mapping personalizzato
  Future<void> _reparseWithCustomMapping() async {
    if (_selectedFilePath == null || _customMapping == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final parser = CsvProductParser(filePath: _selectedFilePath!);
      final customColumnMapping = ColumnMapping(_customMapping!);
      final result = await parser.parse(customMapping: customColumnMapping);

      setState(() {
        _parseResult = result;
        _currentStep = ImportStep.configure;
        _isProcessing = false;
      });

      log.i('CSV riparsato con mapping personalizzato: ${result.rows.length} righe');
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore re-parsing CSV: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      log.e('Errore re-parsing CSV', e);
    }
  }

  Future<void> _startImport() async {
    if (_parseResult == null) return;

    setState(() {
      _currentStep = ImportStep.importing;
      _importStats = ImportStats();
    });

    try {
      final importer = ProductImporter(
        options: _options,
        onProgress: (stats) {
          if (mounted) {
            setState(() {
              _importStats = stats;
            });
          }
        },
      );

      final finalStats = await importer.importProducts(_parseResult!.rows);

      setState(() {
        _importStats = finalStats;
        _currentStep = ImportStep.complete;
      });

      log.i('Import completato: ${finalStats.imported} importati, ${finalStats.failed} falliti');
    } catch (e) {
      log.e('Errore import', e);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante import: $e'),
            backgroundColor: Colors.red,
          ),
        );

        setState(() {
          _currentStep = ImportStep.preview;
        });
      }
    }
  }
}

enum ImportStep {
  selectFile,
  mapColumns,  // Nuovo step per mapping colonne
  configure,
  preview,
  importing,
  complete,
}

/// Campo WooCommerce per dropdown mapping
class WooCommerceField {
  final String key;
  final String label;
  final bool required;

  WooCommerceField(this.key, this.label, {this.required = false});
}
