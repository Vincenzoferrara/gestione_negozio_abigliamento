import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gestione_negozio_abigliamento/theme/theme.dart';
import '../notification/notification_service.dart';
import '../login/jwt_api/adapter/platform_manager.dart';
import '../prodotti/class_prodotti.dart';
import 'app_logger.dart';

/// Schermata per visualizzare i log dell'applicazione
class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({super.key});

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  List<File> _logFiles = [];
  File? _selectedFile;
  String _logContent = '';
  String _filteredContent = '';
  bool _isLoading = false;
  int _totalLines = 0;
  int _filteredLines = 0;
  LogLevel? _selectedLogLevel; // null = mostra tutto
  final ScrollController _scrollController = ScrollController();
  bool _isRunningDiagnostics = false;
  String? _diagnosticResult;

  @override
  void initState() {
    super.initState();
    _loadLogFiles();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLogFiles() async {
    setState(() => _isLoading = true);
    try {
      final files = await log.getAllLogFiles();
      final uniqueByPath = <String, File>{};
      for (final file in files) {
        uniqueByPath[file.path] = file;
      }
      final dedupedFiles = uniqueByPath.values.toList()
        ..sort((a, b) => b.path.compareTo(a.path));

      File? nextSelected;
      final selectedPath = _selectedFile?.path;
      if (selectedPath != null) {
        for (final file in dedupedFiles) {
          if (file.path == selectedPath) {
            nextSelected = file;
            break;
          }
        }
      }
      nextSelected ??= dedupedFiles.isNotEmpty ? dedupedFiles.first : null;

      setState(() {
        _logFiles = dedupedFiles;
        _selectedFile = nextSelected;
      });

      if (_selectedFile != null) {
        await _loadLogContent();
      } else {
        setState(() {
          _logContent = '';
          _filteredContent = '';
          _totalLines = 0;
          _filteredLines = 0;
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadLogContent() async {
    if (_selectedFile == null) return;

    setState(() => _isLoading = true);
    try {
      final content = await log.readLogFile(_selectedFile!);
      final lines = content
          .split('\n')
          .where((line) => line.isNotEmpty)
          .toList();

      setState(() {
        _logContent = content;
        _totalLines = lines.length;
        _applyFilter();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    if (_selectedLogLevel == null) {
      // Mostra tutto
      _filteredContent = _logContent;
      _filteredLines = _totalLines;
      return;
    }

    final lines = _logContent.split('\n');
    final filteredLines = <String>[];

    // Determina il pattern da cercare in base al livello
    String levelPattern;
    switch (_selectedLogLevel!) {
      case LogLevel.debug:
        levelPattern = '[DEBUG  ]';
        break;
      case LogLevel.warning:
        levelPattern = '[WARNING]';
        break;
      case LogLevel.error:
        levelPattern = '[ERROR  ]';
        break;
    }

    for (final line in lines) {
      if (line.contains(levelPattern)) {
        filteredLines.add(line);
      }
    }

    _filteredContent = filteredLines.join('\n');
    _filteredLines = filteredLines.length;
  }

  void _setLogLevelFilter(LogLevel? level) {
    setState(() {
      _selectedLogLevel = level;
      _applyFilter();
    });
  }

  void _copyToClipboard() {
    if (_filteredContent.isEmpty) return;

    Clipboard.setData(ClipboardData(text: _filteredContent));
    NotificationService.instance.messageBar(
      'successo',
      'log_viewer',
      '$_filteredLines righe copiate negli appunti',
    );
  }

  Future<void> _clearLogs() async {
    // Cattura il tema PRIMA del dialog per evitare problemi di context
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorExtension>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Conferma cancellazione'),
        content: const Text('Sei sicuro di voler cancellare tutti i log?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: appColors?.errorColorStatus ?? colorScheme.error,
            ),
            child: const Text('Cancella'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await log.clearAllLogs();
      // Ricarica il contenuto del file corrente (ora vuoto)
      await _loadLogContent();
      if (mounted) {
        NotificationService.instance.messageBar(
          'warning',
          'log_viewer',
          'Contenuto log cancellato',
        );
      }
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _runWooCreateDiagnostic() async {
    if (_isRunningDiagnostics) return;

    if (!PlatformManager.isReady) {
      if (!mounted) return;
      NotificationService.instance.messageBar(
        'errore',
        'log_viewer',
        'Connessione WooCommerce non pronta.',
      );
      return;
    }

    setState(() {
      _isRunningDiagnostics = true;
      _diagnosticResult = null;
    });

    final startedAt = DateTime.now();
    final suffix = startedAt.millisecondsSinceEpoch.toString();
    final productSku = 'MGTEST-P-$suffix';
    final variantSku = 'MGTEST-V-$suffix';
    final productName = 'MGTEST Prodotto $suffix';
    int? createdProductId;

    log.d('DIAG_START sku=$productSku variantSku=$variantSku');

    try {
      final testProduct = ProdottoGlobal(
        nome: productName,
        sku: productSku,
        prezzoNormale: 9.99,
        descrizioneBreve: 'Prodotto diagnostico generato automaticamente',
        descrizioneCompleta: 'Prodotto diagnostico per test creazione/verifica',
        status: 'draft',
        inStock: false,
        quantitaTotale: 0,
        varianti: [
          VarianteProductGlobal(
            nome: 'Variante Diagnostica',
            sku: variantSku,
            prezzo: 9.99,
            quantita: 3,
            attributi: [AttributoVariante(nome: 'COLORE', opzione: 'BLU')],
          ),
        ],
      );

      final created = await PlatformManager.prodotti.createProduct(testProduct);
      createdProductId = created.id;
      log.d(
        'DIAG_CREATE_PRODUCT_OK productId=${created.id} sku=${created.sku}',
      );

      final fetchedProduct = await PlatformManager.prodotti.getProductById(
        created.id!,
      );
      final fetchedVariations = await PlatformManager.varianti.getAllVariations(
        created.id!,
      );

      final productExists = (fetchedProduct.id ?? 0) > 0;
      final variantExists = fetchedVariations.any(
        (v) => v.sku.trim().toLowerCase() == variantSku.toLowerCase(),
      );
      final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;

      if (productExists && variantExists) {
        log.d(
          'DIAG_VERIFY_OK productId=${created.id} variants=${fetchedVariations.length} elapsedMs=$elapsedMs',
        );
        _diagnosticResult =
            'PASS: prodotto e variante creati e verificati (ID ${created.id}).';
      } else {
        log.e(
          'DIAG_VERIFY_FAIL productExists=$productExists variantExists=$variantExists productId=${created.id} fetchedVariants=${fetchedVariations.length}',
        );
        _diagnosticResult =
            'FAIL: verifica incompleta (prodotto=$productExists, variante=$variantExists).';
      }
    } catch (e, st) {
      log.e('DIAG_FAIL errore scenario diagnostico', e, st);
      _diagnosticResult = 'FAIL: errore diagnostico: $e';
    } finally {
      if (createdProductId != null) {
        try {
          final deleted = await PlatformManager.prodotti.deleteProduct(
            createdProductId,
            force: true,
          );
          log.d(
            'DIAG_CLEANUP_${deleted ? 'OK' : 'FAIL'} productId=$createdProductId',
          );
        } catch (e) {
          log.e('DIAG_CLEANUP_FAIL productId=$createdProductId', e);
        }
      }

      await _loadLogFiles();

      if (mounted) {
        setState(() {
          _isRunningDiagnostics = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Viewer'),
        actions: [
          // Numero righe
          if (_totalLines > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _selectedLogLevel == null
                        ? '$_totalLines righe'
                        : '$_filteredLines / $_totalLines righe',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          // Copia
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copia tutto',
            onPressed: _filteredContent.isNotEmpty ? _copyToClipboard : null,
          ),
          // Cancella
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Cancella log',
            onPressed: _clearLogs,
          ),
          // Ricarica
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Ricarica',
            onPressed: _loadLogFiles,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra filtri
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Column(
              children: [
                // Selettore file di log
                if (_logFiles.length > 1) ...[
                  Row(
                    children: [
                      const Icon(Icons.file_present),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButton<File>(
                          value: _selectedFile,
                          isExpanded: true,
                          items: _logFiles.map((file) {
                            final name = file.path.split('/').last;
                            return DropdownMenuItem(
                              value: file,
                              child: Text(name),
                            );
                          }).toList(),
                          onChanged: (file) {
                            if (file != null) {
                              setState(() => _selectedFile = file);
                              _loadLogContent();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                // Filtro livello log
                Row(
                  children: [
                    Icon(
                      Icons.filter_list,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Filtra per livello:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<LogLevel?>(
                        value: _selectedLogLevel,
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<LogLevel?>(
                            value: null,
                            child: Row(
                              children: [
                                Icon(Icons.all_inclusive, size: 18),
                                SizedBox(width: 8),
                                Text('Tutti i livelli'),
                              ],
                            ),
                          ),
                          DropdownMenuItem<LogLevel?>(
                            value: LogLevel.debug,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.bug_report,
                                  size: 18,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                const Text('DEBUG'),
                              ],
                            ),
                          ),
                          DropdownMenuItem<LogLevel?>(
                            value: LogLevel.warning,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning,
                                  size: 18,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 8),
                                const Text('WARNING'),
                              ],
                            ),
                          ),
                          DropdownMenuItem<LogLevel?>(
                            value: LogLevel.error,
                            child: Row(
                              children: [
                                Icon(Icons.error, size: 18, color: Colors.red),
                                const SizedBox(width: 8),
                                const Text('ERROR'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (level) => _setLogLevelFilter(level),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: _isRunningDiagnostics
                          ? null
                          : _runWooCreateDiagnostic,
                      icon: _isRunningDiagnostics
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.science_outlined),
                      label: Text(
                        _isRunningDiagnostics
                            ? 'Test diagnostico in corso...'
                            : 'Test Woo create+verify',
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _loadLogFiles,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Ricarica log'),
                    ),
                  ],
                ),
                if (_diagnosticResult != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _diagnosticResult!.startsWith('PASS')
                          ? Colors.green.withValues(alpha: 0.12)
                          : Colors.orange.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_diagnosticResult!),
                  ),
                ],
              ],
            ),
          ),

          // Contenuto log
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredContent.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _selectedLogLevel != null
                              ? Icons.filter_list_off
                              : Icons.description_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedLogLevel != null
                              ? 'Nessun log per il livello selezionato'
                              : 'Nessun log disponibile',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        child: SelectableText(
                          _filteredContent,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ),
                      // Pulsanti scroll
                      Positioned(
                        right: 16,
                        bottom: 80,
                        child: Column(
                          children: [
                            FloatingActionButton.small(
                              heroTag: 'scroll_top',
                              onPressed: _scrollToTop,
                              child: const Icon(Icons.arrow_upward),
                            ),
                            const SizedBox(height: 8),
                            FloatingActionButton.small(
                              heroTag: 'scroll_bottom',
                              onPressed: _scrollToBottom,
                              child: const Icon(Icons.arrow_downward),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
