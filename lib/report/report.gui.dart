import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:report_flutter/report_flutter.dart';
import '../notification/notification_service.dart';
import '../theme/theme.dart';
import '../prodotti/class_prodotti.dart';
import 'class_report.dart';
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

  // Controllers per il form di creazione
  final _nomeController = TextEditingController();
  final _skuController = TextEditingController();
  final _prezzoController = TextEditingController();
  final _tagliaController = TextEditingController();
  final _coloreController = TextEditingController();

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
    _nomeController.dispose();
    _skuController.dispose();
    _prezzoController.dispose();
    _tagliaController.dispose();
    _coloreController.dispose();
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

  /// Costruisce l'anteprima visiva dell'etichetta
  Widget _buildAnteprimaEtichetta() {
    final settings = _controller.settings;
    final nome = _nomeController.text.isEmpty
        ? 'Nome Prodotto'
        : _nomeController.text;
    final sku = _skuController.text.isEmpty ? null : _skuController.text;
    final prezzo = double.tryParse(_prezzoController.text) ?? 0;
    final taglia = _tagliaController.text.isEmpty
        ? null
        : _tagliaController.text;
    final colore = _coloreController.text.isEmpty
        ? null
        : _coloreController.text;

    final etichetta = Etichetta(
      nome: nome,
      sku: sku,
      prezzo: prezzo,
      taglia: taglia,
      colore: colore,
    );

    return Container(
      width: settings.larghezzaEtichetta * 3, // Scala per visualizzazione
      height: settings.altezzaEtichetta * 3,
      padding: EdgeInsets.all(settings.margineSup * 2),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nome
          Text(
            nome,
            style: TextStyle(
              fontSize: settings.fontSizeNome,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // Taglia e colore
          if (taglia != null || colore != null)
            Row(
              children: [
                if (taglia != null)
                  Text(
                    'Tg: $taglia',
                    style: const TextStyle(fontSize: 8, color: Colors.black87),
                  ),
                if (taglia != null && colore != null)
                  const Text(
                    ' | ',
                    style: TextStyle(fontSize: 8, color: Colors.black87),
                  ),
                if (colore != null)
                  Text(
                    'Col: $colore',
                    style: const TextStyle(fontSize: 8, color: Colors.black87),
                  ),
              ],
            ),

          // SKU
          if (sku != null)
            Text(
              'SKU: $sku',
              style: const TextStyle(fontSize: 7, color: Colors.black54),
            ),

          const Spacer(),

          // Prezzo e QR Code
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${prezzo.toStringAsFixed(2)} EUR',
                style: TextStyle(
                  fontSize: settings.fontSizePrezzo,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              if (settings.mostraQrCode)
                QrImageView(
                  data: etichetta.generaContenutoQr(),
                  version: QrVersions.auto,
                  size: settings.dimensioneQr * 2,
                ),
            ],
          ),
        ],
      ),
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
                          '${etichetta.prezzo.toStringAsFixed(2)} EUR${etichetta.sku != null ? ' - SKU: ${etichetta.sku}' : ''}',
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

  void _aggiungiEtichetta() {
    if (_nomeController.text.isEmpty) {
      NotificationService.instance.messageBar(
        'warning',
        'report',
        'Inserisci almeno il nome del prodotto',
      );
      return;
    }

    final etichetta = Etichetta(
      nome: _nomeController.text,
      sku: _skuController.text.isEmpty ? null : _skuController.text,
      prezzo: double.tryParse(_prezzoController.text) ?? 0,
      taglia: _tagliaController.text.isEmpty ? null : _tagliaController.text,
      colore: _coloreController.text.isEmpty ? null : _coloreController.text,
    );

    _controller.aggiungiEtichetta(etichetta);
    setState(() {});

    NotificationService.instance.messageBar(
      'successo',
      'report',
      'Etichetta "${etichetta.nome}" aggiunta alla coda',
    );
  }

  void _resetForm() {
    _nomeController.clear();
    _skuController.clear();
    _prezzoController.clear();
    _tagliaController.clear();
    _coloreController.clear();
    setState(() {});
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
