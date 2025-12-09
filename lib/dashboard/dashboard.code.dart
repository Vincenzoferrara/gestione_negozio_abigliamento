// Report Code - Business Logic & Models
//
// Sistema di report per WooCommerce
// Gestisce la logica di business, modelli dati e coordinamento con WooQueryReport
//
// Struttura:
// - Modelli dati (Dashboard, Report vendite, Statistiche)
// - ReportService (coordinatore principale)
// - Helper per calcoli e formattazione

import '../login/jwt_api/query_woocommerce/woo_query_report.dart';
import '../login/jwt_api/class_prodotti.dart';
import '../log_viewer/app_logger.dart';

/// Eccezione personalizzata per errori report
class ReportException implements Exception {
  final String message;
  final ReportErrorType type;
  final dynamic originalError;

  ReportException(this.message, this.type, [this.originalError]);

  @override
  String toString() => message;

  /// Messaggio utente-friendly
  String get userMessage {
    switch (type) {
      case ReportErrorType.network:
        return 'Errore di connessione. Verifica la tua connessione internet.';
      case ReportErrorType.authentication:
        return 'Sessione scaduta. Effettua nuovamente il login.';
      case ReportErrorType.serverError:
        return 'Il server non è disponibile. Riprova più tardi.';
      case ReportErrorType.timeout:
        return 'La richiesta ha impiegato troppo tempo. Riprova.';
      case ReportErrorType.noData:
        return 'Nessun dato disponibile per il periodo selezionato.';
      case ReportErrorType.unknown:
        return 'Si è verificato un errore imprevisto. Riprova.';
    }
  }
}

/// Tipi di errore per i report
enum ReportErrorType {
  network,
  authentication,
  serverError,
  timeout,
  noData,
  unknown,
}

// =======================================================
// ==                MODELLI DATI REPORT                ==
// =======================================================

/// Dashboard summary - Vista principale dei report
class DashboardData {
  final PeriodoReport periodo;
  final VenditeData vendite;
  final ProdottiData prodotti;
  final OrdiniData ordini;
  final ClientiData? clienti;
  final DateTime ultimoAggiornamento;

  DashboardData({
    required this.periodo,
    required this.vendite,
    required this.prodotti,
    required this.ordini,
    this.clienti,
    DateTime? ultimoAggiornamento,
  }) : ultimoAggiornamento = ultimoAggiornamento ?? DateTime.now();

  /// Verifica se i dati sono obsoleti (> 5 minuti)
  bool get isObsoleto {
    final diff = DateTime.now().difference(ultimoAggiornamento);
    return diff.inMinutes > 5;
  }
}

/// Periodo del report
class PeriodoReport {
  final DateTime dataInizio;
  final DateTime dataFine;
  final TipoPeriodo tipo;

  PeriodoReport({
    required this.dataInizio,
    required this.dataFine,
    this.tipo = TipoPeriodo.custom,
  });

  /// Factory per periodi predefiniti
  factory PeriodoReport.oggi() {
    final oggi = DateTime.now();
    final inizio = DateTime(oggi.year, oggi.month, oggi.day);
    return PeriodoReport(
      dataInizio: inizio,
      dataFine: oggi,
      tipo: TipoPeriodo.oggi,
    );
  }

  factory PeriodoReport.settimana() {
    final oggi = DateTime.now();
    final inizioSettimana = oggi.subtract(Duration(days: oggi.weekday - 1));
    return PeriodoReport(
      dataInizio: DateTime(inizioSettimana.year, inizioSettimana.month, inizioSettimana.day),
      dataFine: oggi,
      tipo: TipoPeriodo.settimana,
    );
  }

  factory PeriodoReport.mese() {
    final oggi = DateTime.now();
    return PeriodoReport(
      dataInizio: DateTime(oggi.year, oggi.month, 1),
      dataFine: oggi,
      tipo: TipoPeriodo.mese,
    );
  }

  factory PeriodoReport.anno() {
    final oggi = DateTime.now();
    return PeriodoReport(
      dataInizio: DateTime(oggi.year, 1, 1),
      dataFine: oggi,
      tipo: TipoPeriodo.anno,
    );
  }

  /// Numero di giorni nel periodo
  int get giorniTotali => dataFine.difference(dataInizio).inDays + 1;

