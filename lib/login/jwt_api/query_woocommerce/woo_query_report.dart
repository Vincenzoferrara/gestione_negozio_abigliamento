import 'package:woocommerce_flutter_api/woocommerce_flutter_api.dart';
import '../woo_connect.dart';
import '../class_prodotti.dart';
import 'woo_report_parser_helper.dart';

/// Query class per report e statistiche WooCommerce
/// Utilizza WooConnect per l'autenticazione centralizzata
class WooQueryReport {
  // Singleton pattern
  static final WooQueryReport _instance = WooQueryReport._internal();
  factory WooQueryReport() => _instance;
  WooQueryReport._internal();

  final WooConnect _wooConnect = WooConnect();

  /// Ottiene l'istanza WooCommerce autenticata da WooConnect
  WooCommerce get _woo => _wooConnect.woo;

  /// Ottiene report vendite per periodo
  Future<ReportVendite> getSalesReport({
    DateTime? dataInizio,
    DateTime? dataFine,
  }) async {
    try {
      final woo = _woo;

      // Formatta le date per WooCommerce API (YYYY-MM-DD)
      String? dateMin;
      String? dateMax;

      if (dataInizio != null) {
        dateMin = '${dataInizio.year}-${dataInizio.month.toString().padLeft(2, '0')}-${dataInizio.day.toString().padLeft(2, '0')}';
      }

      if (dataFine != null) {
        dateMax = '${dataFine.year}-${dataFine.month.toString().padLeft(2, '0')}-${dataFine.day.toString().padLeft(2, '0')}';
      }

      // Prova prima a usare il metodo del package
      List<WooSalesReport>? reports;
      try {
        reports = await woo.getSalesReport(
          dateMin: dateMin,
          dateMax: dateMax,
        );
      } catch (typeError) {
        // Se c'è un errore di tipo (String/int), usa chiamata raw con parsing manuale
        // Questo è un fallback per il bug nel modello WooSalesReportTotals
        final queryParameters = <String, dynamic>{
          'context': 'view',
        };
        if (dateMin != null) queryParameters['date_min'] = dateMin;
        if (dateMax != null) queryParameters['date_max'] = dateMax;

        final response = await woo.dio.get('/reports/sales', queryParameters: queryParameters);
        final responseData = response.data;
        final List<dynamic> reportsJson = responseData is List ? responseData : [responseData];

        // Parsing manuale con le funzioni safe
        return _parseReportsManually(reportsJson, dataInizio);
      }

      // Se il metodo del package ha funzionato, usa i dati normalmente
      double totaleVendite = 0.0;
      int totaleOrdini = 0;
      final venditeGiornaliere = <VenditaGiornaliera>[];

      for (final report in reports) {
        // Accumula totali con parsing sicuro
        totaleVendite += double.tryParse(report.totalSales ?? '0') ?? 0.0;
        totaleOrdini += report.totalOrders ?? 0;

        // Aggiungi vendite giornaliere se disponibili
        if (report.totals != null) {
          for (final dayTotal in report.totals!) {
            if (dayTotal.date != null) {
              venditeGiornaliere.add(VenditaGiornaliera(
                data: dayTotal.date!,
                totale: double.tryParse(dayTotal.sales ?? '0') ?? 0.0,
                ordini: dayTotal.orders ?? 0,
              ));
            }
          }
        }
      }

      return ReportVendite(
        periodo: dataInizio ?? DateTime.now().subtract(const Duration(days: 30)),
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

  /// Parse manuale dei report quando il modello del package fallisce
  ReportVendite _parseReportsManually(List<dynamic> reportsJson, DateTime? dataInizio) {
    double totaleVendite = 0.0;
    int totaleOrdini = 0;
    final venditeGiornaliere = <VenditaGiornaliera>[];

    for (final reportData in reportsJson) {
      if (reportData is! Map<String, dynamic>) continue;

      // Accumula totali con parsing sicuro
      totaleVendite += parseDoubleSafe(reportData['total_sales']) ?? 0.0;
      totaleOrdini += parseIntSafe(reportData['total_orders']) ?? 0;

      // Aggiungi vendite giornaliere se disponibili
      final totalsData = reportData['totals'];
      if (totalsData is Map<String, dynamic>) {
        totalsData.forEach((dateKey, dayData) {
          if (dayData is Map<String, dynamic>) {
            final date = DateTime.tryParse(dateKey);
            if (date != null) {
              venditeGiornaliere.add(VenditaGiornaliera(
                data: date,
                totale: parseDoubleSafe(dayData['sales']) ?? 0.0,
                ordini: parseIntSafe(dayData['orders']) ?? 0,
              ));
            }
          }
        });
      }
    }

    return ReportVendite(
      periodo: dataInizio ?? DateTime.now().subtract(const Duration(days: 30)),
      totaleVendite: totaleVendite,
      numeroOrdini: totaleOrdini,
      ticketMedio: totaleOrdini > 0 ? totaleVendite / totaleOrdini : 0.0,
      venditePerCategoria: {},
      prodottiPiuVenduti: {},
      venditeGiornaliere: venditeGiornaliere,
    );
  }

  /// Ottiene statistiche prodotti
  Future<Statistiche> getProductStats() async {
    try {
      final woo = _woo;

      // Usa l'API nativa del package
      final List<WooProductTotalReport> reports = await woo.getProductsTotalReport();

      int totaleProdotti = 0;
      int prodottiPubblicati = 0;
      int prodottiBozza = 0;
      int prodottiInStock = 0;
      int prodottiOutOfStock = 0;

      for (final report in reports) {
        final slug = report.slug ?? '';
        final total = int.tryParse(report.total ?? '0') ?? 0;

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
          case 'instock':
            prodottiInStock = total;
            break;
          case 'outofstock':
            prodottiOutOfStock = total;
            break;
        }
      }

      return Statistiche(
        totaleProdotti: totaleProdotti,
        prodottiPubblicati: prodottiPubblicati,
        prodottiBozza: prodottiBozza,
        prodottiConVarianti: 0,
        prodottiInStock: prodottiInStock,
        prodottiOutOfStock: prodottiOutOfStock,
        valoreInventarioTotale: 0.0,
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
      final woo = _woo;

      // Formatta le date
      String? dateMin;
      String? dateMax;

      if (dataInizio != null) {
        dateMin = '${dataInizio.year}-${dataInizio.month.toString().padLeft(2, '0')}-${dataInizio.day.toString().padLeft(2, '0')}';
      }

      if (dataFine != null) {
        dateMax = '${dataFine.year}-${dataFine.month.toString().padLeft(2, '0')}-${dataFine.day.toString().padLeft(2, '0')}';
      }

      // Usa l'API nativa del package
      final List<WooTopSellersReport> reports = await woo.getTopSellersReport(
        dateMin: dateMin,
        dateMax: dateMax,
      );

      // Converti in formato Map (per compatibilità con codice esistente)
      // Nota: WooTopSellersReport non ha il campo 'total', usiamo quantity
      return reports.take(limit).map((report) {
        return {
          'product_id': report.productId,
          'title': report.title,
          'quantity': report.quantity,
          'total': '0', // Non disponibile nel modello WooTopSellersReport
        };
      }).toList();
    } catch (e) {
      throw Exception('Errore nel caricamento top prodotti: $e');
    }
  }

  /// Ottiene ordini per stato
  Future<Map<String, int>> getOrdersByStatus() async {
    try {
      final woo = _woo;

      // Usa l'API nativa del package
      final List<WooOrderTotalReport> reports = await woo.getOrdersTotalReport();

      final Map<String, int> statusCounts = {};

      for (final report in reports) {
        final slug = report.slug ?? '';
        final total = int.tryParse(report.total ?? '0') ?? 0;
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
      final woo = _woo;

      // Usa l'API nativa del package
      final List<WooCustomerTotalReport> reports = await woo.getCustomersTotalReport();

      // Aggrega i dati dalla lista di report
      int totaleClienti = 0;
      int payingCustomers = 0;
      int newCustomers = 0;

      for (final report in reports) {
        final slug = report.slug ?? '';
        final total = int.tryParse(report.total ?? '0') ?? 0;

        switch (slug) {
          case 'customers':
          case 'all':
            totaleClienti = total;
            break;
          case 'paying':
            payingCustomers = total;
            break;
          case 'new':
            newCustomers = total;
            break;
        }
      }

      return {
        'customers_count': totaleClienti,
        'paying_customers': payingCustomers,
        'new_customers': newCustomers,
        'avg_orders_per_customer': '0', // Non disponibile in questo endpoint
        'avg_lifetime_value': '0', // Non disponibile in questo endpoint
      };
    } catch (e) {
      throw Exception('Errore nel caricamento statistiche clienti: $e');
    }
  }

  /// Ottiene review statistiche
  Future<Map<String, int>> getReviewStats() async {
    try {
      final woo = _woo;

      // Usa l'API nativa del package
      final List<WooProductReviewTotalReport> reports = await woo.getProductReviewsTotalReport();

      final Map<String, int> ratingCounts = {};

      for (final report in reports) {
        final rating = report.slug ?? '';
        final total = int.tryParse(report.total ?? '0') ?? 0;
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
      final woo = _woo;

      // Usa l'API nativa del package
      final List<WooCouponTotalReport> reports = await woo.getCouponsTotalReport();

      // Converti in formato Map (per compatibilità)
      return reports.take(perPage).map((report) {
        return {
          'slug': report.slug,
          'name': report.name,
          'total': report.total,
        };
      }).toList();
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
  ///
  /// WORKAROUND per bug nel package woocommerce_flutter_api:
  /// Il modello WooSalesReportTotals ha campi definiti come int? ma l'API
  /// WooCommerce restituisce stringhe ("0" invece di 0), causando errore:
  /// "type 'String' is not a subtype of type 'int?'"
  ///
  /// Questo metodo usa chiamata raw invece del modello per evitare il problema.
  /// TODO: Aprire issue su https://github.com/loaidev64/woocommerce_flutter_api
  Future<List<Map<String, dynamic>>> getSalesTrend({
    DateTime? dataInizio,
    DateTime? dataFine,
    String period = 'day', // day, week, month
  }) async {
    try {
      final woo = _woo;

      // Formatta le date
      String? dateMin;
      String? dateMax;

      if (dataInizio != null) {
        dateMin = '${dataInizio.year}-${dataInizio.month.toString().padLeft(2, '0')}-${dataInizio.day.toString().padLeft(2, '0')}';
      }

      if (dataFine != null) {
        dateMax = '${dataFine.year}-${dataFine.month.toString().padLeft(2, '0')}-${dataFine.day.toString().padLeft(2, '0')}';
      }

      // Usa chiamata raw per evitare problemi di parsing del modello WooSalesReport
      final queryParameters = <String, dynamic>{
        'context': 'view',
      };
      if (dateMin != null) queryParameters['date_min'] = dateMin;
      if (dateMax != null) queryParameters['date_max'] = dateMax;

      final response = await woo.dio.get('/reports/sales', queryParameters: queryParameters);
      final responseData = response.data;
      final List<dynamic> reportsJson = responseData is List ? responseData : [responseData];

      // Converti in formato Map con parsing manuale sicuro
      final List<Map<String, dynamic>> trends = [];

      for (final reportData in reportsJson) {
        if (reportData is! Map<String, dynamic>) continue;

        // Aggiungi vendite giornaliere se disponibili
        final totalsData = reportData['totals'];
        if (totalsData is Map<String, dynamic>) {
          totalsData.forEach((dateKey, dayData) {
            if (dayData is Map<String, dynamic>) {
              trends.add({
                'date': dateKey,
                'total_sales': parseDoubleSafe(dayData['sales']) ?? 0.0,
                'total_orders': parseIntSafe(dayData['orders']) ?? 0,
                'total_items': parseIntSafe(dayData['items']) ?? 0,
              });
            }
          });
        }
      }

      return trends;
    } catch (e) {
      throw Exception('Errore nel caricamento trend vendite: $e');
    }
  }

  /// Verifica disponibilità servizio
  Future<bool> isServiceAvailable() async {
    try {
      final woo = _woo;
      await woo.getSalesReport();
      return true;
    } catch (e) {
      return false;
    }
  }

  // =======================================================
  // == ANALYTICS CLIENTI                                 ==
  // =======================================================

  /// Recupera le statistiche generali della clientela
  /// Nota: questo metodo è computazionalmente intensivo perché deve recuperare
  /// gli ordini per ogni cliente. Usare con cautela.
  Future<CustomerStatistics> getCustomerStatistics() async {
    final customers = await _woo.getCustomers(perPage: 100);

    if (customers.isEmpty) {
      return CustomerStatistics(
        totalCustomers: 0,
        activeCustomers: 0,
        newCustomersThisMonth: 0,
        averageOrdersPerCustomer: 0.0,
        totalCustomerValue: '0.00',
        averageCustomerValue: '0.00',
        topCountries: [],
      );
    }

    final now = DateTime.now();
    final monthAgo = DateTime(now.year, now.month - 1, now.day);

    // Calcola metriche recuperando gli ordini per ogni cliente
    int totalOrders = 0;
    double totalSpent = 0.0;
    int activeCustomers = 0;

    for (final customer in customers) {
      if (customer.id != null) {
        try {
          final orders = await _woo.getOrders(customer: customer.id!, perPage: 100);
          final orderCount = orders.length;

          if (orderCount > 0) {
            activeCustomers++;
            totalOrders += orderCount;

            // Calcola totale speso
            for (var order in orders) {
              if (order.status == WooOrderStatus.completed || order.status == WooOrderStatus.processing) {
                totalSpent += double.tryParse(order.total?.toString() ?? '0') ?? 0.0;
              }
            }
          }
        } catch (e) {
          // Ignora errori per singoli clienti
        }
      }
    }

    final newCustomers = customers.where((c) =>
      c.dateCreated != null && c.dateCreated!.isAfter(monthAgo)
    ).length;

    final averageOrders = customers.isNotEmpty ? totalOrders / customers.length : 0.0;
    final averageSpent = customers.isNotEmpty ? totalSpent / customers.length : 0.0;

    // Top paesi
    final countryCounts = <String, int>{};
    for (final customer in customers) {
      final country = customer.billing?.country ?? '';
      if (country.isNotEmpty) {
        countryCounts[country] = (countryCounts[country] ?? 0) + 1;
      }
    }

    final topCountries = countryCounts.entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return CustomerStatistics(
      totalCustomers: customers.length,
      activeCustomers: activeCustomers,
      newCustomersThisMonth: newCustomers,
      averageOrdersPerCustomer: averageOrders,
      totalCustomerValue: totalSpent.toStringAsFixed(2),
      averageCustomerValue: averageSpent.toStringAsFixed(2),
      topCountries: topCountries.take(5).map((e) =>
        CountryStatistic(country: e.key, customerCount: e.value)
      ).toList(),
    );
  }

  /// Segmenta i clienti in base al valore degli acquisti
  /// Nota: questo metodo è computazionalmente intensivo perché deve recuperare
  /// gli ordini per ogni cliente. Usare con cautela.
  Future<CustomerSegmentation> getCustomerSegmentation({
    double highValueThreshold = 1000.0,
    double mediumValueThreshold = 100.0,
  }) async {
    final customers = await _woo.getCustomers(perPage: 100);

    List<WooCustomer> highValue = [];
    List<WooCustomer> mediumValue = [];
    List<WooCustomer> lowValue = [];
    List<WooCustomer> inactive = [];

    for (final customer in customers) {
      if (customer.id == null) continue;

      // Recupera gli ordini del cliente
      double totalSpent = 0.0;
      int ordersCount = 0;

      try {
        final orders = await _woo.getOrders(customer: customer.id!, perPage: 100);
        ordersCount = orders.length;

        // Calcola totale speso
        for (var order in orders) {
          if (order.status == WooOrderStatus.completed || order.status == WooOrderStatus.processing) {
            totalSpent += double.tryParse(order.total?.toString() ?? '0') ?? 0.0;
          }
        }
      } catch (e) {
        // Ignora errori per singoli clienti
      }

      if (ordersCount == 0) {
        inactive.add(customer);
      } else if (totalSpent >= highValueThreshold) {
        highValue.add(customer);
      } else if (totalSpent >= mediumValueThreshold) {
        mediumValue.add(customer);
      } else {
        lowValue.add(customer);
      }
    }

    return CustomerSegmentation(
      highValueCustomers: highValue,
      mediumValueCustomers: mediumValue,
      lowValueCustomers: lowValue,
      inactiveCustomers: inactive,
      highValueThreshold: highValueThreshold,
      mediumValueThreshold: mediumValueThreshold,
    );
  }

  /// Recupera i clienti a rischio abbandono
  /// Nota: questo metodo è computazionalmente intensivo perché deve recuperare
  /// gli ordini per ogni cliente. Usare con cautela.
  Future<List<WooCustomer>> getChurnRiskCustomers({
    int daysSinceLastOrder = 90,
    int minPreviousOrders = 2,
  }) async {
    final customers = await _woo.getCustomers(perPage: 100);
    final cutoffDate = DateTime.now().subtract(Duration(days: daysSinceLastOrder));

    List<WooCustomer> churnRiskCustomers = [];

    for (final customer in customers) {
      if (customer.id == null) continue;

      try {
        final orders = await _woo.getOrders(customer: customer.id!, perPage: 100);

        if (orders.length >= minPreviousOrders) {
          // Controlla la data dell'ultimo ordine
          final dateModified = customer.dateModified;

          if (dateModified != null && dateModified.isBefore(cutoffDate)) {
            churnRiskCustomers.add(customer);
          }
        }
      } catch (e) {
        // Ignora errori per singoli clienti
      }
    }

    return churnRiskCustomers;
  }
}

// =======================================================
// == MODELLI ANALYTICS CLIENTI                         ==
// =======================================================

/// Modello per le statistiche generali della clientela
class CustomerStatistics {
  final int totalCustomers;
  final int activeCustomers;
  final int newCustomersThisMonth;
  final double averageOrdersPerCustomer;
  final String totalCustomerValue;
  final String averageCustomerValue;
  final List<CountryStatistic> topCountries;

  CustomerStatistics({
    required this.totalCustomers,
    required this.activeCustomers,
    required this.newCustomersThisMonth,
    required this.averageOrdersPerCustomer,
    required this.totalCustomerValue,
    required this.averageCustomerValue,
    required this.topCountries,
  });
}

/// Modello per le statistiche per paese
class CountryStatistic {
  final String country;
  final int customerCount;

  CountryStatistic({
    required this.country,
    required this.customerCount,
  });
}

/// Modello per la segmentazione dei clienti
class CustomerSegmentation {
  final List<WooCustomer> highValueCustomers;
  final List<WooCustomer> mediumValueCustomers;
  final List<WooCustomer> lowValueCustomers;
  final List<WooCustomer> inactiveCustomers;
  final double highValueThreshold;
  final double mediumValueThreshold;

  CustomerSegmentation({
    required this.highValueCustomers,
    required this.mediumValueCustomers,
    required this.lowValueCustomers,
    required this.inactiveCustomers,
    required this.highValueThreshold,
    required this.mediumValueThreshold,
  });

  /// Restituisce il numero totale di clienti segmentati
  int get totalCustomers =>
    highValueCustomers.length +
    mediumValueCustomers.length +
    lowValueCustomers.length +
    inactiveCustomers.length;

  /// Restituisce la percentuale di clienti di alto valore
  double get highValuePercentage =>
    totalCustomers > 0 ? (highValueCustomers.length / totalCustomers) * 100 : 0.0;

  /// Restituisce la percentuale di clienti inattivi
  double get inactivePercentage =>
    totalCustomers > 0 ? (inactiveCustomers.length / totalCustomers) * 100 : 0.0;
}
