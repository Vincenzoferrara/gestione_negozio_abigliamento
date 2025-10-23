import '../jwt_connect.dart';
import '../error_list.dart';
import '../class_prodotti.dart';

/// Query class per report e statistiche WooCommerce
/// Utilizza JwtConnect per l'autenticazione centralizzata
/// Nota: Usa Dio diretto perché Reports API non è completamente supportata dal package
class WooQueryReport {
  // Singleton pattern
  static final WooQueryReport _instance = WooQueryReport._internal();
  factory WooQueryReport() => _instance;
  WooQueryReport._internal();

  final JwtConnect _auth = JwtConnect();

  /// Reset dell'istanza (utile dopo logout)
  void reset() {
    // Report non ha stato da resettare
  }

  /// Ottiene report vendite per periodo
  Future<ReportVendite> getSalesReport({
    DateTime? dataInizio,
    DateTime? dataFine,
  }) async {
    if (!_auth.isConnected) {
      throw UnauthorizedException();
    }

    try {
      final queryParams = <String, dynamic>{
        if (dataInizio != null) 'after': dataInizio.toIso8601String(),
        if (dataFine != null) 'before': dataFine.toIso8601String(),
        'context': 'view',
      };

      final response = await _auth.getAuthenticatedDio().get(
        '${_auth.currentSiteUrl}/wp-json/wc/v3/reports/sales',
        queryParameters: queryParams,
      );

      final data = response.data as List<dynamic>;

      // Calcola totali
      double totaleVendite = 0.0;
      int totaleOrdini = 0;
      final venditeGiornaliere = <VenditaGiornaliera>[];

      for (var sale in data) {
        final vendita = double.tryParse(sale['total_sales']?.toString() ?? '0') ?? 0.0;
        final ordini = int.tryParse(sale['total_orders']?.toString() ?? '0') ?? 0;
        final dataStr = sale['date_created'] ?? sale['date'];

        totaleVendite += vendita;
        totaleOrdini += ordini;

        if (dataStr != null) {
          final data = DateTime.tryParse(dataStr.toString());
          if (data != null) {
            venditeGiornaliere.add(VenditaGiornaliera(
              data: data,
              totale: vendita,
              ordini: ordini,
            ));
          }
        }
      }

      return ReportVendite(
        periodo: dataInizio ?? DateTime.now().subtract(Duration(days: 30)),
        totaleVendite: totaleVendite,
        numeroOrdini: totaleOrdini,
        ticketMedio: totaleOrdini > 0 ? totaleVendite / totaleOrdini : 0.0,
        venditePerCategoria: {},
        prodottiPiuVenduti: {},
        venditeGiornaliere: venditeGiornaliere,
      );
    } catch (e) {
      throw Exception('Errore nel caricamento report vendite: $e');
    }
  }

  /// Ottiene statistiche prodotti
  Future<Statistiche> getProductStats() async {
    if (!_auth.isConnected) {
      throw UnauthorizedException();
    }

    try {
      // Ottiene totali prodotti
      final productsResponse = await _auth.getAuthenticatedDio().get(
        '${_auth.currentSiteUrl}/wp-json/wc/v3/reports/products/totals',
      );

      final data = productsResponse.data as List<dynamic>;

      int totaleProdotti = 0;
      int prodottiPubblicati = 0;
      int prodottiBozza = 0;
      int prodottiInStock = 0;
      int prodottiOutOfStock = 0;

      for (var item in data) {
        final slug = item['slug']?.toString() ?? '';
        final total = int.tryParse(item['total']?.toString() ?? '0') ?? 0;

        switch (slug) {
          case 'publish':
            prodottiPubblicati = total;
            totaleProdotti += total;
            break;
          case 'draft':
            prodottiBozza = total;
            break;
          case 'pending':
            totaleProdotti += total;
            break;
        }
      }

      return Statistiche(
        totaleProdotti: totaleProdotti,
        prodottiPubblicati: prodottiPubblicati,
        prodottiBozza: prodottiBozza,
        prodottiConVarianti: 0, // Non disponibile in questo endpoint
        prodottiInStock: prodottiInStock,
        prodottiOutOfStock: prodottiOutOfStock,
        valoreInventarioTotale: 0.0, // Richiede calcolo separato
        prodottiPerCategoria: {},
        prodottiPerTag: {},
      );
    } catch (e) {
      throw Exception('Errore nel caricamento statistiche prodotti: $e');
    }
  }


