import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gestione_negozio_abigliamento/theme/theme.dart';
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
      setState(() {
        _logFiles = files;
        if (files.isNotEmpty && _selectedFile == null) {
          _selectedFile = files.first;
          _loadLogContent();
        }
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadLogContent() async {
    if (_selectedFile == null) return;

    setState(() => _isLoading = true);
    try {
      final content = await log.readLogFile(_selectedFile!);
      final lines = content.split('\n').where((line) => line.isNotEmpty).toList();

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

    // Cattura il tema prima delle operazioni
    final appColors = Theme.of(context).extension<AppColorExtension>();
    final colorScheme = Theme.of(context).colorScheme;

    Clipboard.setData(ClipboardData(text: _filteredContent));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('$_filteredLines righe copiate negli appunti'),
          ],
        ),
        backgroundColor: appColors?.successColor ?? colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.delete, color: Colors.white),
                SizedBox(width: 8),
                Text('Contenuto log cancellato'),
              ],
            ),
            backgroundColor: appColors?.warningColor ?? colorScheme.errorContainer,
            behavior: SnackBarBehavior.floating,
          ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
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
                                Icon(Icons.bug_report, size: 18, color: Colors.blue),
                                const SizedBox(width: 8),
                                const Text('DEBUG'),
                              ],
                            ),
                          ),
                          DropdownMenuItem<LogLevel?>(
                            value: LogLevel.warning,
                            child: Row(
                              children: [
                                Icon(Icons.warning, size: 18, color: Colors.orange),
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
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
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
