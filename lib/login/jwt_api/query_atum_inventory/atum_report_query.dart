// ATUM Report Query - Statistiche e report ATUM
//
// Gestisce tutte le operazioni di reportistica ATUM
// Include: statistiche vendite, inventario, perdite, performance

import 'dart:async';

import './atum_connect.dart';
import '../../../log_viewer/app_logger.dart';

/// Tipi report ATUM
enum AtumReportType {
  sales,
  inventory,
  lostSales,
  performance,
  financial,
}

/// Filtri per report
class ReportFilters {
  final AtumReportType reportType;
  final String? dateFrom;
  final String? dateTo;
  final int? categoryId;
  final int? supplierId;
  final String? location;
  final String? groupBy; // 'day', 'week', 'month', 'year'
  final String? format; // 'json', 'csv', 'pdf'

  ReportFilters({
    required this.reportType,
    this.dateFrom,
    this.dateTo,
    this.categoryId,
    this.supplierId,
    this.location,
    this.groupBy,
    this.format,
  });
}

/// Statistiche vendite ATUM
class AtumSalesStats {
  final double totalRevenue;
  final int totalOrders;
  final int totalItemsSold;
  final double averageOrderValue;
  final Map<String, double> revenueByCategory;
  final Map<String, double> revenueByProduct;
  final List<Map<String, dynamic>> topSellingProducts;
  final List<Map<String, dynamic>> salesByPeriod;

  AtumSalesStats({
    required this.totalRevenue,
    required this.totalOrders,
    required this.totalItemsSold,
    required this.averageOrderValue,
    required this.revenueByCategory,
    required this.revenueByProduct,
    required this.topSellingProducts,
    required this.salesByPeriod,
  });

  factory AtumSalesStats.fromJson(Map<String, dynamic> json) {
    return AtumSalesStats(
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
      totalOrders: json['total_orders'] ?? 0,
      totalItemsSold: json['total_items_sold'] ?? 0,
      averageOrderValue: (json['average_order_value'] ?? 0).toDouble(),
      revenueByCategory: Map<String, double>.from(json['revenue_by_category'] ?? {}),
      revenueByProduct: Map<String, double>.from(json['revenue_by_product'] ?? {}),
      topSellingProducts: List<Map<String, dynamic>>.from(json['top_selling_products'] ?? []),
      salesByPeriod: List<Map<String, dynamic>>.from(json['sales_by_period'] ?? []),
    );
  }
}

/// Statistiche inventario ATUM
class AtumInventoryReport {
  final int totalProducts;
  final int inStockCount;
  final int lowStockCount;
  final int outOfStockCount;
  final double totalInventoryValue;
  final Map<String, int> stockLevelsByCategory;
  final List<Map<String, dynamic>> lowStockItems;
  final List<Map<String, dynamic>> excessStockItems;
  final double averageStockValue;

  AtumInventoryReport({
    required this.totalProducts,
    required this.inStockCount,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.totalInventoryValue,
    required this.stockLevelsByCategory,
    required this.lowStockItems,
    required this.excessStockItems,
    required this.averageStockValue,
  });

  factory AtumInventoryReport.fromJson(Map<String, dynamic> json) {
    return AtumInventoryReport(
      totalProducts: json['total_products'] ?? 0,
      inStockCount: json['in_stock_count'] ?? 0,
      lowStockCount: json['low_stock_count'] ?? 0,
      outOfStockCount: json['out_of_stock_count'] ?? 0,
      totalInventoryValue: (json['total_inventory_value'] ?? 0).toDouble(),
      stockLevelsByCategory: Map<String, int>.from(json['stock_levels_by_category'] ?? {}),
      lowStockItems: List<Map<String, dynamic>>.from(json['low_stock_items'] ?? []),
      excessStockItems: List<Map<String, dynamic>>.from(json['excess_stock_items'] ?? []),
      averageStockValue: (json['average_stock_value'] ?? 0).toDouble(),
    );
  }
}