  /// Ottiene top prodotti più venduti
  Future<List<Map<String, dynamic>>> getTopSellingProducts({
    int limit = 10,
    DateTime? dataInizio,
    DateTime? dataFine,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'per_page': limit,
        'orderby': 'popularity',
        'order': 'desc',
        if (dataInizio != null) 'after': dataInizio.toIso8601String(),
        if (dataFine != null) 'before': dataFine.toIso8601String(),
      };

      final response = await _auth.getAuthenticatedDio().get(
        '${_auth.currentSiteUrl}/wp-json/wc/v3/reports/top_sellers',
        queryParameters: queryParams,
      );

      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      throw Exception('Errore nel caricamento top prodotti: $e');
    }
  }

  /// Ottiene ordini per stato
  Future<Map<String, int>> getOrdersByStatus() async {
    try {
      final response = await _auth.getAuthenticatedDio().get(
        '${_auth.currentSiteUrl}/wp-json/wc/v3/reports/orders/totals',
      );

      final data = response.data as List<dynamic>;
      final Map<String, int> statusCounts = {};

      for (var item in data) {
        final slug = item['slug']?.toString() ?? '';
        final total = int.tryParse(item['total']?.toString() ?? '0') ?? 0;
        if (slug.isNotEmpty) {
          statusCounts[slug] = total;
        }
      }

      return statusCounts;
    } catch (e) {
      throw Exception('Errore nel caricamento ordini per stato: $e');
    }
  }

  /// Ottiene statistiche clienti
  Future<Map<String, dynamic>> getCustomerStats() async {
    try {
      final response = await _auth.getAuthenticatedDio().get(
        '${_auth.currentSiteUrl}/wp-json/wc/v3/reports/customers/totals',
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Errore nel caricamento statistiche clienti: $e');
    }
  }

  /// Ottiene review statistiche
  Future<Map<String, int>> getReviewStats() async {
    try {
      final response = await _auth.getAuthenticatedDio().get(
        '${_auth.currentSiteUrl}/wp-json/wc/v3/reports/reviews/totals',
      );

      final data = response.data as List<dynamic>;
      final Map<String, int> ratingCounts = {};

      for (var item in data) {
        final rating = item['rating']?.toString() ?? '';
        final total = int.tryParse(item['total']?.toString() ?? '0') ?? 0;
        if (rating.isNotEmpty) {
          ratingCounts[rating] = total;
        }
      }

      return ratingCounts;
    } catch (e) {
      throw Exception('Errore nel caricamento statistiche recensioni: $e');
    }
  }

  /// Ottiene coupon usage statistics
  Future<List<Map<String, dynamic>>> getCouponUsageReport({
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final response = await _auth.getAuthenticatedDio().get(
        '${_auth.currentSiteUrl}/wp-json/wc/v3/reports/coupons/totals',
        queryParameters: {
          'page': page,
          'per_page': perPage,
        },
      );

      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      throw Exception('Errore nel caricamento report coupon: $e');
    }
  }

  /// Ottiene dashboard summary
  Future<Map<String, dynamic>> getDashboardSummary({
    DateTime? dataInizio,
    DateTime? dataFine,
  }) async {
    try {
      // Carica tutti i dati in parallelo
      final results = await Future.wait([
        getSalesReport(dataInizio: dataInizio, dataFine: dataFine),
        getProductStats(),
        getOrdersByStatus(),
        getCustomerStats(),
      ]);

      final salesReport = results[0] as ReportVendite;
      final productStats = results[1] as Statistiche;
      final ordersByStatus = results[2] as Map<String, int>;
      final customerStats = results[3] as Map<String, dynamic>;

      return {
        'sales': {
          'total': salesReport.totaleVendite,
          'orders': salesReport.numeroOrdini,
          'average_order': salesReport.ticketMedio,
        },
        'products': {
          'total': productStats.totaleProdotti,
          'in_stock': productStats.prodottiInStock,
          'out_of_stock': productStats.prodottiOutOfStock,
        },
        'orders_by_status': ordersByStatus,
        'customers': customerStats,
        'period': {
          'start': dataInizio?.toIso8601String(),
          'end': dataFine?.toIso8601String(),
        },
      };
    } catch (e) {
      throw Exception('Errore nel caricamento dashboard summary: $e');
    }
  }

  /// Ottiene trend vendite (giornaliero/settimanale/mensile)
  Future<List<Map<String, dynamic>>> getSalesTrend({
    DateTime? dataInizio,
    DateTime? dataFine,
    String period = 'day', // day, week, month
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (dataInizio != null) 'after': dataInizio.toIso8601String(),
        if (dataFine != null) 'before': dataFine.toIso8601String(),
        'period': period,
      };

      final response = await _auth.getAuthenticatedDio().get(
        '${_auth.currentSiteUrl}/wp-json/wc/v3/reports/sales',
        queryParameters: queryParams,
      );

      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      throw Exception('Errore nel caricamento trend vendite: $e');
    }
  }

  /// Verifica disponibilità servizio
  Future<bool> isServiceAvailable() async {
    try {
      await _auth.getAuthenticatedDio().get('${_auth.currentSiteUrl}/wp-json/wc/v3/reports/sales');
      return true;
    } catch (e) {
      return false;
    }
  }
}
