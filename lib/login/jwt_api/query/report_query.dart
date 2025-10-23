/* /*
 * reports_query.dart
 * 
 * Servizio per la gestione dei Report delle Vendite WooCommerce.
 * Fornisce funzionalità per recuperare statistiche di vendita, 
 * report sui prodotti più venduti, analisi temporali e metriche di business.
 */

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../jwt_connect.dart';
import '../error_list.dart';

// =======================================================
// ==           CLASSE BASE PER I SERVIZI REPORT        ==
// =======================================================

/// Classe base astratta per tutti i servizi di report WooCommerce.
/// Fornisce funzionalità comuni per le richieste API dei report.
abstract class _ReportService {
  final JwtConnect _jwt;
  
  _ReportService(this._jwt);

  /// Esegue una richiesta HTTP autenticata per i report.
  /// 
  /// [method] - Metodo HTTP (GET, POST, ecc.)
  /// [endpoint] - Endpoint dell'API WooCommerce
  /// [queryParams] - Parametri di query opzionali
  /// [body] - Corpo della richiesta per POST/PUT
  /// 
  /// Throws [UnauthorizedException] se il token JWT non è valido
  /// Throws [ReportException] per errori specifici dei report
  Future<dynamic> _request(String method, String endpoint, {
    Map<String, String>? queryParams, 
    Map<String, dynamic>? body
  }) async {
    
    // Controllo preventivo della connessione
    if (_jwt.currentSiteUrl == null || !_jwt.isConnected) {
      throw UnauthorizedException();
    }

    final uri = _jwt.buildUri(_jwt.currentSiteUrl!, endpoint, queryParams: queryParams);
    
    try {
      // Esegue la richiesta autenticata
      final response = await _jwt.authenticatedRequest(method, uri, body: body);
      return _handleResponse(response);

    } on UnauthorizedException {
      // Pulisce lo stato locale se il token non è più valido
      await _jwt.disconnect();
      rethrow;
    }
  }

  /// Gestisce la risposta HTTP e converte gli errori in eccezioni specifiche.
  dynamic _handleResponse(http.Response response) {
    try {
      final jsonBody = jsonDecode(response.body);
      
      if (response.statusCode >= 400) {
        // Gestisce errori specifici dei report
        if (response.statusCode == 400) {
          final String code = jsonBody['code'] ?? 'report_error';
          final String message = jsonBody['message'] ?? 'Errore nel report richiesto.';
          throw ReportException(code: code, message: message);
        }
        
        // Delega altri errori al gestore centralizzato
        ErrorHandler.throwFromResponse(response);
      }
      
      return jsonBody;
      
    } on FormatException {
      throw InvalidResponseFormatException();
    }
  }
}

// =======================================================
// ==              SERVIZIO REPORT VENDITE              ==
// =======================================================

/// Servizio per la gestione dei report delle vendite WooCommerce.
/// 
/// Fornisce accesso a:
/// - Statistiche di vendita generale
/// - Report sui prodotti più venduti
/// - Analisi temporali delle vendite
/// - Metriche di performance
class SalesReportService extends _ReportService {
  SalesReportService(JwtConnect jwt) : super(jwt);

  /// Recupera le statistiche generali delle vendite.
  /// 
  /// [period] - Periodo di tempo (week, month, year, custom)
  /// [dateMin] - Data di inizio per periodo custom (formato: YYYY-MM-DD)
  /// [dateMax] - Data di fine per periodo custom (formato: YYYY-MM-DD)
  /// 
  /// Returns [SalesReport] con le statistiche di vendita
  Future<SalesReport> getSalesStats({
    String period = 'month',
    String? dateMin,
    String? dateMax,
  }) async {
    final queryParams = <String, String>{'period': period};
    
    if (period == 'custom') {
      if (dateMin != null) queryParams['date_min'] = dateMin;
      if (dateMax != null) queryParams['date_max'] = dateMax;
    }
    
    final reportData = await _request('GET', 'wc/v3/reports/sales', queryParams: queryParams);
    return SalesReport.fromJson(reportData);
  }

