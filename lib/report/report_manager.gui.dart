// Report GUI - Interfaccia principale per Report Builder e Viewer
//
// Gestisce la creazione, visualizzazione e gestione dei report

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'report_builder.dart';
import 'report_viewer.dart';
import '../log_viewer/app_logger.dart';

/// Pagina principale dei report
class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> with AutomaticKeepAliveClientMixin {
  final ReportFileService _fileService = ReportFileService();
  List<File> _savedReports = [];
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadSavedReports();
  }

  Future<void> _loadSavedReports() async {
    setState(() => _isLoading = true);
    try {
      final reports = await _fileService.listReports();
      setState(() {
        _savedReports = reports;
        _isLoading = false;
      });
    } catch (e) {
      log.e('Errore caricamento report salvati', e);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createNewReport() async {
    // Mostra dialog per selezionare il tipo di dati
    final dataType = await showDialog<String>(
      context: context,
      builder: (context) => const SelectDataTypeDialog(),
    );

    if (dataType == null) return;

    // Ottieni i campi disponibili per il tipo selezionato
    final fields = _getFieldsForDataType(dataType);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReportBuilderPage(
            availableFields: fields,
            onSave: (config) async {
              try {
                await _fileService.saveReport(config);
                await _loadSavedReports();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Report "${config.name}" salvato')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Errore: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
          ),
        ),
      );
    }
  }

  Future<void> _importReport() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['report'],
      );

      if (result != null && result.files.single.path != null) {
        final config = await _fileService.importReport(result.files.single.path!);

        // Salva nella directory dei report
        await _fileService.saveReport(config);
        await _loadSavedReports();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Report "${config.name}" importato')),
          );
        }
      }
    } catch (e) {
      log.e('Errore importazione report', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore importazione: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _openReport(File file) async {
    try {
      final config = await _fileService.loadReport(file);

      // Mostra dialog per caricare i dati
      if (mounted) {
        final data = await showDialog<List<Map<String, dynamic>>>(
          context: context,
          builder: (context) => LoadDataDialog(config: config),
        );

        if (data != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReportViewerPage(
                config: config,
                data: data,
              ),
            ),
          );
        }
      }
    } catch (e) {
      log.e('Errore apertura report', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _editReport(File file) async {
    try {
      final config = await _fileService.loadReport(file);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportBuilderPage(
              availableFields: config.fields,
              existingConfig: config,
              onSave: (newConfig) async {
                try {
                  // Elimina il vecchio file e salva il nuovo
                  await _fileService.deleteReport(file);
                  await _fileService.saveReport(newConfig);
                  await _loadSavedReports();
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Report "${newConfig.name}" aggiornato')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Errore: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      log.e('Errore modifica report', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteReport(File file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina Report'),
        content: const Text('Sei sicuro di voler eliminare questo report?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _fileService.deleteReport(file);
        await _loadSavedReports();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report eliminato')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  List<ReportField> _getFieldsForDataType(String dataType) {
    // Definisci i campi disponibili per ogni tipo di dati
    switch (dataType) {
      case 'prodotti':
        return const [
          ReportField(name: 'id', label: 'ID', type: int),
          ReportField(name: 'nome', label: 'Nome Prodotto', type: String),
          ReportField(name: 'sku', label: 'SKU', type: String),
          ReportField(name: 'prezzo', label: 'Prezzo', type: double),
          ReportField(name: 'prezzoScontato', label: 'Prezzo Scontato', type: double),
          ReportField(name: 'quantita', label: 'Quantità', type: int),
          ReportField(name: 'categoria', label: 'Categoria', type: String),
          ReportField(name: 'barcode', label: 'Barcode', type: String),
          ReportField(name: 'descrizione', label: 'Descrizione', type: String),
          ReportField(name: 'taglia', label: 'Taglia', type: String),
          ReportField(name: 'colore', label: 'Colore', type: String),
          ReportField(name: 'marca', label: 'Marca', type: String),
          ReportField(name: 'dataCreazione', label: 'Data Creazione', type: DateTime),
        ];
      case 'ordini':
        return const [
          ReportField(name: 'id', label: 'ID Ordine', type: int),
          ReportField(name: 'numero', label: 'Numero Ordine', type: String),
          ReportField(name: 'data', label: 'Data Ordine', type: DateTime),
          ReportField(name: 'stato', label: 'Stato', type: String),
          ReportField(name: 'totale', label: 'Totale', type: double),
          ReportField(name: 'cliente', label: 'Cliente', type: String),
          ReportField(name: 'email', label: 'Email', type: String),
          ReportField(name: 'telefono', label: 'Telefono', type: String),
          ReportField(name: 'indirizzo', label: 'Indirizzo', type: String),
          ReportField(name: 'metodoPagamento', label: 'Metodo Pagamento', type: String),
          ReportField(name: 'note', label: 'Note', type: String),
        ];
      case 'clienti':
        return const [
          ReportField(name: 'id', label: 'ID Cliente', type: int),
          ReportField(name: 'nome', label: 'Nome', type: String),
          ReportField(name: 'cognome', label: 'Cognome', type: String),
          ReportField(name: 'email', label: 'Email', type: String),
          ReportField(name: 'telefono', label: 'Telefono', type: String),
          ReportField(name: 'indirizzo', label: 'Indirizzo', type: String),
          ReportField(name: 'citta', label: 'Città', type: String),
          ReportField(name: 'cap', label: 'CAP', type: String),
          ReportField(name: 'totaleOrdini', label: 'Totale Ordini', type: int),
          ReportField(name: 'totaleSpeso', label: 'Totale Speso', type: double),
          ReportField(name: 'dataRegistrazione', label: 'Data Registrazione', type: DateTime),
        ];
      case 'fatture':
        return const [
          ReportField(name: 'numero', label: 'Numero Fattura', type: String),
          ReportField(name: 'data', label: 'Data', type: DateTime),
          ReportField(name: 'cliente', label: 'Cliente', type: String),
          ReportField(name: 'partitaIva', label: 'Partita IVA', type: String),
          ReportField(name: 'codiceFiscale', label: 'Codice Fiscale', type: String),
          ReportField(name: 'indirizzo', label: 'Indirizzo', type: String),
          ReportField(name: 'imponibile', label: 'Imponibile', type: double),
          ReportField(name: 'iva', label: 'IVA', type: double),
          ReportField(name: 'totale', label: 'Totale', type: double),
          ReportField(name: 'metodoPagamento', label: 'Metodo Pagamento', type: String),
          ReportField(name: 'scadenza', label: 'Scadenza', type: DateTime),
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Builder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload),
            onPressed: _importReport,
            tooltip: 'Importa Report',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSavedReports,
            tooltip: 'Aggiorna',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewReport,
        icon: const Icon(Icons.add),
        label: const Text('Nuovo Report'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedReports.isEmpty
              ? _buildEmptyState()
              : _buildReportsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Nessun report salvato',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea il tuo primo report',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createNewReport,
            icon: const Icon(Icons.add),
            label: const Text('Crea Report'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _savedReports.length,
      itemBuilder: (context, index) {
        final file = _savedReports[index];
        final fileName = file.path.split('/').last.replaceAll('.report', '');

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.description,
                color: Theme.of(context).primaryColor,
              ),
            ),
            title: Text(
              fileName.split('_').first,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: FutureBuilder<FileStat>(
              future: file.stat(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text(
                    'Modificato: ${_formatDate(snapshot.data!.modified)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'open':
                    _openReport(file);
                    break;
                  case 'edit':
                    _editReport(file);
                    break;
                  case 'delete':
                    _deleteReport(file);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'open',
                  child: ListTile(
                    leading: Icon(Icons.open_in_new),
                    title: Text('Apri'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Modifica'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Elimina', style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            onTap: () => _openReport(file),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Oggi ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Ieri';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} giorni fa';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// Dialog per selezionare il tipo di dati
class SelectDataTypeDialog extends StatelessWidget {
  const SelectDataTypeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seleziona Tipo Dati'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.inventory_2, color: Colors.blue),
            title: const Text('Prodotti'),
            subtitle: const Text('Etichette, listini, inventario'),
            onTap: () => Navigator.pop(context, 'prodotti'),
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart, color: Colors.green),
            title: const Text('Ordini'),
            subtitle: const Text('Documenti ordine, spedizioni'),
            onTap: () => Navigator.pop(context, 'ordini'),
          ),
          ListTile(
            leading: const Icon(Icons.people, color: Colors.orange),
            title: const Text('Clienti'),
            subtitle: const Text('Anagrafiche, report clienti'),
            onTap: () => Navigator.pop(context, 'clienti'),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long, color: Colors.purple),
            title: const Text('Fatture'),
            subtitle: const Text('Fatture, ricevute'),
            onTap: () => Navigator.pop(context, 'fatture'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
      ],
    );
  }
}

/// Dialog per caricare i dati nel report
class LoadDataDialog extends StatelessWidget {
  final ReportConfig config;

  const LoadDataDialog({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Carica Dati'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Come vuoi caricare i dati per questo report?'),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('Da Database'),
            subtitle: const Text('Carica dati dal sistema'),
            onTap: () {
              // TODO: Implementare caricamento da database
              // Per ora restituisce dati di esempio
              Navigator.pop(context, _getSampleData());
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_upload),
            title: const Text('Da File'),
            subtitle: const Text('Importa da CSV/JSON'),
            onTap: () async {
              // TODO: Implementare importazione da file
              Navigator.pop(context, _getSampleData());
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getSampleData() {
    // Dati di esempio per test
    return [
      {
        'id': 1,
        'nome': 'Prodotto Test 1',
        'sku': 'SKU001',
        'prezzo': 29.99,
        'quantita': 100,
        'categoria': 'Abbigliamento',
        'barcode': '1234567890123',
      },
      {
        'id': 2,
        'nome': 'Prodotto Test 2',
        'sku': 'SKU002',
        'prezzo': 49.99,
        'quantita': 50,
        'categoria': 'Accessori',
        'barcode': '1234567890124',
      },
      {
        'id': 3,
        'nome': 'Prodotto Test 3',
        'sku': 'SKU003',
        'prezzo': 19.99,
        'quantita': 200,
        'categoria': 'Abbigliamento',
        'barcode': '1234567890125',
      },
    ];
  }
}
