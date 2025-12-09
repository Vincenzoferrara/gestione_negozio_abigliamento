// Dashboard GUI - Interfaccia Utente per Dashboard
//
// Dashboard e visualizzazione statistiche WooCommerce
// Mostra vendite, prodotti, ordini e statistiche

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard.code.dart';
import 'dashboard_charts.dart';
import 'dashboard_detailed.dart';
import 'dashboard_customization.dart';
import 'ads_dashboard.code.dart';
import '../log_viewer/app_logger.dart';
import '../login/gui/login.code.dart';

/// Pagina principale della dashboard con statistiche
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ReportService _reportService = ReportService();
  final AdsPlatformService _adsService = AdsPlatformService();

  DashboardData? _dashboard;
  AdsPlatformData? _adsData;
  PeriodoReport _periodo = PeriodoReport.mese();
  bool _isLoading = false;
  String? _errorMessage;

  // Verifica se l'utente è autenticato
  bool get _isAuthenticated => loginCode.isConnected;

  @override
  void initState() {
    super.initState();
    // Carica i dati solo se autenticato
    if (_isAuthenticated) {
      _loadDashboard();
      _initializeAdsService();
    }
  }

  Future<void> _initializeAdsService() async {
    try {
      await _adsService.initialize();
      // Carica dati ads se disponibili
      if (_adsService.isConnected("meta") ||
          _adsService.isConnected("google") ||
          _adsService.isConnected("tiktok")) {
        _loadAdsData();
      }
    } catch (e) {
      log.w('⚠️ Ads service non disponibile: $e');
    }
  }

  Future<void> _loadAdsData() async {
    try {
      // Carica gli Account IDs salvati
      final prefs = await SharedPreferences.getInstance();
      final metaAdAccountId = prefs.getString('ads_meta_account_id');
      final googleCustomerId = prefs.getString('ads_google_customer_id');
      final tiktokAdvertiserId = prefs.getString('ads_tiktok_advertiser_id');
      final instagramUserId = prefs.getString('ads_instagram_user_id');

      final data = await _adsService.fetchAllData(
        metaAdAccountId: metaAdAccountId?.isEmpty == true
            ? null
            : metaAdAccountId,
        googleCustomerId: googleCustomerId?.isEmpty == true
            ? null
            : googleCustomerId,
        tiktokAdvertiserId: tiktokAdvertiserId?.isEmpty == true
            ? null
            : tiktokAdvertiserId,
        instagramUserId: instagramUserId?.isEmpty == true
            ? null
            : instagramUserId,
      );
      if (mounted) {
        setState(() => _adsData = data);
      }
    } catch (e) {
      log.w('⚠️ Errore caricamento dati ads: $e');
    }
  }

  @override
  void dispose() {
    _adsService.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard({bool forceRefresh = false}) async {
    // Verifica autenticazione prima di caricare
    if (!_isAuthenticated) {
      return;
    }

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
      body: _buildBody(),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsante personalizzazione
          FloatingActionButton.small(
            heroTag: 'customize',
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CustomizableDashboardPage(),
                ),
              );
            },
            child: const Icon(Icons.dashboard_customize),
          ),
          const SizedBox(height: 8),
          // Pulsante refresh
          FloatingActionButton.small(
            heroTag: 'refresh',
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            onPressed: () => _loadDashboard(forceRefresh: true),
            child: const Icon(Icons.refresh),
          ),
          const SizedBox(height: 8),
          // Pulsante periodo
          PopupMenuButton<PeriodoReport>(
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
            child: FloatingActionButton.small(
              heroTag: 'period',
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              onPressed: null,
              child: const Icon(Icons.date_range),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    // Se non autenticato, mostra messaggio di login
    if (!_isAuthenticated) {
      return _buildLoginRequired();
    }

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Caricamento dashboard...'),
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

            // Card Ads Platform (se connesse)
            if (_adsService.isConnected("meta") ||
                _adsService.isConnected("google") ||
                _adsService.isConnected("tiktok")) ...[
              _buildAdsPlatformCard(),
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
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const Spacer(),
            Text(
              '${_periodo.giorniTotali} giorni',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
            Color(ReportColors.primary).withValues(alpha: 0.15),
            Color(ReportColors.primary).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(ReportColors.primary).withValues(alpha: 0.15),
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
                          color: Color(
                            ReportColors.primary,
                          ).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.euro,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Vendite',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                      color: Color(ReportColors.primary).withValues(alpha: 0.2),
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
                    color:
                        (vendite.isInCrescita
                                ? Color(ReportColors.success)
                                : Color(ReportColors.danger))
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          (vendite.isInCrescita
                                  ? Color(ReportColors.success)
                                  : Color(ReportColors.danger))
                              .withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        vendite.isInCrescita
                            ? Icons.trending_up
                            : Icons.trending_down,
                        color: vendite.isInCrescita
                            ? Color(ReportColors.success)
                            : Color(ReportColors.danger),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        vendite.variazioneFormatted,
                        style: TextStyle(
                          color: vendite.isInCrescita
                              ? Color(ReportColors.success)
                              : Color(ReportColors.danger),
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildMetric(
              'Totale',
              prodotti.totaleProdotti.toString(),
              Icons.apps,
            ),
            const SizedBox(height: 8),
            _buildMetric(
              'In Stock',
              prodotti.prodottiInStock.toString(),
              Icons.check_circle,
              color: ReportColors.success,
            ),
            const SizedBox(height: 8),
            _buildMetric(
              'Esauriti',
              prodotti.prodottiOutOfStock.toString(),
              Icons.warning,
              color: ReportColors.danger,
            ),

            if (prodotti.hasAllarmeStock) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(ReportColors.warning).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: Color(ReportColors.warning),
                      size: 20,
                    ),
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildMetric(
              'Totale',
              ordini.totaleOrdini.toString(),
              Icons.shopping_bag,
            ),
            const SizedBox(height: 8),
            _buildMetric(
              'Completati',
              ordini.ordiniCompletati.toString(),
              Icons.check,
              color: ReportColors.success,
            ),
            const SizedBox(height: 8),
            _buildMetric(
              'In elaborazione',
              ordini.ordiniInElaborazione.toString(),
              Icons.hourglass_empty,
              color: ReportColors.info,
            ),

            if (ordini.ordiniDaGestire > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(ReportColors.info).withValues(alpha: 0.1),
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildMetric(
                    'Totale',
                    clienti.totaleClienti.toString(),
                    Icons.person,
                  ),
                ),
                Expanded(
                  child: _buildMetric(
                    'Nuovi',
                    clienti.nuoviClienti.toString(),
                    Icons.person_add,
                    color: ReportColors.success,
                  ),
                ),
                Expanded(
                  child: _buildMetric(
                    'Attivi',
                    clienti.clientiAttivi.toString(),
                    Icons.person_outline,
                  ),
                ),
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
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
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEnhancedMetric(
    String label,
    String value,
    IconData icon,
    int colorValue,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
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
              color: Color(colorValue).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Color(colorValue)),
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
                    builder: (context) =>
                        TopProductsReportPage(periodo: _periodo),
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
                    builder: (context) =>
                        PerformanceTimelineReportPage(periodo: _periodo),
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
              Color(colorValue).withValues(alpha: 0.1),
              Color(colorValue).withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Color(colorValue).withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(colorValue).withValues(alpha: 0.1),
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
                        color: Color(colorValue).withValues(alpha: 0.3),
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdsPlatformCard() {
    final metrics = _adsData?.getAggregateMetrics();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con controlli
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.ads_click,
                    color: Colors.purple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Piattaforme Pubblicitarie',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Meta, Google, TikTok Ads',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                // Pulsante refresh
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: _loadAdsData,
                  tooltip: 'Ricarica dati ads',
                ),
                // Auto-refresh toggle
                IconButton(
                  icon: Icon(
                    _adsService.isSchedulerRunning
                        ? Icons.pause
                        : Icons.play_arrow,
                    size: 20,
                  ),
                  onPressed: _toggleAdsAutoRefresh,
                  tooltip: _adsService.isSchedulerRunning
                      ? 'Disattiva auto-refresh'
                      : 'Attiva auto-refresh',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stato connessioni
            Row(
              children: [
                _buildPlatformBadge(
                  'Meta',
                  _adsService.isConnected("meta"),
                  Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildPlatformBadge(
                  'Google',
                  _adsService.isConnected("google"),
                  Colors.red,
                ),
                const SizedBox(width: 8),
                _buildPlatformBadge(
                  'TikTok',
                  _adsService.isConnected("tiktok"),
                  Colors.black,
                ),
              ],
            ),

            // Metriche aggregate (se disponibili)
            if (metrics != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'Metriche Aggregate',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildAdMetricCard(
                    'Spesa Totale',
                    '€${metrics.totalSpend.toStringAsFixed(2)}',
                    Icons.euro,
                    Colors.red,
                  ),
                  _buildAdMetricCard(
                    'Impressioni',
                    '${metrics.totalImpressions}',
                    Icons.visibility,
                    Colors.blue,
                  ),
                  _buildAdMetricCard(
                    'Click',
                    '${metrics.totalClicks}',
                    Icons.touch_app,
                    Colors.green,
                  ),
                  _buildAdMetricCard(
                    'Conversioni',
                    '${metrics.totalConversions}',
                    Icons.shopping_cart,
                    Colors.orange,
                  ),
                  _buildAdMetricCard(
                    'CTR',
                    '${metrics.ctr.toStringAsFixed(2)}%',
                    Icons.percent,
                    Colors.purple,
                  ),
                  _buildAdMetricCard(
                    'CPC',
                    '€${metrics.cpc.toStringAsFixed(2)}',
                    Icons.monetization_on,
                    Colors.teal,
                  ),
                ],
              ),
            ],

            // Dettagli per piattaforma
            if (_adsData != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // Meta Ads
              if (_adsService.isConnected("meta")) ...[
                _buildPlatformDetailsSection(
                  'Meta Ads',
                  Icons.facebook,
                  Colors.blue,
                  [
                    if (_adsData!.metaCampaigns != null)
                      'Campagne: ${_adsData!.metaCampaigns['data']?.length ?? 0}',
                    if (_adsData!.instagramMedia != null)
                      'Instagram Media: ${_adsData!.instagramMedia['data']?.length ?? 0}',
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Google Ads
              if (_adsService.isConnected("google")) ...[
                _buildPlatformDetailsSection(
                  'Google Ads',
                  Icons.g_mobiledata,
                  Colors.red,
                  ['Dati disponibili'],
                ),
                const SizedBox(height: 12),
              ],

              // TikTok Ads
              if (_adsService.isConnected("tiktok")) ...[
                _buildPlatformDetailsSection(
                  'TikTok Ads',
                  Icons.tiktok_outlined,
                  Colors.black,
                  [
                    if (_adsData!.tiktokCampaigns != null)
                      'Campagne: ${_adsData!.tiktokCampaigns['data']?.length ?? 0}',
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  void _toggleAdsAutoRefresh() {
    if (_adsService.isSchedulerRunning) {
      _adsService.stopAutoRefresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Auto-refresh ads disattivato")),
      );
    } else {
      _adsService.startAutoRefresh(interval: const Duration(minutes: 5));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Auto-refresh ads attivato (ogni 5 min)")),
      );
    }
    setState(() {});
  }

  Widget _buildPlatformDetailsSection(
    String name,
    IconData icon,
    Color color,
    List<String> details,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...details.map(
              (detail) => Padding(
                padding: const EdgeInsets.only(left: 28, top: 4),
                child: Text(
                  detail,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformBadge(String name, bool isConnected, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isConnected
            ? color.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isConnected ? color : Colors.grey, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConnected ? Icons.check_circle : Icons.cancel,
            size: 12,
            color: isConnected ? color : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            name,
            style: TextStyle(
              fontSize: 10,
              color: isConnected ? color : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginRequired() {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24),
              Text(
                'Per visualizzare i dati devi fare il login',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'La dashboard contiene informazioni riservate che richiedono l\'autenticazione',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  // Naviga alla pagina di login o mostra dialog
                  Navigator.of(context).pushNamed('/login');
                },
                icon: const Icon(Icons.login),
                label: const Text('Accedi'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