  String get descrizione {
    switch (tipo) {
      case TipoPeriodo.oggi:
        return 'Oggi';
      case TipoPeriodo.settimana:
        return 'Questa settimana';
      case TipoPeriodo.mese:
        return 'Questo mese';
      case TipoPeriodo.anno:
        return 'Quest\'anno';
      case TipoPeriodo.custom:
        return 'Periodo personalizzato';
    }
  }
}

enum TipoPeriodo {
  oggi,
  settimana,
  mese,
  anno,
  custom,
}

/// Dati vendite per dashboard
class VenditeData {
  final double totaleVendite;
  final int numeroOrdini;
  final double ticketMedio;
  final double variazionePrecedente; // Percentuale rispetto al periodo precedente
  final List<VenditaGiornaliera> andamentoGiornaliero;

  VenditeData({
    required this.totaleVendite,
    required this.numeroOrdini,
    required this.ticketMedio,
    this.variazionePrecedente = 0.0,
    this.andamentoGiornaliero = const [],
  });

  bool get isInCrescita => variazionePrecedente > 0;
  bool get isInCalo => variazionePrecedente < 0;
  bool get isStabile => variazionePrecedente == 0.0;

  String get variazioneFormatted {
    if (variazionePrecedente == 0) return '0%';
    final segno = variazionePrecedente > 0 ? '+' : '';
    return '$segno${variazionePrecedente.toStringAsFixed(1)}%';
  }
}

/// Dati prodotti per dashboard
class ProdottiData {
  final int totaleProdotti;
  final int prodottiInStock;
  final int prodottiOutOfStock;
  final int prodottiPerEsaurimento; // Stock < 5
  final double valoreInventario;
  final Map<String, int>? prodottiPerCategoria;
  final List<Map<String, dynamic>>? prodottiStockBasso; // Lista prodotti con stock basso

  ProdottiData({
    required this.totaleProdotti,
    required this.prodottiInStock,
    required this.prodottiOutOfStock,
    this.prodottiPerEsaurimento = 0,
    this.valoreInventario = 0.0,
    this.prodottiPerCategoria,
    this.prodottiStockBasso,
  });

  double get percentualeInStock =>
      totaleProdotti > 0 ? (prodottiInStock / totaleProdotti) * 100 : 0;

  double get percentualeOutOfStock =>
      totaleProdotti > 0 ? (prodottiOutOfStock / totaleProdotti) * 100 : 0;

  bool get hasAllarmeStock => prodottiOutOfStock > 0 || prodottiPerEsaurimento > 0;
}

/// Dati ordini per dashboard
class OrdiniData {
  final Map<String, int> ordiniPerStato;
  final int totaleOrdini;
  final int ordiniCompletati;
  final int ordiniInElaborazione;
  final int ordiniInAttesa;

  OrdiniData({
    required this.ordiniPerStato,
  })  : totaleOrdini = ordiniPerStato.values.fold(0, (sum, count) => sum + count),
        ordiniCompletati = ordiniPerStato['completed'] ?? 0,
        ordiniInElaborazione = ordiniPerStato['processing'] ?? 0,
        ordiniInAttesa = ordiniPerStato['pending'] ?? 0;

  double get tassoCompletamento =>
      totaleOrdini > 0 ? (ordiniCompletati / totaleOrdini) * 100 : 0;

  int get ordiniDaGestire => ordiniInElaborazione + ordiniInAttesa;
}

/// Dati clienti per dashboard
class ClientiData {
  final int totaleClienti;
  final int nuoviClienti;
  final int clientiAttivi; // Con almeno un ordine
  final double valoreMedioCliente;

  ClientiData({
    required this.totaleClienti,
    required this.nuoviClienti,
    required this.clientiAttivi,
    this.valoreMedioCliente = 0.0,
  });

  double get percentualeClientiAttivi =>
      totaleClienti > 0 ? (clientiAttivi / totaleClienti) * 100 : 0;
}

/// Prodotto più venduto
class TopProdotto {
  final int productId;
  final String titolo;
  final int quantitaVenduta;
  final double totaleVendite;
  final String? immagineUrl;

  TopProdotto({
    required this.productId,
    required this.titolo,
    required this.quantitaVenduta,
    required this.totaleVendite,
    this.immagineUrl,
  });

  double get prezzoMedio =>
      quantitaVenduta > 0 ? totaleVendite / quantitaVenduta : 0.0;
}