/// Statistiche vendite perse ATUM
class AtumLostSalesReport {
  final int totalLostSales;
  final double totalLostRevenue;
  final List<Map<String, dynamic>> lostSalesByProduct;
  final List<Map<String, dynamic>> lostSalesByCategory;
  final Map<String, int> lostSalesByReason;

  AtumLostSalesReport({
    required this.totalLostSales,
    required this.totalLostRevenue,
    required this.lostSalesByProduct,
    required this.lostSalesByCategory,
    required this.lostSalesByReason,
  });

  factory AtumLostSalesReport.fromJson(Map<String, dynamic> json) {
    return AtumLostSalesReport(
      totalLostSales: json['total_lost_sales'] ?? 0,
      totalLostRevenue: (json['total_lost_revenue'] ?? 0).toDouble(),
      lostSalesByProduct: List<Map<String, dynamic>>.from(json['lost_sales_by_product'] ?? []),
      lostSalesByCategory: List<Map<String, dynamic>>.from(json['lost_sales_by_category'] ?? []),
      lostSalesByReason: Map<String, int>.from(json['lost_sales_by_reason'] ?? {}),
    );
  }
}

/// Statistiche performance ATUM
class AtumPerformanceReport {
  final Map<String, double> profitMargins;
  final Map<String, double> inventoryTurnover;
  final List<Map<String, dynamic>> bestPerformingProducts;
  final List<Map<String, dynamic>> worstPerformingProducts;
  final double averageDaysInStock;
  final Map<String, double> supplierPerformance;

  AtumPerformanceReport({
    required this.profitMargins,
    required this.inventoryTurnover,
    required this.bestPerformingProducts,
    required this.worstPerformingProducts,
    required this.averageDaysInStock,
    required this.supplierPerformance,
  });

  factory AtumPerformanceReport.fromJson(Map<String, dynamic> json) {
    return AtumPerformanceReport(
      profitMargins: Map<String, double>.from(json['profit_margins'] ?? {}),
      inventoryTurnover: Map<String, double>.from(json['inventory_turnover'] ?? {}),
      bestPerformingProducts: List<Map<String, dynamic>>.from(json['best_performing_products'] ?? []),
      worstPerformingProducts: List<Map<String, dynamic>>.from(json['worst_performing_products'] ?? []),
      averageDaysInStock: (json['average_days_in_stock'] ?? 0).toDouble(),
      supplierPerformance: Map<String, double>.from(json['supplier_performance'] ?? {}),
    );
  }
}

/// Service per gestire i report ATUM
class AtumReportQuery {
  // Singleton
  static final AtumReportQuery _instance = AtumReportQuery._internal();
  factory AtumReportQuery() => _instance;
  AtumReportQuery._internal();

  final AtumConnect _atumConnect = AtumConnect();

  /// Ottiene l'istanza ATUM autenticata
  AtumConnect get _atum => _atumConnect;

  // =======================================================
  // == METODI REPORTISTICA ATUM                    ==
  // =======================================================

  /// Ottiene statistiche vendite
  Future<AtumSalesStats> getSalesStatistics({
    String? dateFrom,
    String? dateTo,
    String? groupBy = 'month',
    int? categoryId,
    int? supplierId,
  }) async {
    try {
      log.d('Getting ATUM sales statistics...');
      
      final queryParams = <String, String>{
        'date_from': dateFrom ?? '',
        'date_to': dateTo ?? '',
        'group_by': groupBy ?? '',

      };

      final response = await _atum.atumRequest('GET', '/reports/sales', queryParams: queryParams);
      
      return AtumSalesStats.fromJson(response['data'] ?? {});
    } catch (e) {
      log.e('Error getting sales statistics: $e');
      rethrow;
    }
  }

