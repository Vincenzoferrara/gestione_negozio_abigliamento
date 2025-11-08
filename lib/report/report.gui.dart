// Report GUI - Interfaccia Utente per Report
//
// Dashboard e visualizzazione report WooCommerce
// Mostra vendite, prodotti, ordini e statistiche

import 'package:flutter/material.dart';
import 'report.code.dart';
import 'report_charts.dart';
import 'report_detailed.dart';
import '../log_viewer/app_logger.dart';

/// Pagina principale dei report con dashboard
class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final ReportService _reportService = ReportService();

  DashboardData? _dashboard;
  PeriodoReport _periodo = PeriodoReport.mese();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dashboard = await _reportService.getDashboard(
        periodo: _periodo,
        forceRefresh: forceRefresh,
      );

      if (mounted) {
        setState(() {
          _dashboard = dashboard;
          _isLoading = false;
        });
      }
    } catch (e) {
      log.e('❌ Errore caricamento dashboard', e);
      if (mounted) {
        setState(() {
          _errorMessage = 'Errore: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _changePeriod(PeriodoReport newPeriod) {
    setState(() {
      _periodo = newPeriod;
    });
    _loadDashboard(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report & Statistiche'),
        actions: [
          // Selector periodo
          PopupMenuButton<PeriodoReport>(
            icon: const Icon(Icons.date_range),
            onSelected: _changePeriod,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: PeriodoReport.oggi(),
                child: const Text('Oggi'),
              ),
              PopupMenuItem(
                value: PeriodoReport.settimana(),
                child: const Text('Questa settimana'),
              ),
              PopupMenuItem(
                value: PeriodoReport.mese(),
                child: const Text('Questo mese'),
              ),
              PopupMenuItem(
                value: PeriodoReport.anno(),
                child: const Text('Quest\'anno'),
              ),
            ],
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadDashboard(forceRefresh: true),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Caricamento report...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadDashboard,
              icon: const Icon(Icons.refresh),
              label: const Text('Riprova'),
            ),
          ],
        ),
      );
    }

    if (_dashboard == null) {
      return const Center(child: Text('Nessun dato disponibile'));
    }

    return RefreshIndicator(
      onRefresh: () => _loadDashboard(forceRefresh: true),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con periodo
            _buildPeriodHeader(),
            const SizedBox(height: 24),

            // Card vendite
            _buildVenditeCard(),
            const SizedBox(height: 16),

            // Row con prodotti e ordini
            Row(
              children: [
                Expanded(child: _buildProdottiCard()),
                const SizedBox(width: 16),
                Expanded(child: _buildOrdiniCard()),
              ],
            ),
            const SizedBox(height: 16),

            // Card clienti (se disponibile)
            if (_dashboard!.clienti != null) ...[
              _buildClientiCard(),
              const SizedBox(height: 16),
            ],

            // Grafico andamento vendite (se disponibile)
            if (_dashboard!.vendite.andamentoGiornaliero.isNotEmpty) ...[
              _buildAndamentoVenditeCard(),
              const SizedBox(height: 16),
            ],

            // Quick access ai report dettagliati
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 12),
              child: Text(
                'Report Dettagliati',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildQuickAccessReports(),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _periodo.descrizione,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${ReportFormatter.formatDateFull(_periodo.dataInizio)} - ${ReportFormatter.formatDateFull(_periodo.dataFine)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              '${_periodo.giorniTotali} giorni',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVenditeCard() {
    final vendite = _dashboard!.vendite;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(ReportColors.primary).withOpacity(0.15),
            Color(ReportColors.primary).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(ReportColors.primary).withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(ReportColors.primary),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Color(ReportColors.primary).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.euro, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Vendite',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Totale vendite
              Text(
                ReportFormatter.formatCurrency(vendite.totaleVendite),
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Color(ReportColors.primary),
                  shadows: [
                    Shadow(
                      color: Color(ReportColors.primary).withOpacity(0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Info aggiuntive con design migliorato
              Row(
                children: [
                  Expanded(
                    child: _buildEnhancedMetric(
                      'Ordini',
                      vendite.numeroOrdini.toString(),
                      Icons.shopping_cart,
                      ReportColors.info,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildEnhancedMetric(
                      'Ticket Medio',
                      ReportFormatter.formatCurrency(vendite.ticketMedio),
                      Icons.receipt,
                      ReportColors.success,
                    ),
                  ),
                ],
              ),

              // Variazione (se disponibile)
              if (vendite.variazionePrecedente != 0.0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (vendite.isInCrescita ? Color(ReportColors.success) : Color(ReportColors.danger)).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (vendite.isInCrescita ? Color(ReportColors.success) : Color(ReportColors.danger)).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        vendite.isInCrescita ? Icons.trending_up : Icons.trending_down,
                        color: vendite.isInCrescita ? Color(ReportColors.success) : Color(ReportColors.danger),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        vendite.variazioneFormatted,
                        style: TextStyle(
                          color: vendite.isInCrescita ? Color(ReportColors.success) : Color(ReportColors.danger),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'vs periodo precedente',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProdottiCard() {
    final prodotti = _dashboard!.prodotti;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2, color: Color(ReportColors.info)),
                const SizedBox(width: 8),
                const Text(
                  'Prodotti',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildMetric('Totale', prodotti.totaleProdotti.toString(), Icons.apps),
            const SizedBox(height: 8),
            _buildMetric('In Stock', prodotti.prodottiInStock.toString(), Icons.check_circle, color: ReportColors.success),
            const SizedBox(height: 8),
            _buildMetric('Esauriti', prodotti.prodottiOutOfStock.toString(), Icons.warning, color: ReportColors.danger),

            if (prodotti.hasAllarmeStock) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(ReportColors.warning).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Color(ReportColors.warning), size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Attenzione allo stock!',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrdiniCard() {
    final ordini = _dashboard!.ordini;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: Color(ReportColors.success)),
                const SizedBox(width: 8),
                const Text(
                  'Ordini',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildMetric('Totale', ordini.totaleOrdini.toString(), Icons.shopping_bag),
            const SizedBox(height: 8),
            _buildMetric('Completati', ordini.ordiniCompletati.toString(), Icons.check, color: ReportColors.success),
            const SizedBox(height: 8),
            _buildMetric('In elaborazione', ordini.ordiniInElaborazione.toString(), Icons.hourglass_empty, color: ReportColors.info),

            if (ordini.ordiniDaGestire > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(ReportColors.info).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Color(ReportColors.info), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${ordini.ordiniDaGestire} ordini da gestire',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClientiCard() {
    final clienti = _dashboard!.clienti!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: Color(ReportColors.primary)),
                const SizedBox(width: 8),
                const Text(
                  'Clienti',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(child: _buildMetric('Totale', clienti.totaleClienti.toString(), Icons.person)),
                Expanded(child: _buildMetric('Nuovi', clienti.nuoviClienti.toString(), Icons.person_add, color: ReportColors.success)),
                Expanded(child: _buildMetric('Attivi', clienti.clientiAttivi.toString(), Icons.person_outline)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAndamentoVenditeCard() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        child: SalesLineChart(
          vendite: _dashboard!.vendite.andamentoGiornaliero,
          title: 'Andamento Vendite',
          lineColor: Color(ReportColors.primary),
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, IconData icon, {int? color}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color != null ? Color(color) : Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEnhancedMetric(String label, String value, IconData icon, int colorValue) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(colorValue).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Color(colorValue),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessReports() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildReportAccessCard(
                'Top Prodotti',
                'Analizza i prodotti più venduti',
                Icons.star,
                ReportColors.warning,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TopProductsReportPage(periodo: _periodo),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildReportAccessCard(
                'Performance',
                'Analisi temporale vendite',
                Icons.trending_up,
                ReportColors.success,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PerformanceTimelineReportPage(periodo: _periodo),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildReportAccessCard(
                'Analisi Ordini',
                'Distribuzione e statistiche',
                Icons.assessment,
                ReportColors.info,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OrdersDetailedReportPage(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildReportAccessCard(
                'Export Report',
                'Esporta dati in CSV/PDF',
                Icons.file_download,
                ReportColors.primary,
                () {
                  // TODO: Implementare export
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Funzionalità in arrivo...')),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReportAccessCard(
    String title,
    String subtitle,
    IconData icon,
    int colorValue,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(colorValue).withOpacity(0.1),
              Color(colorValue).withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Color(colorValue).withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(colorValue).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Color(colorValue),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Color(colorValue).withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(colorValue),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}