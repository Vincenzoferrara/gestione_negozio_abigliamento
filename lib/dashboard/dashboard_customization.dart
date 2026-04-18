// Dashboard Customization - Sistema di dashboard personalizzabile con griglia
//
// Permette all'utente di:
// - Riordinare i widget tramite drag & drop in griglia
// - Scegliere il tipo di grafico per ogni widget
// - Mostrare/nascondere widget
// - Ridimensionare widget
// - Salvare le preferenze

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dashboard_grid/dashboard_grid.dart';
import '../notification/notification_service.dart';
import 'dashboard.code.dart';
import 'dashboard_charts.dart';
import 'ads_dashboard.code.dart';
import '../login/gui/login.code.dart';
import 'ads_comment_manager.dart';
import 'ads_comment_dialog.dart';

// =======================================================
// ==              MODELLI CONFIGURAZIONE               ==
// =======================================================

/// Tipi di grafico disponibili
enum ChartType { line, bar, pie, area, radar }

/// Configurazione di un widget della dashboard
class DashboardWidgetConfig {
  final String id;
  final String title;
  final String dataSource; // 'vendite', 'ordini', 'prodotti', 'clienti'
  ChartType chartType;
  bool visible;
  int x; // colonna nella griglia
  int y; // riga nella griglia
  int width; // larghezza in celle
  int height; // altezza in celle

  DashboardWidgetConfig({
    required this.id,
    required this.title,
    required this.dataSource,
    this.chartType = ChartType.line,
    this.visible = true,
    this.x = 0,
    this.y = 0,
    this.width = 2,
    this.height = 2,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'dataSource': dataSource,
    'chartType': chartType.index,
    'visible': visible,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
  };

  factory DashboardWidgetConfig.fromJson(Map<String, dynamic> json) {
    return DashboardWidgetConfig(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      dataSource: json['dataSource'] ?? '',
      chartType: ChartType.values[json['chartType'] ?? 0],
      visible: json['visible'] ?? true,
      x: json['x'] ?? 0,
      y: json['y'] ?? 0,
      width: json['width'] ?? 2,
      height: json['height'] ?? 2,
    );
  }

  /// Tipi di grafico supportati per questa data source
  List<ChartType> get supportedChartTypes {
    switch (dataSource) {
      case 'vendite':
        return [ChartType.line, ChartType.bar, ChartType.area];
      case 'ordini':
        return [ChartType.pie, ChartType.bar];
      case 'prodotti':
        return [ChartType.bar, ChartType.pie];
      case 'ordini_tempo':
        return [ChartType.bar, ChartType.line];
      // Meta Ads
      case 'ads_meta_campaigns':
      case 'ads_meta_reach':
      case 'ads_meta_impressions':
      case 'ads_meta_conversions':
      case 'ads_meta_adsets':
        return [ChartType.bar, ChartType.line];
      case 'ads_meta_frequency':
      case 'ads_meta_cpm':
      case 'ads_meta_ctr':
      case 'ads_meta_cpc':
      case 'ads_meta_roas':
        return [ChartType.line, ChartType.area];
      case 'ads_meta_spend':
      case 'ads_meta_audience':
        return [ChartType.pie, ChartType.bar];
      case 'ads_meta_budget_vs_spend':
        return [ChartType.bar];

      // Instagram
      case 'ads_instagram_media':
      case 'ads_instagram_stories':
      case 'ads_instagram_reels':
      case 'ads_instagram_reach':
      case 'ads_instagram_impressions':
      case 'ads_instagram_best_times':
        return [ChartType.bar, ChartType.line];
      case 'ads_instagram_engagement':
      case 'ads_instagram_engagement_rate':
      case 'ads_instagram_followers':
        return [ChartType.line, ChartType.area];

      // Google Ads
      case 'ads_google_campaigns':
      case 'ads_google_search':
      case 'ads_google_display':
      case 'ads_google_impressions':
      case 'ads_google_conversions':
      case 'ads_google_conversion_value':
      case 'ads_google_keywords':
      case 'ads_google_quality_score':
      case 'ads_google_roas':
        return [ChartType.bar, ChartType.line];
      case 'ads_google_clicks':
      case 'ads_google_ctr':
      case 'ads_google_cpc':
        return [ChartType.line, ChartType.area];
      case 'ads_google_cost':
        return [ChartType.pie, ChartType.bar];

      // TikTok Ads
      case 'ads_tiktok_campaigns':
      case 'ads_tiktok_impressions':
      case 'ads_tiktok_video_views':
      case 'ads_tiktok_conversions':
      case 'ads_tiktok_creative':
        return [ChartType.bar, ChartType.line];
      case 'ads_tiktok_clicks':
      case 'ads_tiktok_engagement':
      case 'ads_tiktok_engagement_rate':
      case 'ads_tiktok_cpm':
      case 'ads_tiktok_cpc':
        return [ChartType.line, ChartType.area];
      case 'ads_tiktok_spend':
      case 'ads_tiktok_audience':
        return [ChartType.pie, ChartType.bar];

      // Cross-platform & Aggregate
      case 'ads_total_spend':
      case 'ads_budget_allocation':
        return [ChartType.pie, ChartType.bar];
      case 'ads_total_impressions':
      case 'ads_total_clicks':
      case 'ads_total_conversions':
      case 'ads_roi':
      case 'ads_roas_comparison':
      case 'ads_platform_performance':
      case 'ads_ctr_comparison':
      case 'ads_cpc_comparison':
        return [ChartType.bar, ChartType.line];

      // Section divider - widget speciale
      case 'section_divider':
        return [
          ChartType.bar,
        ]; // Non cambier� tipo, ma serve per non dare errori

      default:
        return ChartType.values;
    }
  }

  String get chartTypeName {
    switch (chartType) {
      case ChartType.line:
        return 'Linea';
      case ChartType.bar:
        return 'Barre';
      case ChartType.pie:
        return 'Torta';
      case ChartType.area:
        return 'Area';
      case ChartType.radar:
        return 'Radar';
    }
  }

  IconData get chartTypeIcon {
    switch (chartType) {
      case ChartType.line:
        return Icons.show_chart;
      case ChartType.bar:
        return Icons.bar_chart;
      case ChartType.pie:
        return Icons.pie_chart;
      case ChartType.area:
        return Icons.area_chart;
      case ChartType.radar:
        return Icons.radar;
    }
  }
}

// =======================================================
// ==           MANAGER LAYOUT DASHBOARD                ==
// =======================================================

/// Gestisce il salvataggio e caricamento delle preferenze dashboard
class DashboardLayoutManager {
  static const String _prefsKey = 'dashboard_layout_grid';