/// Report vendite dettagliato
class ReportVenditeDettagliato {
  final PeriodoReport periodo;
  final VenditeData vendite;
  final List<TopProdotto> topProdotti;
  final Map<String, double> venditePerCategoria;
  final List<TendenzaVendite> tendenze;

  ReportVenditeDettagliato({
    required this.periodo,
    required this.vendite,
    required this.topProdotti,
    required this.venditePerCategoria,
    required this.tendenze,
  });
}

/// Tendenza vendite per grafici
class TendenzaVendite {
  final DateTime data;
  final double vendite;
  final int ordini;
  final double ticketMedio;

  TendenzaVendite({
    required this.data,
    required this.vendite,
    required this.ordini,
  }) : ticketMedio = ordini > 0 ? vendite / ordini : 0.0;

  String get dataFormattata {
    return '${data.day}/${data.month}';
  }
}

// =======================================================
// ==            SERVIZIO PRINCIPALE REPORT             ==
// =======================================================

/// Servizio principale per gestire tutti i report
/// Coordina WooQueryReport e fornisce dati elaborati alla GUI
class ReportService {
  // Singleton
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal();

  final WooQueryReport _wooReport = WooQueryReport();

  /// Cache per dashboard data
  DashboardData? _cachedDashboard;
  PeriodoReport? _cachedPeriodo;

  /// Reset della cache (dopo logout o cambio periodo)
  void reset() {
    _cachedDashboard = null;
    _cachedPeriodo = null;
  }