  /// Recupera i prodotti più venduti.
  /// 
  /// [period] - Periodo di analisi
  /// [limit] - Numero massimo di prodotti da restituire
  /// 
  /// Returns Lista di [TopProduct]
  Future<List<TopProduct>> getTopProducts({
    String period = 'month',
    int limit = 10,
  }) async {
    final queryParams = <String, String>{
      'period': period,
      'limit': limit.toString(),
    };
    
    final List<dynamic> productsData = await _request(
      'GET', 
      'wc/v3/reports/top_sellers', 
      queryParams: queryParams
    );
    
    return productsData.map((data) => TopProduct.fromJson(data)).toList();
  }

  /// Recupera il report delle vendite per categoria.
  /// 
  /// [period] - Periodo di analisi
  /// [categories] - Lista di ID delle categorie (opzionale)
  /// 
  /// Returns Lista di [CategorySales]
  Future<List<CategorySales>> getCategorySales({
    String period = 'month',
    List<int>? categories,
  }) async {
    final queryParams = <String, String>{'period': period};
    
    if (categories != null && categories.isNotEmpty) {
      queryParams['categories'] = categories.join(',');
    }
    
    final List<dynamic> salesData = await _request(
      'GET', 
      'wc/v3/reports/sales/categories', 
      queryParams: queryParams
    );
    
    return salesData.map((data) => CategorySales.fromJson(data)).toList();
  }

  /// Recupera le statistiche dei clienti.
  /// 
  /// [period] - Periodo di analisi
  /// 
  /// Returns [CustomerStats] con le metriche sui clienti
  Future<CustomerStats> getCustomerStats({
    String period = 'month',
  }) async {
    final queryParams = <String, String>{'period': period};
    
    final statsData = await _request(
      'GET', 
      'wc/v3/reports/customers', 
      queryParams: queryParams
    );
    
    return CustomerStats.fromJson(statsData);
  }

  /// Recupera il report degli ordini.
  /// 
  /// [period] - Periodo di analisi
  /// [status] - Status degli ordini da includere (opzionale)
  /// 
  /// Returns [OrdersReport] con le statistiche degli ordini
  Future<OrdersReport> getOrdersReport({
    String period = 'month',
    String? status,
  }) async {
    final queryParams = <String, String>{'period': period};
    
    if (status != null) {
      queryParams['status'] = status;
    }
    
    final reportData = await _request(
      'GET', 
      'wc/v3/reports/orders', 
      queryParams: queryParams
    );
    
    return OrdersReport.fromJson(reportData);
  }

  /// Recupera le metriche di performance per un periodo personalizzato.
  /// 
  /// [startDate] - Data di inizio (formato: YYYY-MM-DD)
  /// [endDate] - Data di fine (formato: YYYY-MM-DD)
  /// [granularity] - Granularità dei dati (day, week, month)
  /// 
  /// Returns Lista di [PerformanceMetric]
  Future<List<PerformanceMetric>> getPerformanceMetrics({
    required String startDate,
    required String endDate,
    String granularity = 'day',
  }) async {
    final queryParams = <String, String>{
      'after': startDate,
      'before': endDate,
      'interval': granularity,
    };
    
    final List<dynamic> metricsData = await _request(
      'GET', 
      'wc/v3/reports/revenue', 
      queryParams: queryParams
    );
    
    return metricsData.map((data) => PerformanceMetric.fromJson(data)).toList();
  }
}

// =======================================================
// ==                 MODELLI DI DATI                   ==
// =======================================================

/// Modello per il report generale delle vendite.
class SalesReport {
  final String totalSales;
  final String netSales;
  final String averageOrderValue;
  final int totalOrders;
  final int totalItems;
  final String totalTax;
  final String totalShipping;
  final int totalRefunds;
  final int totalDiscount;
  final String totalsGroupedBy;
  
  SalesReport({
    required this.totalSales,
    required this.netSales,
    required this.averageOrderValue,
    required this.totalOrders,
    required this.totalItems,
    required this.totalTax,
    required this.totalShipping,
    required this.totalRefunds,
    required this.totalDiscount,
    required this.totalsGroupedBy,
  });

  factory SalesReport.fromJson(Map<String, dynamic> json) {
    return SalesReport(
      totalSales: json['total_sales'] ?? '0',
      netSales: json['net_sales'] ?? '0',
      averageOrderValue: json['average_sales'] ?? '0',
      totalOrders: json['total_orders'] ?? 0,
      totalItems: json['total_items'] ?? 0,
      totalTax: json['total_tax'] ?? '0',
      totalShipping: json['total_shipping'] ?? '0',
      totalRefunds: json['total_refunds'] ?? 0,
      totalDiscount: json['total_discount'] ?? 0,
      totalsGroupedBy: json['totals_grouped_by'] ?? 'day',
    );
  }
}