  /// Widget di default con posizioni griglia
  static List<DashboardWidgetConfig> getDefaultWidgets() {
    return [
      DashboardWidgetConfig(
        id: 'vendite_trend',
        title: 'Andamento Vendite',
        dataSource: 'vendite',
        chartType: ChartType.line,
        x: 0,
        y: 0,
        width: 2,
        height: 2,
      ),
      DashboardWidgetConfig(
        id: 'top_prodotti',
        title: 'Top Prodotti',
        dataSource: 'prodotti',
        chartType: ChartType.bar,
        x: 2,
        y: 0,
        width: 2,
        height: 2,
      ),
      DashboardWidgetConfig(
        id: 'ordini_stato',
        title: 'Ordini per Stato',
        dataSource: 'ordini',
        chartType: ChartType.pie,
        x: 0,
        y: 2,
        width: 2,
        height: 2,
      ),
      DashboardWidgetConfig(
        id: 'ordini_tempo',
        title: 'Ordini nel Tempo',
        dataSource: 'ordini_tempo',
        chartType: ChartType.bar,
        x: 2,
        y: 2,
        width: 2,
        height: 2,
      ),
      // Widget aggiuntivi (nascosti di default)
      DashboardWidgetConfig(
        id: 'totale_ordini',
        title: 'Totale Ordini',
        dataSource: 'totale_ordini',
        chartType: ChartType.bar,
        x: 0,
        y: 4,
        width: 2,
        height: 1,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'coupon_usati',
        title: 'Coupon Utilizzati',
        dataSource: 'coupon',
        chartType: ChartType.pie,
        x: 2,
        y: 4,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'prodotti_esauriti',
        title: 'Prodotti Esauriti',
        dataSource: 'prodotti_esauriti',
        chartType: ChartType.bar,
        x: 0,
        y: 5,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'clienti_top',
        title: 'Migliori Clienti',
        dataSource: 'clienti',
        chartType: ChartType.bar,
        x: 2,
        y: 6,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'fatturato_totale',
        title: 'Fatturato Totale',
        dataSource: 'fatturato',
        chartType: ChartType.line,
        x: 0,
        y: 7,
        width: 4,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'media_ordine',
        title: 'Media per Ordine',
        dataSource: 'media_ordine',
        chartType: ChartType.line,
        x: 0,
        y: 9,
        width: 2,
        height: 2,
        visible: false,
      ),
      // ============ SEZIONE: META ADS ============
      // Performance generale
      DashboardWidgetConfig(
        id: 'ads_meta_campaigns',
        title: 'Meta - Campagne Attive',
        dataSource: 'ads_meta_campaigns',
        chartType: ChartType.bar,
        x: 0,
        y: 11,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_meta_reach',
        title: 'Meta - Reach',
        dataSource: 'ads_meta_reach',
        chartType: ChartType.line,
        x: 2,
        y: 11,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_meta_impressions',
        title: 'Meta - Impressioni',
        dataSource: 'ads_meta_impressions',
        chartType: ChartType.bar,
        x: 0,
        y: 13,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_meta_frequency',
        title: 'Meta - Frequenza',
        dataSource: 'ads_meta_frequency',
        chartType: ChartType.line,
        x: 2,
        y: 13,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_meta_cpm',
        title: 'Meta - CPM',
        dataSource: 'ads_meta_cpm',
        chartType: ChartType.line,
        x: 0,
        y: 15,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_meta_ctr',
        title: 'Meta - CTR',
        dataSource: 'ads_meta_ctr',
        chartType: ChartType.line,
        x: 2,
        y: 15,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_meta_cpc',
        title: 'Meta - CPC',
        dataSource: 'ads_meta_cpc',
        chartType: ChartType.line,
        x: 0,
        y: 17,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_meta_spend',
        title: 'Meta - Spesa',
        dataSource: 'ads_meta_spend',
        chartType: ChartType.pie,
        x: 2,
        y: 17,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_meta_conversions',
        title: 'Meta - Conversioni',
        dataSource: 'ads_meta_conversions',
        chartType: ChartType.bar,
        x: 0,
        y: 19,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_meta_roas',
        title: 'Meta - ROAS',
        dataSource: 'ads_meta_roas',
        chartType: ChartType.bar,
        x: 2,
        y: 19,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_meta_adsets',
        title: 'Meta - Ad Sets Performance',
        dataSource: 'ads_meta_adsets',
        chartType: ChartType.bar,
        x: 0,
        y: 21,
        width: 4,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_meta_audience',
        title: 'Meta - Audience Insights',
        dataSource: 'ads_meta_audience',
        chartType: ChartType.pie,
        x: 0,
        y: 23,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_meta_budget_vs_spend',
        title: 'Meta - Budget vs Spesa',
        dataSource: 'ads_meta_budget_vs_spend',
        chartType: ChartType.bar,
        x: 2,
        y: 23,
        width: 2,
        height: 2,
        visible: false,
      ),

      // ============ SEZIONE: INSTAGRAM ============
      DashboardWidgetConfig(
        id: 'ads_instagram_media',
        title: 'Instagram - Post Pubblicati',
        dataSource: 'ads_instagram_media',
        chartType: ChartType.bar,
        x: 0,
        y: 25,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_instagram_engagement',
        title: 'Instagram - Engagement',
        dataSource: 'ads_instagram_engagement',
        chartType: ChartType.line,
        x: 2,
        y: 25,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_instagram_engagement_rate',
        title: 'Instagram - Tasso Engagement',
        dataSource: 'ads_instagram_engagement_rate',
        chartType: ChartType.line,
        x: 0,
        y: 27,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_instagram_stories',
        title: 'Instagram - Stories Analytics',
        dataSource: 'ads_instagram_stories',
        chartType: ChartType.bar,
        x: 2,
        y: 27,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_instagram_reels',
        title: 'Instagram - Reels Performance',
        dataSource: 'ads_instagram_reels',
        chartType: ChartType.bar,
        x: 0,
        y: 29,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_instagram_followers',
        title: 'Instagram - Crescita Follower',
        dataSource: 'ads_instagram_followers',
        chartType: ChartType.line,
        x: 2,
        y: 29,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_instagram_reach',
        title: 'Instagram - Reach',
        dataSource: 'ads_instagram_reach',
        chartType: ChartType.bar,
        x: 0,
        y: 31,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_instagram_impressions',
        title: 'Instagram - Impressioni',
        dataSource: 'ads_instagram_impressions',
        chartType: ChartType.bar,
        x: 2,
        y: 31,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_instagram_best_times',
        title: 'Instagram - Orari Migliori',
        dataSource: 'ads_instagram_best_times',
        chartType: ChartType.bar,
        x: 0,
        y: 33,
        width: 4,
        height: 2,
        visible: false,
      ),

      // ============ SEZIONE: GOOGLE ADS ============
      DashboardWidgetConfig(
        id: 'ads_google_campaigns',
        title: 'Google - Campagne Attive',
        dataSource: 'ads_google_campaigns',
        chartType: ChartType.bar,
        x: 0,
        y: 35,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_google_search',
        title: 'Google - Search Campaigns',
        dataSource: 'ads_google_search',
        chartType: ChartType.bar,
        x: 2,
        y: 35,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_google_display',
        title: 'Google - Display Campaigns',
        dataSource: 'ads_google_display',
        chartType: ChartType.bar,
        x: 0,
        y: 37,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_google_impressions',
        title: 'Google - Impressioni',
        dataSource: 'ads_google_impressions',
        chartType: ChartType.bar,
        x: 2,
        y: 37,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_google_clicks',
        title: 'Google - Click',
        dataSource: 'ads_google_clicks',
        chartType: ChartType.line,
        x: 0,
        y: 39,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_google_ctr',
        title: 'Google - CTR',
        dataSource: 'ads_google_ctr',
        chartType: ChartType.line,
        x: 2,
        y: 39,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_google_cpc',
        title: 'Google - CPC',
        dataSource: 'ads_google_cpc',
        chartType: ChartType.line,
        x: 0,
        y: 41,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_google_cost',
        title: 'Google - Costo',
        dataSource: 'ads_google_cost',
        chartType: ChartType.pie,
        x: 2,
        y: 41,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_google_conversions',
        title: 'Google - Conversioni',
        dataSource: 'ads_google_conversions',
        chartType: ChartType.bar,
        x: 0,
        y: 43,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_google_conversion_value',
        title: 'Google - Valore Conversioni',
        dataSource: 'ads_google_conversion_value',
        chartType: ChartType.bar,
        x: 2,
        y: 43,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_google_keywords',
        title: 'Google - Performance Keyword',
        dataSource: 'ads_google_keywords',
        chartType: ChartType.bar,
        x: 0,
        y: 45,
        width: 4,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_google_quality_score',
        title: 'Google - Quality Score',
        dataSource: 'ads_google_quality_score',
        chartType: ChartType.bar,
        x: 0,
        y: 47,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_google_roas',
        title: 'Google - ROAS',
        dataSource: 'ads_google_roas',
        chartType: ChartType.bar,
        x: 2,
        y: 47,
        width: 2,
        height: 2,
        visible: false,
      ),

      // ============ SEZIONE: TIKTOK ADS ============
      DashboardWidgetConfig(
        id: 'ads_tiktok_campaigns',
        title: 'TikTok - Campagne Attive',
        dataSource: 'ads_tiktok_campaigns',
        chartType: ChartType.bar,
        x: 0,
        y: 49,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_tiktok_impressions',
        title: 'TikTok - Impressioni',
        dataSource: 'ads_tiktok_impressions',
        chartType: ChartType.bar,
        x: 2,
        y: 49,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_tiktok_clicks',
        title: 'TikTok - Click',
        dataSource: 'ads_tiktok_clicks',
        chartType: ChartType.line,
        x: 0,
        y: 51,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_tiktok_video_views',
        title: 'TikTok - Visualizzazioni Video',
        dataSource: 'ads_tiktok_video_views',
        chartType: ChartType.bar,
        x: 2,
        y: 51,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_tiktok_engagement',
        title: 'TikTok - Engagement',
        dataSource: 'ads_tiktok_engagement',
        chartType: ChartType.line,
        x: 0,
        y: 53,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_tiktok_engagement_rate',
        title: 'TikTok - Tasso Engagement',
        dataSource: 'ads_tiktok_engagement_rate',
        chartType: ChartType.line,
        x: 2,
        y: 53,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_tiktok_spend',
        title: 'TikTok - Spesa',
        dataSource: 'ads_tiktok_spend',
        chartType: ChartType.pie,
        x: 0,
        y: 55,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_tiktok_conversions',
        title: 'TikTok - Conversioni',
        dataSource: 'ads_tiktok_conversions',
        chartType: ChartType.bar,
        x: 2,
        y: 55,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_tiktok_cpm',
        title: 'TikTok - CPM',
        dataSource: 'ads_tiktok_cpm',
        chartType: ChartType.line,
        x: 0,
        y: 57,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_tiktok_cpc',
        title: 'TikTok - CPC',
        dataSource: 'ads_tiktok_cpc',
        chartType: ChartType.line,
        x: 2,
        y: 57,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_tiktok_audience',
        title: 'TikTok - Demografia Audience',
        dataSource: 'ads_tiktok_audience',
        chartType: ChartType.pie,
        x: 0,
        y: 59,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_tiktok_creative',
        title: 'TikTok - Performance Creative',
        dataSource: 'ads_tiktok_creative',
        chartType: ChartType.bar,
        x: 2,
        y: 59,
        width: 2,
        height: 2,
        visible: false,
      ),

      // ============ SEZIONE: CROSS-PLATFORM & AGGREGATE ============
      DashboardWidgetConfig(
        id: 'ads_total_spend',
        title: 'Totale - Spesa per Piattaforma',
        dataSource: 'ads_total_spend',
        chartType: ChartType.pie,
        x: 0,
        y: 61,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_total_impressions',
        title: 'Totale - Impressioni',
        dataSource: 'ads_total_impressions',
        chartType: ChartType.bar,
        x: 2,
        y: 61,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_total_clicks',
        title: 'Totale - Click',
        dataSource: 'ads_total_clicks',
        chartType: ChartType.bar,
        x: 0,
        y: 63,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_total_conversions',
        title: 'Totale - Conversioni',
        dataSource: 'ads_total_conversions',
        chartType: ChartType.bar,
        x: 2,
        y: 63,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_roi',
        title: 'Totale - ROI',
        dataSource: 'ads_roi',
        chartType: ChartType.bar,
        x: 0,
        y: 65,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_roas_comparison',
        title: 'Totale - ROAS Comparativo',
        dataSource: 'ads_roas_comparison',
        chartType: ChartType.bar,
        x: 2,
        y: 65,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_budget_allocation',
        title: 'Totale - Allocazione Budget',
        dataSource: 'ads_budget_allocation',
        chartType: ChartType.pie,
        x: 0,
        y: 67,
        width: 4,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_platform_performance',
        title: 'Totale - Performance Piattaforme',
        dataSource: 'ads_platform_performance',
        chartType: ChartType.bar,
        x: 0,
        y: 69,
        width: 4,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_ctr_comparison',
        title: 'Totale - CTR Comparativo',
        dataSource: 'ads_ctr_comparison',
        chartType: ChartType.bar,
        x: 0,
        y: 71,
        width: 2,
        height: 2,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'ads_cpc_comparison',
        title: 'Totale - CPC Comparativo',
        dataSource: 'ads_cpc_comparison',
        chartType: ChartType.bar,
        x: 2,
        y: 71,
        width: 2,
        height: 2,
        visible: false,
      ),

      // ============ WIDGET SPECIALI: SECTION DIVIDERS ============
      // Widget separatori per organizzare la dashboard in sezioni
      DashboardWidgetConfig(
        id: 'section_woocommerce',
        title: '═══ WOOCOMMERCE ═══',
        dataSource: 'section_divider',
        chartType: ChartType.bar,
        x: 0,
        y: 0,
        width: 4,
        height: 1,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'section_meta',
        title: '═══ META ADS ═══',
        dataSource: 'section_divider',
        chartType: ChartType.bar,
        x: 0,
        y: 10,
        width: 4,
        height: 1,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'section_instagram',
        title: '═══ INSTAGRAM ═══',
        dataSource: 'section_divider',
        chartType: ChartType.bar,
        x: 0,
        y: 24,
        width: 4,
        height: 1,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'section_google',
        title: '═══ GOOGLE ADS ═══',
        dataSource: 'section_divider',
        chartType: ChartType.bar,
        x: 0,
        y: 34,
        width: 4,
        height: 1,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'section_tiktok',
        title: '═══ TIKTOK ADS ═══',
        dataSource: 'section_divider',
        chartType: ChartType.bar,
        x: 0,
        y: 48,
        width: 4,
        height: 1,
        visible: false,
      ),
      DashboardWidgetConfig(
        id: 'section_aggregate',
        title: '═══ TOTALI & COMPARATIVI ═══',
        dataSource: 'section_divider',
        chartType: ChartType.bar,
        x: 0,
        y: 60,
        width: 4,
        height: 1,
        visible: false,
      ),
    ];
  }

