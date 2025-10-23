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
  bool _isLoading = false;
  int _totalLines = 0;
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
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _copyToClipboard() {
    if (_logContent.isEmpty) return;

    Clipboard.setData(ClipboardData(text: _logContent));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('$_totalLines righe copiate negli appunti'),
          ],
        ),
        backgroundColor: Theme.of(context).extension<AppColorExtension>()!.successColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _clearLogs() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma cancellazione'),
        content: const Text('Sei sicuro di voler cancellare tutti i log?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).extension<AppColorExtension>()!.errorColorStatus),
            child: const Text('Cancella'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await log.clearAllLogs();
      await _loadLogFiles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.delete, color: Colors.white),
                SizedBox(width: 8),
                Text('Log cancellati con successo'),
              ],
            ),
            backgroundColor: Theme.of(context).extension<AppColorExtension>()!.warningColor,
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
                    '$_totalLines righe',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          // Copia
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copia tutto',
            onPressed: _logContent.isNotEmpty ? _copyToClipboard : null,
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
          // Selettore file di log
          if (_logFiles.length > 1)
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
              child: Row(
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
            ),

          // Contenuto log
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _logContent.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nessun log disponibile',
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
                              _logContent,
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