/// Modello per i prodotti più venduti.
class TopProduct {
  final int productId;
  final String title;
  final int quantity;
  final String total;
  
  TopProduct({
    required this.productId,
    required this.title,
    required this.quantity,
    required this.total,
  });

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      productId: json['product_id'] ?? 0,
      title: json['title'] ?? '',
      quantity: json['quantity'] ?? 0,
      total: json['total'] ?? '0',
    );
  }
}

/// Modello per le vendite per categoria.
class CategorySales {
  final int categoryId;
  final String categoryName;
  final String totalSales;
  final int totalOrders;
  final int totalItems;
  
  CategorySales({
    required this.categoryId,
    required this.categoryName,
    required this.totalSales,
    required this.totalOrders,
    required this.totalItems,
  });

  factory CategorySales.fromJson(Map<String, dynamic> json) {
    return CategorySales(
      categoryId: json['category_id'] ?? 0,
      categoryName: json['category_name'] ?? '',
      totalSales: json['total_sales'] ?? '0',
      totalOrders: json['total_orders'] ?? 0,
      totalItems: json['total_items'] ?? 0,
    );
  }
}

/// Modello per le statistiche sui clienti.
class CustomerStats {
  final int totalCustomers;
  final int payingCustomers;
  final int newCustomers;
  final String averageOrdersPerCustomer;
  final String averageLifetimeValue;
  
  CustomerStats({
    required this.totalCustomers,
    required this.payingCustomers,
    required this.newCustomers,
    required this.averageOrdersPerCustomer,
    required this.averageLifetimeValue,
  });

  factory CustomerStats.fromJson(Map<String, dynamic> json) {
    return CustomerStats(
      totalCustomers: json['customers_count'] ?? 0,
      payingCustomers: json['paying_customers'] ?? 0,
      newCustomers: json['new_customers'] ?? 0,
      averageOrdersPerCustomer: json['avg_orders_per_customer'] ?? '0',
      averageLifetimeValue: json['avg_lifetime_value'] ?? '0',
    );
  }
}

/// Modello per il report degli ordini.
class OrdersReport {
  final int totalOrders;
  final int completedOrders;
  final int pendingOrders;
  final int processingOrders;
  final int cancelledOrders;
  final int refundedOrders;
  final String totalRevenue;
  
  OrdersReport({
    required this.totalOrders,
    required this.completedOrders,
    required this.pendingOrders,
    required this.processingOrders,
    required this.cancelledOrders,
    required this.refundedOrders,
    required this.totalRevenue,
  });

  factory OrdersReport.fromJson(Map<String, dynamic> json) {
    return OrdersReport(
      totalOrders: json['total_orders'] ?? 0,
      completedOrders: json['completed_orders'] ?? 0,
      pendingOrders: json['pending_orders'] ?? 0,
      processingOrders: json['processing_orders'] ?? 0,
      cancelledOrders: json['cancelled_orders'] ?? 0,
      refundedOrders: json['refunded_orders'] ?? 0,
      totalRevenue: json['total_revenue'] ?? '0',
    );
  }
}

/// Modello per le metriche di performance.
class PerformanceMetric {
  final String date;
  final String revenue;
  final int orders;
  final int items;
  final String averageOrderValue;
  final int customers;
  
  PerformanceMetric({
    required this.date,
    required this.revenue,
    required this.orders,
    required this.items,
    required this.averageOrderValue,
    required this.customers,
  });

  factory PerformanceMetric.fromJson(Map<String, dynamic> json) {
    return PerformanceMetric(
      date: json['date_start'] ?? '',
      revenue: json['total_sales'] ?? '0',
      orders: json['orders_count'] ?? 0,
      items: json['num_items_sold'] ?? 0,
      averageOrderValue: json['avg_order_value'] ?? '0',
      customers: json['customers_count'] ?? 0,
    );
  }
}

/// Servizio principale per aggregare tutti i servizi di report
class ReportsService {
  final JwtConnect _jwt;
  
  late final SalesReportService salesReportService;

  ReportsService(this._jwt) {
    salesReportService = SalesReportService(_jwt);
  }
} */