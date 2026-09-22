import 'package:flutter/material.dart';
import 'package:report_flutter/report_flutter.dart';
import '../notification/notification_service.dart';
import '../theme/theme.dart';
import '../prodotti/class_prodotti.dart';
import 'report.code.dart';

class EtichettePage extends StatefulWidget {
  const EtichettePage({super.key});

  @override
  State<EtichettePage> createState() => _EtichettePageState();
}

class _EtichettePageState extends State<EtichettePage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  final EtichetteController _controller = EtichetteService().controller;

  // Report Designer
  late ReportTemplate _reportTemplate;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Inizializza template di default
    _reportTemplate = ReportTemplate(
      id: 'etichetta_default',
      name: 'Etichetta Prodotto',
      itemWidth: 50,
      itemHeight: 30,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final customColors = Theme.of(context).extension<AppColorExtension>()!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Etichette'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.create), text: 'Crea'),
            Tab(icon: Icon(Icons.preview), text: 'Visualizza'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCreaTab(customColors),
          _buildVisualizzaTab(customColors),
        ],
      ),
    );
  }

  /// Tab per creare la grafica di una singola etichetta con il designer drag-and-drop
  Widget _buildCreaTab(AppColorExtension customColors) {
    return ReportBuilder(
      template: _reportTemplate,
      sampleData: ProdottoGlobal(),
      onTemplateChanged: (template) {
        setState(() => _reportTemplate = template);
      },
      onSave: (template) {
        NotificationService.instance.messageBar(
          'successo',
          'report',
          'Template "${template.name}" salvato!',
        );
        // TODO: Salvare template su storage
      },
    );
  }

  /// Tab per visualizzare la coda di stampa
  Widget _buildVisualizzaTab(AppColorExtension customColors) {
    final etichette = _controller.etichetteDaStampare;

    return Column(
      children: [
        // Barra azioni
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Coda di stampa: ${etichette.length} etichette',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              if (etichette.isNotEmpty) ...[
                ElevatedButton.icon(
                  onPressed: _stampaEtichette,
                  icon: const Icon(Icons.print),
                  label: const Text('Stampa'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _esportaPdf,
                  icon: const Icon(Icons.save),
                  label: const Text('Esporta PDF'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _svuotaCoda,
                  icon: const Icon(Icons.delete_sweep),
                  tooltip: 'Svuota coda',
                  color: customColors.errorColorStatus,
                ),
              ],
            ],
          ),
        ),

        const Divider(height: 1),

        // Lista etichette
        Expanded(
          child: etichette.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.label_off,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nessuna etichetta in coda',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Aggiungi etichette dalla tab "Crea"',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: etichette.length,
                  itemBuilder: (context, index) {
                    final etichetta = etichette[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text('${index + 1}')),
                        title: Text(etichetta.nome),
                        subtitle: Text(
                          '${etichetta.prezzo.toStringAsFixed(2)} EUR${etichetta.barcodeInterno != null ? ' - Barcode interno: ${etichetta.barcodeInterno}' : ''}',
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.delete,
                            color: customColors.errorColorStatus,
                          ),
                          onPressed: () => _rimuoviEtichetta(index),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _rimuoviEtichetta(int index) {
    _controller.rimuoviEtichetta(index);
    setState(() {});
  }

  void _svuotaCoda() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Svuota coda'),
        content: const Text(
          'Sei sicuro di voler rimuovere tutte le etichette dalla coda?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              _controller.svuotaCoda();
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Svuota'),
          ),
        ],
      ),
    );
  }

  Future<void> _stampaEtichette() async {
    try {
      await _controller.stampa();
    } catch (e) {
      if (mounted) {
        NotificationService.instance.messageBar(
          'errore',
          'report',
          'Errore durante la stampa: $e',
        );
      }
    }
  }

  Future<void> _esportaPdf() async {
    try {
      final filePath = await _controller.esportaPdf();
      if (mounted) {
        NotificationService.instance.messageBar(
          'successo',
          'report',
          'PDF salvato: $filePath',
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationService.instance.messageBar(
          'errore',
          'report',
          'Errore durante l\'esportazione: $e',
        );
      }
    }
  }
}