  /// Salva la configurazione della dashboard
  static Future<void> saveLayout(List<DashboardWidgetConfig> widgets) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = widgets.map((w) => w.toJson()).toList();
    await prefs.setString(_prefsKey, jsonEncode(jsonList));
  }

  /// Carica la configurazione della dashboard
  static Future<List<DashboardWidgetConfig>> loadLayout() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_prefsKey);

    if (jsonString == null) {
      return getDefaultWidgets();
    }

    try {
      final jsonList = jsonDecode(jsonString) as List;
      final savedWidgets = jsonList
          .map((json) => DashboardWidgetConfig.fromJson(json))
          .toList();

      // Merge con i widget di default per aggiungere eventuali nuovi widget
      final defaultWidgets = getDefaultWidgets();
      final savedIds = savedWidgets.map((w) => w.id).toSet();

      // Aggiungi widget di default che non sono presenti nei salvati
      for (var defaultWidget in defaultWidgets) {
        if (!savedIds.contains(defaultWidget.id)) {
          savedWidgets.add(defaultWidget);
        }
      }

      return savedWidgets;
    } catch (e) {
      return getDefaultWidgets();
    }
  }

  /// Resetta al layout di default
  static Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}

// =======================================================
// ==          PAGINA DASHBOARD PERSONALIZZABILE        ==
// =======================================================

/// Configurazione account ads per supporto multi-utente
class AdsAccountConfig {
  final String id;
  final String name;
  final String platform; // 'meta', 'google', 'tiktok', 'instagram'
  final String accountId;
  final bool isActive;

  AdsAccountConfig({
    required this.id,
    required this.name,
    required this.platform,
    required this.accountId,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'platform': platform,
    'accountId': accountId,
    'isActive': isActive,
  };

  factory AdsAccountConfig.fromJson(Map<String, dynamic> json) =>
      AdsAccountConfig(
        id: json['id'],
        name: json['name'],
        platform: json['platform'],
        accountId: json['accountId'],
        isActive: json['isActive'] ?? true,
      );
}

/// Dashboard con widget personalizzabili in griglia drag & drop
class CustomizableDashboardPage extends StatefulWidget {
  const CustomizableDashboardPage({super.key});

  @override
  State<CustomizableDashboardPage> createState() =>
      _CustomizableDashboardPageState();
}

/// Enum per i periodi di filtro
enum PeriodoFiltro { oggi, settimana, mese, anno, personalizzato }

class _CustomizableDashboardPageState extends State<CustomizableDashboardPage> {
  final ReportService _reportService = ReportService();
  final AdsPlatformService _adsService = AdsPlatformService();
  final AdsCommentManager _commentManager = AdsCommentManager();

  List<DashboardWidgetConfig> _widgets = [];
  DashboardData? _dashboardData;
  ReportVenditeDettagliato? _reportVendite;
  AdsPlatformData? _adsData;

  bool _isLoading = true;
  bool _isEditMode = false;
  String? _errorMessage;

  // Filtro data
  PeriodoFiltro _periodoSelezionato = PeriodoFiltro.mese;
  DateTimeRange? _rangePersonalizzato;

  // Multi-account support per ads platforms
  String? _selectedMetaAccountId;
  String? _selectedGoogleCustomerId;
  String? _selectedTikTokAdvertiserId;
  String? _selectedInstagramUserId;

  // Lista account configurati (caricati dalle impostazioni)
  List<AdsAccountConfig> _adsAccounts = [];

  late DashboardGrid _gridConfig;

  // Verifica se l'utente è autenticato
  bool get _isAuthenticated => loginCode.isConnected;

