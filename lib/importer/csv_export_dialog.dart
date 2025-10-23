// CSV Export Dialog - Interfaccia per esportazione prodotti in CSV

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'csv_product_exporter.dart';
import '../log_viewer/app_logger.dart';

class CsvExportDialog extends StatefulWidget {
  final List<int>? selectedProductIds; // Se specificato, esporta solo questi

  const CsvExportDialog({
    super.key,
    this.selectedProductIds,
  });

  @override
  State<CsvExportDialog> createState() => _CsvExportDialogState();
}

class _CsvExportDialogState extends State<CsvExportDialog> {
  bool _isExporting = false;
  double _progress = 0.0;
  int _currentProduct = 0;
  int _totalProducts = 0;
  CsvExportResult? _result;

  // Opzioni export
  bool _includeCategories = true;
  bool _includeTags = true;
  bool _includeVariations = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            if (_result == null) ...[
              _buildOptions(),
              const SizedBox(height: 24),
              _buildActions(),
            ] else ...[
              _buildResult(),
            ],
            if (_isExporting) ...[
              const SizedBox(height: 20),
              _buildProgress(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          _result != null && !_result!.hasErrors
              ? Icons.check_circle
              : Icons.file_download,
          color: _result != null && !_result!.hasErrors
              ? Colors.green
              : Theme.of(context).primaryColor,
          size: 32,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _result != null
                    ? 'Export Completato'
                    : 'Esporta Prodotti in CSV',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                widget.selectedProductIds != null
                    ? 'Esporta ${widget.selectedProductIds!.length} prodotti selezionati'
                    : 'Esporta tutti i prodotti',
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

  Widget _buildOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Opzioni Export:',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Includi categorie'),
          subtitle: const Text('Esporta categorie prodotti'),
          value: _includeCategories,
          onChanged: (value) => setState(() => _includeCategories = value),
        ),
        SwitchListTile(
          title: const Text('Includi tag'),
          subtitle: const Text('Esporta tag prodotti'),
          value: _includeTags,
          onChanged: (value) => setState(() => _includeTags = value),
        ),
        SwitchListTile(
          title: const Text('Includi varianti'),
          subtitle: const Text('Esporta anche le varianti dei prodotti'),
          value: _includeVariations,
          onChanged: (value) => setState(() => _includeVariations = value),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: _isExporting ? null : () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _isExporting ? null : _startExport,
          icon: const Icon(Icons.download),
          label: const Text('Esporta CSV'),
        ),
      ],
    );
  }

  Widget _buildProgress() {
    return Column(
      children: [
        LinearProgressIndicator(value: _progress),
        const SizedBox(height: 8),
        Text(
          'Esportazione in corso: $_currentProduct / $_totalProducts prodotti',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildResult() {
    final result = _result!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: result.hasErrors
            ? Colors.red.withOpacity(0.1)
            : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: result.hasErrors ? Colors.red : Colors.green,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.hasErrors ? Icons.error : Icons.check_circle,
                color: result.hasErrors ? Colors.red : Colors.green,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.hasErrors
                      ? 'Export completato con errori'
                      : 'Export completato con successo!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: result.hasErrors ? Colors.red : Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Prodotti esportati: ${result.productsExported}'),
          Text('Righe CSV generate: ${result.rowsGenerated}'),
          Text('File: ${result.filePath.split('/').last}'),
          if (result.hasErrors) ...[
            const SizedBox(height: 8),
            Text(
              'Errori: ${result.errors.length}',
              style: const TextStyle(color: Colors.red),
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  Future<void> _startExport() async {
    // Chiedi dove salvare
    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Salva export CSV',
      fileName: 'prodotti_export_${DateTime.now().millisecondsSinceEpoch}.csv',
      allowedExtensions: ['csv'],
      type: FileType.custom,
    );

    if (outputPath == null) {
      return; // Utente ha annullato
    }

    setState(() {
      _isExporting = true;
      _progress = 0.0;
    });

    try {
      final exporter = CsvProductExporter();
      final options = CsvExportOptions(
        includeCategories: _includeCategories,
        includeTags: _includeTags,
        includeVariations: _includeVariations,
      );

      final result = widget.selectedProductIds != null
          ? await exporter.exportSelectedProducts(
              widget.selectedProductIds!,
              outputPath,
              options: options,
            )
          : await exporter.exportProducts(
              outputPath: outputPath,
              options: options,
              onProgress: (current, total) {
                setState(() {
                  _currentProduct = current;
                  _totalProducts = total;
                  _progress = current / total;
                });
              },
            );

      setState(() {
        _result = result;
        _isExporting = false;
      });

      log.i('✅ Export CSV completato: ${result.productsExported} prodotti');
    } catch (e) {
      setState(() {
        _isExporting = false;
      });

      log.e('❌ Errore export CSV', e);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