  /// Ottiene dashboard completa con tutti i dati
  Future<DashboardData> getDashboard({
    PeriodoReport? periodo,
    bool forceRefresh = false,
  }) async {
    try {
      // Usa periodo corrente o mese di default
      periodo ??= PeriodoReport.mese();

      // Verifica cache
      if (!forceRefresh &&
          _cachedDashboard != null &&
          !_cachedDashboard!.isObsoleto &&
          _cachedPeriodo?.tipo == periodo.tipo) {
        log.d('📊 Dashboard cache HIT');
        return _cachedDashboard!;
      }

      log.d('📊 Caricamento dashboard per periodo: ${periodo.descrizione}');

      // Ottieni dashboard summary, statistiche stock e categorie in parallelo
      final results = await Future.wait([
        _wooReport.getDashboardSummary(
          dataInizio: periodo.dataInizio,
          dataFine: periodo.dataFine,
        ),
        _wooReport.getStockStatistics(lowStockThreshold: 5),
        _wooReport.getProductsByCategory(),
      ]);

      final summary = results[0] as Map<String, dynamic>;
      final stockStats = results[1] as Map<String, dynamic>;
      final prodottiPerCategoria = results[2] as Map<String, int>;

      // Costruisci dati vendite
      final salesData = summary['sales'] as Map<String, dynamic>;

      // Ottieni andamento giornaliero
      final trendsRaw = await _wooReport.getSalesTrend(
        dataInizio: periodo.dataInizio,
        dataFine: periodo.dataFine,
      );

      final andamentoGiornaliero = trendsRaw.map((t) {
        return VenditaGiornaliera(
          data: DateTime.tryParse(t['date']?.toString() ?? '') ?? DateTime.now(),
          totale: _parseDouble(t['total_sales']),
          ordini: _parseInt(t['total_orders']),
        );
      }).toList();

      // Calcola variazione rispetto al periodo precedente
      double variazionePrecedente = 0.0;
      try {
        final giorniPeriodo = periodo.giorniTotali;
        final inizioPrecedente = periodo.dataInizio.subtract(Duration(days: giorniPeriodo));
        final finePrecedente = periodo.dataInizio.subtract(const Duration(days: 1));

        final reportPrecedente = await _wooReport.getSalesReport(
          dataInizio: inizioPrecedente,
          dataFine: finePrecedente,
        );

        if (reportPrecedente.totaleVendite > 0) {
          final totaleCorrente = _parseDouble(salesData['total']);
          variazionePrecedente = ((totaleCorrente - reportPrecedente.totaleVendite) / reportPrecedente.totaleVendite) * 100;
        }
      } catch (e) {
        log.w('Impossibile calcolare variazione periodo precedente: $e');
      }

      final vendite = VenditeData(
        totaleVendite: _parseDouble(salesData['total']),
        numeroOrdini: _parseInt(salesData['orders']),
        ticketMedio: _parseDouble(salesData['average_order']),
        variazionePrecedente: variazionePrecedente,
        andamentoGiornaliero: andamentoGiornaliero,
      );

      // Costruisci dati prodotti con statistiche stock avanzate
      final prodotti = ProdottiData(
        totaleProdotti: _parseInt(stockStats['total_products']),
        prodottiInStock: _parseInt(stockStats['in_stock']),
        prodottiOutOfStock: _parseInt(stockStats['out_of_stock']),
        prodottiPerEsaurimento: _parseInt(stockStats['low_stock_count']),
        valoreInventario: _parseDouble(stockStats['inventory_value']),
        prodottiStockBasso: stockStats['low_stock_products'] as List<Map<String, dynamic>>?,
        prodottiPerCategoria: prodottiPerCategoria,
      );

      // Costruisci dati ordini
      final ordersData = summary['orders_by_status'] as Map<String, dynamic>;
      final ordini = OrdiniData(
        ordiniPerStato: ordersData.map((k, v) => MapEntry(k, _parseInt(v))),
      );

      // Costruisci dati clienti (opzionali)
      ClientiData? clienti;
      if (summary.containsKey('customers')) {
        final customersData = summary['customers'] as Map<String, dynamic>;
        clienti = ClientiData(
          totaleClienti: _parseInt(customersData['customers_count']),
          nuoviClienti: _parseInt(customersData['new_customers']),
          clientiAttivi: _parseInt(customersData['paying_customers']),
        );
      }

      // Crea dashboard
      final dashboard = DashboardData(
        periodo: periodo,
        vendite: vendite,
        prodotti: prodotti,
        ordini: ordini,
        clienti: clienti,
      );

      // Salva in cache
      _cachedDashboard = dashboard;
      _cachedPeriodo = periodo;

      log.i('✅ Dashboard caricata con successo');
      return dashboard;
    } catch (e, stack) {
      log.e('❌ Errore caricamento dashboard', e);
      log.e('Stack trace:', stack);

      // Converti in ReportException con messaggio specifico
      final errorString = e.toString().toLowerCase();
      ReportErrorType errorType;

      if (errorString.contains('socketexception') ||
          errorString.contains('connection') ||
          errorString.contains('network')) {
        errorType = ReportErrorType.network;
      } else if (errorString.contains('401') ||
                 errorString.contains('403') ||
                 errorString.contains('unauthorized') ||
                 errorString.contains('authentication')) {
        errorType = ReportErrorType.authentication;
      } else if (errorString.contains('500') ||
                 errorString.contains('502') ||
                 errorString.contains('503')) {
        errorType = ReportErrorType.serverError;
      } else if (errorString.contains('timeout')) {
        errorType = ReportErrorType.timeout;
      } else {
        errorType = ReportErrorType.unknown;
      }

      throw ReportException(
        'Errore caricamento dashboard: $e',
        errorType,
        e,
      );
    }
  }

  /// Ottiene report vendite dettagliato
  Future<ReportVenditeDettagliato> getReportVendite({
    PeriodoReport? periodo,
  }) async {
    try {
      periodo ??= PeriodoReport.mese();

      log.d('📈 Caricamento report vendite per: ${periodo.descrizione}');

      // Carica dati in parallelo
      final results = await Future.wait([
        _wooReport.getSalesReport(
          dataInizio: periodo.dataInizio,
          dataFine: periodo.dataFine,
        ),
        _wooReport.getTopSellingProducts(
          limit: 10,
          dataInizio: periodo.dataInizio,
          dataFine: periodo.dataFine,
        ),
        _wooReport.getSalesTrend(
          dataInizio: periodo.dataInizio,
          dataFine: periodo.dataFine,
        ),
      ]);

      final reportVendite = results[0] as ReportVendite;
      final topProductsRaw = results[1] as List<Map<String, dynamic>>;
      final trendsRaw = results[2] as List<Map<String, dynamic>>;

      // Converti top prodotti
      final topProdotti = topProductsRaw.map((p) {
        return TopProdotto(
          productId: _parseInt(p['product_id']),
          titolo: p['title']?.toString() ?? 'Sconosciuto',
          quantitaVenduta: _parseInt(p['quantity']),
          totaleVendite: _parseDouble(p['total']),
        );
      }).toList();

      // Converti tendenze
      final tendenze = trendsRaw.map((t) {
        return TendenzaVendite(
          data: DateTime.tryParse(t['date']?.toString() ?? '') ?? DateTime.now(),
          vendite: _parseDouble(t['total_sales']),
          ordini: _parseInt(t['total_orders']),
        );
      }).toList();

      // Costruisci VenditeData
      final vendite = VenditeData(
        totaleVendite: reportVendite.totaleVendite,
        numeroOrdini: reportVendite.numeroOrdini,
        ticketMedio: reportVendite.ticketMedio,
        andamentoGiornaliero: reportVendite.venditeGiornaliere,
      );

      log.i('✅ Report vendite caricato: ${topProdotti.length} top prodotti');

      return ReportVenditeDettagliato(
        periodo: periodo,
        vendite: vendite,
        topProdotti: topProdotti,
        venditePerCategoria: reportVendite.venditePerCategoria,
        tendenze: tendenze,
      );
    } catch (e, stack) {
      log.e('❌ Errore caricamento report vendite', e);
      log.e('Stack trace:', stack);
      rethrow;
    }
  }