  @override
  void initState() {
    super.initState();
    _gridConfig = DashboardGrid(maxColumns: 4);
    _loadDashboard();
    // Inizializza sempre il servizio ads (carica i dati solo se autenticato)
    _initializeAdsService();
    // Inizializza il comment manager
    _commentManager.initialize();
  }

  @override
  void dispose() {
    _adsService.dispose();
    super.dispose();
  }

  Future<void> _initializeAdsService() async {
    try {
      await _adsService.initialize();
      if (_adsService.isConnected("meta") ||
          _adsService.isConnected("google") ||
          _adsService.isConnected("tiktok")) {
        await _loadAdsData();
      }
    } catch (e) {
      // Ignora errori ads, non sono critici
    }
  }

  Future<void> _loadAdsData() async {
    if (!_isAuthenticated) return;

    try {
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
      // Ignora errori ads
    }
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Carica sempre il layout
      _widgets = await DashboardLayoutManager.loadLayout();

      // Riorganizza i widget per eliminare spazi vuoti
      _reorganizeWidgets();

      // Salva il layout riorganizzato
      await _saveLayout();

      // Carica i dati solo se autenticato
      if (_isAuthenticated) {
        final results = await Future.wait([
          _reportService.getDashboard(),
          _reportService.getReportVendite(),
        ]);

        if (mounted) {
          _dashboardData = results[0] as DashboardData;
          _reportVendite = results[1] as ReportVenditeDettagliato;
        }
      }

      // Configura la griglia con i widget
      if (mounted) {
        _updateGridConfig();
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _updateGridConfig() {
    // Ricrea la griglia con i widget aggiornati
    _gridConfig = DashboardGrid(
      maxColumns: 4,
      listener: (changes) {
        // Aggiorna le posizioni dei widget quando vengono spostati
        for (final change in changes) {
          if (change.to != null) {
            final config = _widgets.firstWhere(
              (w) => w.id == change.to!.id,
              orElse: () => _widgets.first,
            );
            // Valida che le coordinate siano >= 0
            config.x = change.to!.x < 0 ? 0 : change.to!.x;
            config.y = change.to!.y < 0 ? 0 : change.to!.y;
          }
        }
        _saveLayout();
      },
    );

    // Aggiungi tutti i widget alla griglia
    for (final config in _widgets) {
      // Valida coordinate prima di aggiungere
      final validX = config.x < 0 ? 0 : config.x;
      final validY = config.y < 0 ? 0 : config.y;

      _gridConfig.addWidget(
        DashboardWidget(
          id: config.id,
          x: validX,
          y: validY,
          width: config.width,
          height: config.height,
          builder: (context) => _buildWidgetCard(config),
        ),
      );
    }
  }

  Future<void> _saveLayout() async {
    await DashboardLayoutManager.saveLayout(_widgets);
  }

  /// Riorganizza i widget eliminando gli spazi vuoti
  void _reorganizeWidgets() {
    if (_widgets.isEmpty) return;

    // Ordina i widget per posizione (prima per y, poi per x)
    _widgets.sort((a, b) {
      if (a.y != b.y) return a.y.compareTo(b.y);
      return a.x.compareTo(b.x);
    });

    // Crea una mappa delle celle occupate
    final int maxColumns = 4;
    final Map<int, List<bool>> grid = {};

    // Funzione per verificare se una posizione è libera
    bool isPositionFree(int x, int y, int width, int height) {
      for (int dy = 0; dy < height; dy++) {
        final row = grid[y + dy] ?? List.filled(maxColumns, false);
        for (int dx = 0; dx < width; dx++) {
          if (x + dx >= maxColumns || row[x + dx]) {
            return false;
          }
        }
      }
      return true;
    }

    // Funzione per occupare una posizione
    void occupyPosition(int x, int y, int width, int height) {
      for (int dy = 0; dy < height; dy++) {
        final row = grid.putIfAbsent(
          y + dy,
          () => List.filled(maxColumns, false),
        );
        for (int dx = 0; dx < width; dx++) {
          if (x + dx < maxColumns) {
            row[x + dx] = true;
          }
        }
      }
    }

    // Riposiziona ogni widget nella prima posizione disponibile
    for (final widget in _widgets) {
      bool positioned = false;

      // Cerca dalla riga 0 in poi
      for (int y = 0; y < 100 && !positioned; y++) {
        for (int x = 0; x < maxColumns && !positioned; x++) {
          if (x + widget.width <= maxColumns &&
              isPositionFree(x, y, widget.width, widget.height)) {
            widget.x = x;
            widget.y = y;
            occupyPosition(x, y, widget.width, widget.height);
            positioned = true;
          }
        }
      }
    }
  }

  Future<void> _resetLayout() async {
    await DashboardLayoutManager.resetToDefault();
    _widgets = DashboardLayoutManager.getDefaultWidgets();
    _updateGridConfig();
    setState(() {});
    if (mounted) {
      NotificationService.instance.messageBar(
        'info',
        'dashboard_customization',
        'Layout ripristinato',
      );
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
    if (!_isEditMode) {
      _saveLayout();
    }
  }

  DateTimeRange _getDateRangeForPeriodo() {
    final now = DateTime.now();
    switch (_periodoSelezionato) {
      case PeriodoFiltro.oggi:
        return DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: now,
        );
      case PeriodoFiltro.settimana:
        return DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );
      case PeriodoFiltro.mese:
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
      case PeriodoFiltro.anno:
        return DateTimeRange(start: DateTime(now.year, 1, 1), end: now);
      case PeriodoFiltro.personalizzato:
        return _rangePersonalizzato ??
            DateTimeRange(
              start: now.subtract(const Duration(days: 30)),
              end: now,
            );
    }
  }

  String _getPeriodoLabel(PeriodoFiltro periodo) {
    switch (periodo) {
      case PeriodoFiltro.oggi:
        return 'Oggi';
      case PeriodoFiltro.settimana:
        return 'Settimana';
      case PeriodoFiltro.mese:
        return 'Mese';
      case PeriodoFiltro.anno:
        return 'Anno';
      case PeriodoFiltro.personalizzato:
        return 'Personalizzato';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Barra filtro data
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.filter_list,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text('Periodo:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                ...PeriodoFiltro.values.map((periodo) {
                  final isSelected = periodo == _periodoSelezionato;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_getPeriodoLabel(periodo)),
                      selected: isSelected,
                      onSelected: (selected) async {
                        if (selected) {
                          if (periodo == PeriodoFiltro.personalizzato) {
                            final range = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              initialDateRange: _rangePersonalizzato,
                            );
                            if (range != null) {
                              setState(() {
                                _periodoSelezionato = periodo;
                                _rangePersonalizzato = range;
                              });
                              _loadDashboard();
                            }
                          } else {
                            setState(() => _periodoSelezionato = periodo);
                            _loadDashboard();
                          }
                        }
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          // Dashboard content
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsante modifica
          FloatingActionButton.small(
            heroTag: 'edit',
            backgroundColor: _isEditMode
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.primary,
            foregroundColor: _isEditMode
                ? Theme.of(context).colorScheme.onSecondary
                : Theme.of(context).colorScheme.onPrimary,
            onPressed: _toggleEditMode,
            child: Icon(_isEditMode ? Icons.check : Icons.edit),
          ),
          const SizedBox(height: 8),
          // Pulsante refresh
          FloatingActionButton.small(
            heroTag: 'refresh',
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            onPressed: _loadDashboard,
            child: const Icon(Icons.refresh),
          ),
          const SizedBox(height: 8),
          // Menu opzioni
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'reset':
                  _showResetConfirmDialog();
                  break;
                case 'manage':
                  _showWidgetManagerDialog();
                  break;
              }
            },
            child: FloatingActionButton.small(
              heroTag: 'menu',
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              onPressed: null,
              child: const Icon(Icons.more_vert),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'manage',
                child: ListTile(
                  leading: Icon(Icons.widgets),
                  title: Text('Gestisci Widget'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: ListTile(
                  leading: Icon(Icons.restore),
                  title: Text('Ripristina Default'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    // La dashboard è sempre accessibile, ogni widget controlla la propria autenticazione
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Caricamento dashboard...',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text('Errore: $_errorMessage'),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcola le dimensioni in base allo spazio disponibile
        final sidebarWidth = _isEditMode ? 250.0 : 0.0;

        // Spazio disponibile meno sidebar
        final availableWidth = constraints.maxWidth - sidebarWidth;
        final availableHeight = constraints.maxHeight;

        // Il pacchetto dashboard_grid aggiunge automaticamente spacing
        // Calcolo semplice: dividi lo spazio per 4 celle
        // e lascia che il pacchetto gestisca lo spacing internamente
        final widgetWidth = availableWidth / 4 - 12; // 12px per spacing medio
        final widgetHeight = availableHeight / 4 - 12;

        return Row(
          children: [
            // Dashboard principale
            Expanded(
              child: ClipRect(
                child: Dashboard(
                  config: _gridConfig,
                  editMode: _isEditMode,
                  widgetWidth: widgetWidth,
                  widgetHeight: widgetHeight,
                  widgetSpacing: 8,
                  cellPreviewDecoration: TableCellDecoration(
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
            // Barra laterale widget disponibili (solo in edit mode)
            if (_isEditMode)
              Container(
                width: 250,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border(
                    left: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Widget Disponibili',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).textTheme.titleMedium?.color,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                          8,
                          8,
                          8,
                          80,
                        ), // Extra padding in basso per i FAB
                        child: Column(
                          children: [
                            // Sezione WooCommerce
                            _buildSectionHeader(
                              'WooCommerce',
                              Icons.shopping_cart,
                              Colors.purple,
                            ),
                            ..._getWooCommerceWidgets().map(
                              (widget) => _buildWidgetListTile(widget),
                            ),
                            const SizedBox(height: 16),

                            // Sezione Meta Ads / Facebook
                            _buildSectionHeader(
                              'Meta / Facebook',
                              Icons.facebook,
                              Colors.blue,
                            ),
                            ..._getMetaAdsWidgets().map(
                              (widget) => _buildWidgetListTile(widget),
                            ),
                            const SizedBox(height: 12),

                            // Sezione Instagram
                            _buildSectionHeader(
                              'Instagram',
                              Icons.camera_alt,
                              Colors.pink,
                            ),
                            ..._getInstagramWidgets().map(
                              (widget) => _buildWidgetListTile(widget),
                            ),
                            const SizedBox(height: 12),

                            // Sezione Google Ads
                            _buildSectionHeader(
                              'Google Ads',
                              Icons.g_mobiledata,
                              Colors.green,
                            ),
                            ..._getGoogleAdsWidgets().map(
                              (widget) => _buildWidgetListTile(widget),
                            ),
                            const SizedBox(height: 12),

                            // Sezione TikTok Ads
                            _buildSectionHeader(
                              'TikTok Ads',
                              Icons.music_note,
                              Colors.black,
                            ),
                            ..._getTikTokAdsWidgets().map(
                              (widget) => _buildWidgetListTile(widget),
                            ),
                            const SizedBox(height: 12),

                            // Sezione Totali & Comparativi
                            _buildSectionHeader(
                              'Totali & Comparativi',
                              Icons.analytics,
                              Colors.orange,
                            ),
                            ..._getTotaliAdsWidgets().map(
                              (widget) => _buildWidgetListTile(widget),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildWidgetCard(DashboardWidgetConfig config) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: _isEditMode
            ? Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.5),
                width: 2,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con titolo e pulsante settings
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    config.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    size: 18,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  onPressed: () => _showWidgetSettingsDialog(config),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ),
          // Chart
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: _buildChart(config),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(DashboardWidgetConfig config) {
    // Ogni widget controlla la propria autenticazione specifica
    switch (config.id) {
      case 'vendite_trend':
        return _buildVenditeChart(config);
      case 'top_prodotti':
        return _buildTopProdottiChart(config);
      case 'ordini_stato':
        return _buildOrdiniStatoChart(config);
      case 'ordini_tempo':
        return _buildOrdiniTempoChart(config);
      case 'totale_ordini':
        return _buildTotaleOrdiniWidget();
      case 'coupon_usati':
        return _buildCouponWidget(config);
      case 'prodotti_esauriti':
        return _buildProdottiEsauritiWidget(config);
      case 'clienti_top':
        return _buildClientiTopWidget(config);
      case 'fatturato_totale':
        return _buildFatturatoWidget(config);
      case 'media_ordine':
        return _buildMediaOrdineWidget(config);
      // Widget Ads
      case 'ads_meta_campaigns':
        return _buildAdsMetaCampaignsWidget(config);
      case 'ads_meta_insights':
        return _buildAdsMetaInsightsWidget(config);
      case 'ads_meta_spend':
        return _buildAdsMetaSpendWidget(config);
      case 'ads_instagram_media':
        return _buildAdsInstagramMediaWidget(config);
      case 'ads_instagram_engagement':
        return _buildAdsInstagramEngagementWidget(config);
      case 'ads_google_campaigns':
        return _buildAdsGoogleCampaignsWidget(config);
      case 'ads_google_performance':
        return _buildAdsGooglePerformanceWidget(config);
      case 'ads_tiktok_campaigns':
        return _buildAdsTikTokCampaignsWidget(config);
      case 'ads_tiktok_reports':
        return _buildAdsTikTokReportsWidget(config);
      case 'ads_tiktok_spend':
        return _buildAdsTikTokSpendWidget(config);
      case 'ads_aggregate':
        return _buildAdsAggregateWidget(config);
      case 'ads_total_spend':
        return _buildAdsTotalSpendWidget(config);
      case 'ads_roi':
        return _buildAdsROIWidget(config);

      // Section dividers
      case 'section_woocommerce':
      case 'section_meta':
      case 'section_instagram':
      case 'section_google':
      case 'section_tiktok':
      case 'section_aggregate':
        return _buildSectionDivider(config);

      default:
        return Center(
          child: Text(
            'Widget non supportato',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        );
    }
  }

  /// Widget separatore di sezione
  Widget _buildSectionDivider(DashboardWidgetConfig config) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Theme.of(context).primaryColor.withValues(alpha: 0.5),
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            config.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Theme.of(context).primaryColor.withValues(alpha: 0.5),
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVenditeChart(DashboardWidgetConfig config) {
    // Verifica autenticazione WooCommerce
    if (!_isAuthenticated || _dashboardData == null) {
      return _buildWidgetLoginRequired();
    }

    final vendite = _dashboardData!.vendite.andamentoGiornaliero;
    if (vendite.isEmpty) {
      return Center(
        child: Text(
          'Nessun dato vendite',
          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
        ),
      );
    }

    switch (config.chartType) {
      case ChartType.line:
        return SalesLineChart(
          vendite: vendite,
          lineColor: Color(ReportColors.primary),
        );
      case ChartType.bar:
        return OrdersBarChart(vendite: vendite);
      case ChartType.area:
        return SalesLineChart(
          vendite: vendite,
          lineColor: Color(ReportColors.primary),
          showArea: true,
        );
      default:
        return SalesLineChart(
          vendite: vendite,
          lineColor: Color(ReportColors.primary),
        );
    }
  }

  Widget _buildTopProdottiChart(DashboardWidgetConfig config) {
    // Verifica autenticazione WooCommerce
    if (!_isAuthenticated || _reportVendite == null) {
      return _buildWidgetLoginRequired();
    }

    final topProdotti = _reportVendite!.topProdotti;
    if (topProdotti.isEmpty) {
      return Center(
        child: Text(
          'Nessun dato prodotti',
          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
        ),
      );
    }

    switch (config.chartType) {
      case ChartType.bar:
        return TopProductsBarChart(topProducts: topProdotti);
      case ChartType.pie:
        // Converti in formato pie chart
        final Map<String, int> prodottiMap = {};
        for (var p in topProdotti.take(5)) {
          prodottiMap[p.titolo] = p.quantitaVenduta;
        }
        return OrderStatusPieChart(ordersByStatus: prodottiMap);
      default:
        return TopProductsBarChart(topProducts: topProdotti);
    }
  }

  Widget _buildOrdiniStatoChart(DashboardWidgetConfig config) {
    // Verifica autenticazione WooCommerce
    if (!_isAuthenticated || _dashboardData == null) {
      return _buildWidgetLoginRequired();
    }

    final ordiniPerStato = _dashboardData!.ordini.ordiniPerStato;
    if (ordiniPerStato.isEmpty) {
      return Center(
        child: Text(
          'Nessun dato ordini',
          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
        ),
      );
    }

    switch (config.chartType) {
      case ChartType.pie:
        return OrderStatusPieChart(ordersByStatus: ordiniPerStato);
      case ChartType.bar:
        // Converti in top prodotti format per usare bar chart
        final topProdotti = ordiniPerStato.entries.map((e) {
          return TopProdotto(
            productId: 0,
            titolo: _getStatusLabel(e.key),
            quantitaVenduta: e.value,
            totaleVendite: e.value.toDouble(),
          );
        }).toList();
        return TopProductsBarChart(topProducts: topProdotti);
      default:
        return OrderStatusPieChart(ordersByStatus: ordiniPerStato);
    }
  }

  Widget _buildOrdiniTempoChart(DashboardWidgetConfig config) {
    // Verifica autenticazione WooCommerce
    if (!_isAuthenticated || _dashboardData == null) {
      return _buildWidgetLoginRequired();
    }

    final vendite = _dashboardData!.vendite.andamentoGiornaliero;
    if (vendite.isEmpty) {
      return Center(
        child: Text(
          'Nessun dato ordini',
          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
        ),
      );
    }

    switch (config.chartType) {
      case ChartType.bar:
        return OrdersBarChart(vendite: vendite);
      case ChartType.line:
        return SalesLineChart(
          vendite: vendite,
          lineColor: Color(ReportColors.info),
          showOrders: true,
        );
      default:
        return OrdersBarChart(vendite: vendite);
    }
  }

  Widget _buildTotaleOrdiniWidget() {
    // Verifica autenticazione WooCommerce
    if (!_isAuthenticated || _dashboardData == null) {
      return _buildWidgetLoginRequired();
    }

    final totaleOrdini = _dashboardData!.ordini.ordiniPerStato.values.fold(
      0,
      (sum, val) => sum + val,
    );
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$totaleOrdini',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Text(
            'Ordini Totali',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponWidget(DashboardWidgetConfig config) {
    // Verifica autenticazione WooCommerce
    if (!_isAuthenticated || _dashboardData == null) {
      return _buildWidgetLoginRequired();
    }

    // Placeholder - da implementare con dati reali coupon
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_offer,
            size: 48,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(height: 8),
          Text(
            'Coupon',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProdottiEsauritiWidget(DashboardWidgetConfig config) {
    // Verifica autenticazione WooCommerce
    if (!_isAuthenticated || _dashboardData == null) {
      return _buildWidgetLoginRequired();
    }

    // Placeholder - da implementare con dati reali prodotti esauriti
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 8),
          Text(
            'Prodotti Esauriti',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientiTopWidget(DashboardWidgetConfig config) {
    // Verifica autenticazione WooCommerce
    if (!_isAuthenticated || _dashboardData == null) {
      return _buildWidgetLoginRequired();
    }

    // Placeholder - da implementare con dati reali clienti
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            'Migliori Clienti',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFatturatoWidget(DashboardWidgetConfig config) {
    // Verifica autenticazione WooCommerce
    if (!_isAuthenticated || _dashboardData == null) {
      return _buildWidgetLoginRequired();
    }

    final fatturato = _dashboardData!.vendite.totaleVendite;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${fatturato.toStringAsFixed(2)} EUR',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Text(
            'Fatturato Totale',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaOrdineWidget(DashboardWidgetConfig config) {
    // Verifica autenticazione WooCommerce
    if (!_isAuthenticated || _dashboardData == null) {
      return _buildWidgetLoginRequired();
    }

    final totaleOrdini = _dashboardData!.ordini.ordiniPerStato.values.fold(
      0,
      (sum, val) => sum + val,
    );
    final media = totaleOrdini > 0
        ? _dashboardData!.vendite.totaleVendite / totaleOrdini
        : 0.0;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${media.toStringAsFixed(2)} EUR',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          Text(
            'Media per Ordine',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(String status) {
    const labels = {
      'pending': 'In Attesa',
      'processing': 'In Elaborazione',
      'completed': 'Completati',
      'on-hold': 'In Sospeso',
      'cancelled': 'Annullati',
      'refunded': 'Rimborsati',
      'failed': 'Falliti',
    };
    return labels[status] ?? status;
  }

  /// Restituisce la lista di tutti i widget disponibili
  List<DashboardWidgetConfig> _getAvailableWidgets() {
    return _widgets;
  }

  /// Restituisce i widget WooCommerce
  List<DashboardWidgetConfig> _getWooCommerceWidgets() {
    return _widgets
        .where((w) => !w.id.startsWith('ads_') && !w.id.startsWith('section_'))
        .toList();
  }

  /// Restituisce i widget Meta Ads
  List<DashboardWidgetConfig> _getMetaAdsWidgets() {
    return _widgets.where((w) => w.id.startsWith('ads_meta_')).toList();
  }

  /// Restituisce i widget Instagram
  List<DashboardWidgetConfig> _getInstagramWidgets() {
    return _widgets.where((w) => w.id.startsWith('ads_instagram_')).toList();
  }

  /// Restituisce i widget Google Ads
  List<DashboardWidgetConfig> _getGoogleAdsWidgets() {
    return _widgets.where((w) => w.id.startsWith('ads_google_')).toList();
  }

  /// Restituisce i widget TikTok Ads
  List<DashboardWidgetConfig> _getTikTokAdsWidgets() {
    return _widgets.where((w) => w.id.startsWith('ads_tiktok_')).toList();
  }

  /// Restituisce i widget Totali/Cross-platform
  List<DashboardWidgetConfig> _getTotaliAdsWidgets() {
    return _widgets
        .where(
          (w) =>
              w.id.startsWith('ads_total_') ||
              w.id.startsWith('ads_roi') ||
              w.id.startsWith('ads_roas_') ||
              w.id.startsWith('ads_budget_') ||
              w.id.startsWith('ads_platform_') ||
              w.id.startsWith('ads_ctr_') ||
              w.id.startsWith('ads_cpc_'),
        )
        .toList();
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.1)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWidgetListTile(DashboardWidgetConfig widget) {
    final isVisible = _widgets.firstWhere((w) => w.id == widget.id).visible;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        leading: Icon(
          widget.chartTypeIcon,
          size: 20,
          color: isVisible
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).disabledColor,
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            fontSize: 12,
            color: isVisible ? null : Theme.of(context).disabledColor,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            size: 18,
          ),
          onPressed: () {
            setState(() {
              final config = _widgets.firstWhere((w) => w.id == widget.id);
              config.visible = !config.visible;
            });
            _updateGridConfig();
          },
        ),
        onTap: () {
          if (!isVisible) {
            setState(() {
              final config = _widgets.firstWhere((w) => w.id == widget.id);
              config.visible = true;
            });
            _updateGridConfig();
          }
        },
      ),
    );
  }

  // =======================================================
  // ==           WIDGET ADS PLATFORM - META              ==
  // =======================================================

  Widget _buildAdsMetaCampaignsWidget(DashboardWidgetConfig config) {
    if (!_isAuthenticated) return _buildWidgetLoginRequired();
    if (!_adsService.isConnected("meta"))
      return _buildAdsNotConnected('Meta', Icons.facebook, Colors.blue);

    final campaigns = _adsData?.metaCampaigns?['data'];
    if (campaigns == null || campaigns.isEmpty) {
      return _buildNoData('Meta Campagne');
    }

    return _wrapAdsWidgetWithComment(
      adId: 'meta_campaigns',
      platform: 'meta',
      title: config.title,
      child: _buildStatsWidget(
        icon: Icons.facebook,
        color: Colors.blue,
        value: '${campaigns.length}',
        label: 'Campagne Attive',
      ),
    );
  }

  Widget _buildAdsMetaInsightsWidget(DashboardWidgetConfig config) {
    if (!_isAuthenticated) return _buildWidgetLoginRequired();
    if (!_adsService.isConnected("meta"))
      return _buildAdsNotConnected('Meta', Icons.facebook, Colors.blue);

    final insights = _adsData?.metaInsights?['data'];
    if (insights == null || insights.isEmpty) {
      return _buildNoData('Meta Insights');
    }

    return _wrapAdsWidgetWithComment(
      adId: 'meta_insights',
      platform: 'meta',
      title: config.title,
      child: _buildStatsWidget(
        icon: Icons.insights,
        color: Colors.blue,
        value: '${insights.length}',
        label: 'Insights Disponibili',
      ),
    );
  }

  Widget _buildAdsMetaSpendWidget(DashboardWidgetConfig config) {
    if (!_isAuthenticated) return _buildWidgetLoginRequired();
    if (!_adsService.isConnected("meta"))
      return _buildAdsNotConnected('Meta', Icons.facebook, Colors.blue);

    final insights = _adsData?.metaInsights?['data'];
    if (insights == null || insights.isEmpty) {
      return _buildNoData('Meta Spesa');
    }

    double totalSpend = 0.0;
    for (var insight in insights) {
      totalSpend += double.tryParse(insight['spend']?.toString() ?? '0') ?? 0.0;
    }

    return _wrapAdsWidgetWithComment(
      adId: 'meta_spend',
      platform: 'meta',
      title: config.title,
      child: _buildStatsWidget(
        icon: Icons.euro,
        color: Colors.red,
        value: '€${totalSpend.toStringAsFixed(2)}',
        label: 'Spesa Totale',
      ),
    );
  }

  // =======================================================
  // ==           WIDGET ADS PLATFORM - INSTAGRAM         ==
  // =======================================================

  Widget _buildAdsInstagramMediaWidget(DashboardWidgetConfig config) {
    if (!_isAuthenticated) return _buildWidgetLoginRequired();
    if (!_adsService.isConnected("meta"))
      return _buildAdsNotConnected(
        'Instagram',
        Icons.photo_library,
        Colors.purple,
      );

    final media = _adsData?.instagramMedia?['data'];
    if (media == null || media.isEmpty) {
      return _buildNoData('Instagram Media');
    }

    return _wrapAdsWidgetWithComment(
      adId: 'instagram_media',
      platform: 'instagram',
      title: config.title,
      child: _buildStatsWidget(
        icon: Icons.photo_library,
        color: Colors.purple,
        value: '${media.length}',
        label: 'Media Pubblicati',
      ),
    );
  }

  Widget _buildAdsInstagramEngagementWidget(DashboardWidgetConfig config) {
    if (!_isAuthenticated) return _buildWidgetLoginRequired();
    if (!_adsService.isConnected("meta"))
      return _buildAdsNotConnected(
        'Instagram',
        Icons.photo_library,
        Colors.purple,
      );

    final media = _adsData?.instagramMedia?['data'];
    if (media == null || media.isEmpty) {
      return _buildNoData('Instagram Engagement');
    }

    int totalEngagement = 0;
    for (var m in media) {
      totalEngagement +=
          ((m['like_count'] ?? 0) as num).toInt() +
          ((m['comments_count'] ?? 0) as num).toInt();
    }

    return _wrapAdsWidgetWithComment(
      adId: 'instagram_engagement',
      platform: 'instagram',
      title: config.title,
      child: _buildStatsWidget(
        icon: Icons.favorite,
        color: Colors.pink,
        value: '$totalEngagement',
        label: 'Engagement Totale',
      ),
    );
  }

  // =======================================================
  // ==           WIDGET ADS PLATFORM - GOOGLE            ==
  // =======================================================

  Widget _buildAdsGoogleCampaignsWidget(DashboardWidgetConfig config) {
    if (!_isAuthenticated) return _buildWidgetLoginRequired();
    if (!_adsService.isConnected("google"))
      return _buildAdsNotConnected('Google', Icons.g_mobiledata, Colors.red);

    final campaigns = _adsData?.googleCampaigns;
    if (campaigns == null) {
      return _buildNoData('Google Campagne');
    }

    return _wrapAdsWidgetWithComment(
      adId: 'google_campaigns',
      platform: 'google',
      title: config.title,
      child: _buildStatsWidget(
        icon: Icons.g_mobiledata,
        color: Colors.red,
        value: 'Attivo',
        label: 'Google Ads',
      ),
    );
  }

  Widget _buildAdsGooglePerformanceWidget(DashboardWidgetConfig config) {
    if (!_isAuthenticated) return _buildWidgetLoginRequired();
    if (!_adsService.isConnected("google"))
      return _buildAdsNotConnected('Google', Icons.g_mobiledata, Colors.red);

    return _wrapAdsWidgetWithComment(
      adId: 'google_performance',
      platform: 'google',
      title: config.title,
      child: _buildStatsWidget(
        icon: Icons.analytics,
        color: Colors.orange,
        value: 'N/A',
        label: 'Performance Google',
      ),
    );
  }

  // =======================================================
  // ==           WIDGET ADS PLATFORM - TIKTOK            ==
  // =======================================================

  Widget _buildAdsTikTokCampaignsWidget(DashboardWidgetConfig config) {
    if (!_isAuthenticated) return _buildWidgetLoginRequired();
    if (!_adsService.isConnected("tiktok"))
      return _buildAdsNotConnected('TikTok', Icons.video_library, Colors.black);

    final campaigns = _adsData?.tiktokCampaigns?['data'];
    if (campaigns == null || campaigns.isEmpty) {
      return _buildNoData('TikTok Campagne');
    }

    return _wrapAdsWidgetWithComment(
      adId: 'tiktok_campaigns',
      platform: 'tiktok',
      title: config.title,
      child: _buildStatsWidget(
        icon: Icons.video_library,
        color: Colors.black,
        value: '${campaigns.length}',
        label: 'Campagne Attive',
      ),
    );
  }

  Widget _buildAdsTikTokReportsWidget(DashboardWidgetConfig config) {
    if (!_isAuthenticated) return _buildWidgetLoginRequired();
    if (!_adsService.isConnected("tiktok"))
      return _buildAdsNotConnected('TikTok', Icons.video_library, Colors.black);

    final reports = _adsData?.tiktokReports?['data'];
    if (reports == null || reports.isEmpty) {
      return _buildNoData('TikTok Report');
    }

    return _wrapAdsWidgetWithComment(
      adId: 'tiktok_reports',
      platform: 'tiktok',
      title: config.title,
      child: _buildStatsWidget(
        icon: Icons.analytics,
        color: Colors.cyan,
        value: '${reports.length}',
        label: 'Report Disponibili',
      ),
    );
  }

  Widget _buildAdsTikTokSpendWidget(DashboardWidgetConfig config) {
    if (!_isAuthenticated) return _buildWidgetLoginRequired();
    if (!_adsService.isConnected("tiktok"))
      return _buildAdsNotConnected('TikTok', Icons.video_library, Colors.black);

    final reports = _adsData?.tiktokReports?['data'];
    if (reports == null || reports.isEmpty) {
      return _buildNoData('TikTok Spesa');
    }

    double totalSpend = 0.0;
    for (var report in reports) {
      totalSpend += double.tryParse(report['spend']?.toString() ?? '0') ?? 0.0;
    }

    return _wrapAdsWidgetWithComment(
      adId: 'tiktok_spend',
      platform: 'tiktok',
      title: config.title,
      child: _buildStatsWidget(
        icon: Icons.euro,
        color: Colors.red,
        value: '€${totalSpend.toStringAsFixed(2)}',
        label: 'Spesa Totale',
      ),
    );
  }

  // =======================================================
  // ==           WIDGET ADS PLATFORM - AGGREGATE         ==
  // =======================================================

  Widget _buildAdsAggregateWidget(DashboardWidgetConfig config) {
    if (!_isAuthenticated) return _buildWidgetLoginRequired();

    final metrics = _adsData?.getAggregateMetrics();
    if (metrics == null) {
      return _buildNoData('Metriche Aggregate');
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricRow(
            'Spesa',
            '€${metrics.totalSpend.toStringAsFixed(2)}',
            Icons.euro,
            Colors.red,
          ),
          const SizedBox(height: 4),
          _buildMetricRow(
            'Impressioni',
            '${metrics.totalImpressions}',
            Icons.visibility,
            Colors.blue,
          ),
          const SizedBox(height: 4),
          _buildMetricRow(
            'Click',
            '${metrics.totalClicks}',
            Icons.touch_app,
            Colors.green,
          ),
          const SizedBox(height: 4),
          _buildMetricRow(
            'CTR',
            '${metrics.ctr.toStringAsFixed(2)}%',
            Icons.percent,
            Colors.purple,
          ),
          const SizedBox(height: 4),
          _buildMetricRow(
            'CPC',
            '€${metrics.cpc.toStringAsFixed(2)}',
            Icons.monetization_on,
            Colors.teal,
          ),
        ],
      ),
    );
  }

  Widget _buildAdsTotalSpendWidget(DashboardWidgetConfig config) {
    if (!_isAuthenticated) return _buildWidgetLoginRequired();

    final metrics = _adsData?.getAggregateMetrics();
    if (metrics == null) {
      return _buildNoData('Spesa Totale');
    }

    return _buildStatsWidget(
      icon: Icons.euro,
      color: Colors.red,
      value: '€${metrics.totalSpend.toStringAsFixed(2)}',
      label: 'Spesa Totale Ads',
    );
  }

  Widget _buildAdsROIWidget(DashboardWidgetConfig config) {
    if (!_isAuthenticated) return _buildWidgetLoginRequired();

    final metrics = _adsData?.getAggregateMetrics();
    if (metrics == null) {
      return _buildNoData('ROI');
    }

    // Calcola ROI basico (conversioni / spesa)
    final roi = metrics.totalSpend > 0
        ? (metrics.totalConversions / metrics.totalSpend) * 100
        : 0.0;

    return _buildStatsWidget(
      icon: Icons.trending_up,
      color: roi > 0 ? Colors.green : Colors.orange,
      value: '${roi.toStringAsFixed(1)}%',
      label: 'ROI Ads',
    );
  }

  // =======================================================
  // ==           HELPER WIDGETS ADS                      ==
  // =======================================================

  Widget _buildStatsWidget({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Wrapper per widget ads che aggiunge il pulsante per i commenti
  Widget _wrapAdsWidgetWithComment({
    required Widget child,
    required String adId,
    required String platform,
    required String title,
  }) {
    // Determina l'accountId corrente in base alla piattaforma
    String? accountId;
    switch (platform) {
      case 'meta':
        accountId = _selectedMetaAccountId;
        break;
      case 'google':
        accountId = _selectedGoogleCustomerId;
        break;
      case 'tiktok':
        accountId = _selectedTikTokAdvertiserId;
        break;
      case 'instagram':
        accountId = _selectedInstagramUserId;
        break;
    }

    // Se non c'è un account selezionato, mostra solo il widget senza commenti
    if (accountId == null || accountId.isEmpty) {
      return child;
    }

    final hasComment = _commentManager.hasComment(adId, platform, accountId);
    final comment = _commentManager.getComment(adId, platform, accountId);

    return Stack(
      children: [
        child,
        // Pulsante commento in alto a destra
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                final result = await showAdsCommentDialog(
                  context: context,
                  adId: adId,
                  platform: platform,
                  accountId:
                      accountId!, // Safe to use ! because we checked earlier
                  adTitle: title,
                  existingComment: comment,
                );

                if (result == true && mounted) {
                  setState(
                    () {},
                  ); // Aggiorna UI per mostrare/nascondere indicatore
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hasComment
                      ? Colors.orange.withValues(alpha: 0.9)
                      : Colors.grey.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasComment ? Icons.comment : Icons.comment_outlined,
                      size: 16,
                      color: Colors.white,
                    ),
                    if (hasComment) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.check_circle,
                        size: 12,
                        color: Colors.white,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        // Mostra estratto del commento se presente
        if (hasComment && comment != null)
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.note, size: 12, color: Colors.white),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      comment.comment.length > 50
                          ? '${comment.comment.substring(0, 50)}...'
                          : comment.comment,
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAdsNotConnected(String platform, IconData icon, Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: color.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(
            '$platform non connesso',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoData(String widgetName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 40,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 12),
          Text(
            'Nessun dato\n$widgetName',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildWidgetLoginRequired() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 32,
              color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Login richiesto',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed('/login');
              },
              icon: const Icon(Icons.login, size: 14),
              label: const Text('Accedi', style: TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
              ),
            ),
          ],
        ),
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

  // =======================================================
  // ==                   DIALOGS                         ==
  // =======================================================

  void _showWidgetSettingsDialog(DashboardWidgetConfig config) {
    showDialog(
      context: context,
      builder: (context) => _WidgetSettingsDialog(
        config: config,
        onSave: (updatedConfig) {
          setState(() {
            final index = _widgets.indexWhere((w) => w.id == config.id);
            if (index >= 0) {
              _widgets[index] = updatedConfig;
            }
          });
          _updateGridConfig();
          _saveLayout();
        },
        onDelete: () {
          setState(() {
            _widgets.removeWhere((w) => w.id == config.id);
            _reorganizeWidgets();
          });
          _updateGridConfig();
          _saveLayout();
        },
      ),
    );
  }

  void _showWidgetManagerDialog() {
    showDialog(
      context: context,
      builder: (context) => _WidgetManagerDialog(
        widgets: _widgets,
        onSave: (updatedWidgets) {
          setState(() {
            _widgets = updatedWidgets;
            _reorganizeWidgets();
          });
          _updateGridConfig();
          _saveLayout();
        },
      ),
    );
  }

  void _showResetConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ripristina Layout'),
        content: const Text(
          'Vuoi ripristinare il layout di default? Tutte le personalizzazioni andranno perse.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetLayout();
            },
            child: const Text('Ripristina'),
          ),
        ],
      ),
    );
  }
}

// =======================================================
// ==          DIALOG IMPOSTAZIONI WIDGET               ==
// =======================================================

class _WidgetSettingsDialog extends StatefulWidget {
  final DashboardWidgetConfig config;
  final Function(DashboardWidgetConfig) onSave;
  final VoidCallback onDelete;

  const _WidgetSettingsDialog({
    required this.config,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<_WidgetSettingsDialog> createState() => _WidgetSettingsDialogState();
}

class _WidgetSettingsDialogState extends State<_WidgetSettingsDialog> {
  late ChartType _selectedChartType;
  late int _width;
  late int _height;

  @override
  void initState() {
    super.initState();
    _selectedChartType = widget.config.chartType;
    _width = widget.config.width;
    _height = widget.config.height;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Impostazioni: ${widget.config.title}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selezione tipo grafico
          const Text(
            'Tipo di Grafico',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: widget.config.supportedChartTypes.map((type) {
              final isSelected = type == _selectedChartType;
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getChartIcon(type),
                      size: 16,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : null,
                    ),
                    const SizedBox(width: 4),
                    Text(_getChartName(type)),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedChartType = type);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Dimensioni widget
          const Text(
            'Larghezza (celle)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Slider(
            value: _width.toDouble(),
            min: 1,
            max: 4,
            divisions: 3,
            label: '$_width',
            onChanged: (value) {
              setState(() => _width = value.toInt());
            },
          ),
          const Text(
            'Altezza (celle)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Slider(
            value: _height.toDouble(),
            min: 1,
            max: 4,
            divisions: 3,
            label: '$_height',
            onChanged: (value) {
              setState(() => _height = value.toInt());
            },
          ),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () {
            Navigator.pop(context);
            // Mostra dialog di conferma
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Rimuovi Widget'),
                content: Text(
                  'Vuoi rimuovere "${widget.config.title}" dalla dashboard?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annulla'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onDelete();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Rimuovi'),
                  ),
                ],
              ),
            );
          },
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          label: const Text('Rimuovi', style: TextStyle(color: Colors.red)),
        ),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.config.chartType = _selectedChartType;
            widget.config.width = _width;
            widget.config.height = _height;
            widget.onSave(widget.config);
            Navigator.pop(context);
          },
          child: const Text('Salva'),
        ),
      ],
    );
  }

  IconData _getChartIcon(ChartType type) {
    switch (type) {
      case ChartType.line:
        return Icons.show_chart;
      case ChartType.bar:
        return Icons.bar_chart;
      case ChartType.pie:
        return Icons.pie_chart;
      case ChartType.area:
        return Icons.area_chart;
      case ChartType.radar:
        return Icons.radar;
    }
  }

  String _getChartName(ChartType type) {
    switch (type) {
      case ChartType.line:
        return 'Linea';
      case ChartType.bar:
        return 'Barre';
      case ChartType.pie:
        return 'Torta';
      case ChartType.area:
        return 'Area';
      case ChartType.radar:
        return 'Radar';
    }
  }
}

// =======================================================
// ==           DIALOG GESTIONE WIDGET                  ==
// =======================================================

class _WidgetManagerDialog extends StatefulWidget {
  final List<DashboardWidgetConfig> widgets;
  final Function(List<DashboardWidgetConfig>) onSave;

  const _WidgetManagerDialog({required this.widgets, required this.onSave});

  @override
  State<_WidgetManagerDialog> createState() => _WidgetManagerDialogState();
}

class _WidgetManagerDialogState extends State<_WidgetManagerDialog> {
  late List<DashboardWidgetConfig> _widgets;

  @override
  void initState() {
    super.initState();
    _widgets = List.from(widget.widgets);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Gestisci Widget'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _widgets.length,
          itemBuilder: (context, index) {
            final widgetConfig = _widgets[index];
            return ListTile(
              leading: Icon(widgetConfig.chartTypeIcon),
              title: Text(widgetConfig.title),
              subtitle: Text('Grafico: ${widgetConfig.chartTypeName}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Rimuovi dalla dashboard',
                onPressed: () {
                  setState(() {
                    _widgets.removeAt(index);
                  });
                },
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_widgets);
            Navigator.pop(context);
          },
          child: const Text('Salva'),
        ),
      ],
    );
  }
}