  /// Ottiene report inventario
  Future<AtumInventoryReport> getInventoryReport({
    String? dateFrom,
    String? dateTo,
    String? location,
    bool? includeZeroStock = false,
    String? groupBy = 'month',
  }) async {
    try {
      log.d('Getting ATUM inventory report...');
      
      final queryParams = <String, String>{
        'date_from': dateFrom ?? '',
        'date_to': dateTo ?? '',
        'group_by': groupBy ?? '',
      };

      final response = await _atum.atumRequest('GET', '/reports/inventory', queryParams: queryParams);
      
      return AtumInventoryReport.fromJson(response['data'] ?? {});
    } catch (e) {
      log.e('Error getting inventory report: $e');
      rethrow;
    }
  }

  /// Ottiene report finanziario
  Future<Map<String, dynamic>> getFinancialReport({
    String? dateFrom,
    String? dateTo,
    String? groupBy = 'month',
  }) async {
    try {
      log.d('Getting ATUM financial report...');
      
      final queryParams = <String, String>{
        'date_from': dateFrom ?? '',
        'date_to': dateTo ?? '',
        'group_by': groupBy ?? '',
      };

      final response = await _atum.atumRequest('GET', '/reports/financial', queryParams: queryParams);
      
      return response['data'] ?? {};
    } catch (e) {
      log.e('Error getting financial report: $e');
      rethrow;
    }
  }

  /// Genera report personalizzato
  Future<Map<String, dynamic>> generateCustomReport({
    required ReportFilters filters,
    required List<String> fields, // campi da includere
    String format = 'json',
  }) async {
    try {
      log.d('Generating ATUM custom report...');
      
      final data = {
        'report_type': filters.reportType.name,
        'date_from': filters.dateFrom,
        'date_to': filters.dateTo,
        'fields': fields,
        'format': format,
        if (filters.categoryId != null) 'category_id': filters.categoryId,
        if (filters.supplierId != null) 'supplier_id': filters.supplierId,
        if (filters.location != null) 'location': filters.location,
        if (filters.groupBy != null) 'group_by': filters.groupBy,
      };

      final response = await _atum.atumRequest('POST', '/reports/custom', data: data);
      
      log.i('✅ Custom report generated successfully');
      return response['data'] ?? {};
    } catch (e) {
      log.e('Error generating custom report: $e');
      rethrow;
    }
  }

  /// Esporta report in formato specifico
  Future<String?> exportReport({
    required String reportId,
    required String format, // 'csv', 'pdf', 'excel'
    Map<String, dynamic>? filters,
  }) async {
    try {
      log.d('Exporting ATUM report: $reportId, format=$format');
      
      final data = {
        'format': format,
        if (filters != null) 'filters': filters,
      };

      final response = await _atum.atumRequest('POST', '/reports/$reportId/export', data: data);
      
      if (response['success'] == true) {
        log.i('✅ Report exported successfully');
        return response['export_url'];
      } else {
        log.w('⚠️ Report export failed: ${response['message']}');
        return null;
      }
    } catch (e) {
      log.e('Error exporting report: $e');
      rethrow;
    }
  }

  /// Ottiene widget dashboard
  Future<Map<String, dynamic>> getDashboardWidget() async {
    try {
      log.d('Getting ATUM dashboard widget...');
      
      final response = await _atum.atumRequest('GET', '/reports/dashboard-widget');
      
      return response['data'] ?? {};
    } catch (e) {
      log.e('Error getting dashboard widget: $e');
      rethrow;
    }
  }

  /// Ottiene statistiche generali
  Future<Map<String, dynamic>> getGeneralStatistics() async {
    try {
      log.d('Getting ATUM general statistics...');
      
      final response = await _atum.atumRequest('GET', '/reports/general-statistics');
      
      return response['data'] ?? {};
    } catch (e) {
      log.e('Error getting general statistics: $e');
      rethrow;
    }
  }

  /// Verifica disponibilità servizio report
  Future<bool> isReportServiceAvailable() async {
    try {
      await getSalesStatistics();
      return true;
    } catch (e) {
      log.w('ATUM Report service not available: $e');
      return false;
    }
  }
}