  /// Ottiene statistiche prodotti
  Future<Statistiche> getStatisticheProdotti() async {
    try {
      log.d('📦 Caricamento statistiche prodotti');
      final stats = await _wooReport.getProductStats();
      log.i('✅ Statistiche prodotti caricate');
      return stats;
    } catch (e) {
      log.e('❌ Errore caricamento statistiche prodotti', e);
      rethrow;
    }
  }

  /// Ottiene ordini per stato
  Future<Map<String, int>> getOrdiniPerStato() async {
    try {
      log.d('📋 Caricamento ordini per stato');
      final ordini = await _wooReport.getOrdersByStatus();
      log.i('✅ Ordini per stato caricati: ${ordini.length} stati');
      return ordini;
    } catch (e) {
      log.e('❌ Errore caricamento ordini per stato', e);
      rethrow;
    }
  }

  /// Ottiene statistiche recensioni
  Future<Map<String, int>> getStatisticheRecensioni() async {
    try {
      log.d('⭐ Caricamento statistiche recensioni');
      final reviews = await _wooReport.getReviewStats();
      log.i('✅ Statistiche recensioni caricate');
      return reviews;
    } catch (e) {
      log.e('❌ Errore caricamento statistiche recensioni', e);
      rethrow;
    }
  }

  /// Verifica disponibilità servizio report
  Future<bool> isServiceAvailable() async {
    try {
      return await _wooReport.isServiceAvailable();
    } catch (e) {
      log.e('❌ Servizio report non disponibile', e);
      return false;
    }
  }

  // Helper per parsing sicuro
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

// =======================================================
// ==              HELPER E UTILITY                     ==
// =======================================================

/// Formatter per valori report
class ReportFormatter {
  /// Formatta valuta in euro
  static String formatCurrency(double value) {
    return '€${value.toStringAsFixed(2)}';
  }

  /// Formatta valuta compatta (es. 1.5K, 2.3M)
  static String formatCurrencyCompact(double value) {
    if (value >= 1000000) {
      return '€${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '€${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return '€${value.toStringAsFixed(0)}';
    }
  }

  /// Formatta percentuale
  static String formatPercentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }

  /// Formatta numero intero compatto
  static String formatNumber(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return value.toString();
    }
  }

  /// Formatta data per grafici
  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }

  /// Formatta data completa
  static String formatDateFull(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Colori per i report
class ReportColors {
  // Colori principali
  static const primary = 0xFF2196F3;
  static const success = 0xFF4CAF50;
  static const warning = 0xFFFF9800;
  static const danger = 0xFFF44336;
  static const info = 0xFF00BCD4;

  // Colori per trend
  static const trendUp = success;
  static const trendDown = danger;
  static const trendStable = 0xFF9E9E9E;

  // Colori per stati ordine
  static const statusPending = warning;
  static const statusProcessing = info;
  static const statusCompleted = success;
  static const statusCancelled = danger;

  // Colori per grafici
  static const chartColors = [
    0xFF2196F3,
    0xFFF44336,
    0xFF4CAF50,
    0xFFFF9800,
    0xFF9C27B0,
    0xFF00BCD4,
    0xFFFFEB3B,
    0xFF795548,
  ];
}
