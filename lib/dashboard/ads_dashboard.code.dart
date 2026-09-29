// Ads Dashboard Code - Logica ads temporaneamente esclusa dalla build F-Droid.
//
// ADS_CONNECTOR_DISABLED_FOR_FDROID
// L'integrazione ads_connector resta conservata più sotto come codice commentato,
// ma non entra nella compilazione finché la funzionalità non viene ripresa/testata.

/// Service stub per mantenere stabile l'API usata dalla dashboard.
class AdsPlatformService {
  Function(AdsPlatformData)? onDataUpdated;

  bool get isSchedulerRunning => false;

  Future<void> initialize() async {}

  Future<bool> loginMeta() async => false;

  Future<bool> loginGoogle() async => false;

  Future<bool> loginTikTok() async => false;

  Future<void> logout(String provider) async {}

  Future<AdsPlatformData> fetchAllData({
    String? metaAdAccountId,
    String? googleCustomerId,
    String? tiktokAdvertiserId,
    String? instagramUserId,
  }) async => AdsPlatformData();

  void startAutoRefresh({
    required Duration interval,
    String? metaAdAccountId,
    String? googleCustomerId,
    String? tiktokAdvertiserId,
    String? instagramUserId,
  }) {}

  void stopAutoRefresh() {}

  bool isConnected(String provider) => false;

  void dispose() {}
}

/// Modello dati per contenere tutti i dati delle piattaforme ads.
class AdsPlatformData {
  dynamic metaCampaigns;
  dynamic metaInsights;
  dynamic instagramMedia;
  dynamic googleCampaigns;
  dynamic tiktokCampaigns;
  dynamic tiktokReports;

  AdsPlatformData({
    this.metaCampaigns,
    this.metaInsights,
    this.instagramMedia,
    this.googleCampaigns,
    this.tiktokCampaigns,
    this.tiktokReports,
  });

  AdsMetrics getAggregateMetrics() => AdsMetrics(
    totalSpend: 0,
    totalImpressions: 0,
    totalClicks: 0,
    totalConversions: 0,
    ctr: 0,
    cpc: 0,
  );
}

/// Metriche aggregate di tutte le piattaforme.
class AdsMetrics {
  final double totalSpend;
  final int totalImpressions;
  final int totalClicks;
  final int totalConversions;
  final double ctr;
  final double cpc;

  AdsMetrics({
    required this.totalSpend,
    required this.totalImpressions,
    required this.totalClicks,
    required this.totalConversions,
    required this.ctr,
    required this.cpc,
  });
}

// -----------------------------------------------------------------------------
// Implementazione originale disabilitata per F-Droid / alfa non testato.
// Non rimuovere: verrà ripresa quando ads_connector sarà reso compatibile.
// -----------------------------------------------------------------------------
// ORIGINAL_ADS_CONNECTOR_CODE: // Ads Dashboard Code - Logica per gestione piattaforme ads
// ORIGINAL_ADS_CONNECTOR_CODE: //
// ORIGINAL_ADS_CONNECTOR_CODE: // Service layer per Meta Ads, Google Ads, TikTok Ads
// ORIGINAL_ADS_CONNECTOR_CODE: // Gestisce OAuth, recupero dati, caching, scheduler
// ORIGINAL_ADS_CONNECTOR_CODE:
// ORIGINAL_ADS_CONNECTOR_CODE: import 'package:ads_connector/ads_connector.dart';
// ORIGINAL_ADS_CONNECTOR_CODE: import '../log_viewer/app_logger.dart';
// ORIGINAL_ADS_CONNECTOR_CODE:
// ORIGINAL_ADS_CONNECTOR_CODE: /// Service per gestione completa delle piattaforme ads
// ORIGINAL_ADS_CONNECTOR_CODE: class AdsPlatformService {
// ORIGINAL_ADS_CONNECTOR_CODE:   // Clients per ogni piattaforma
// ORIGINAL_ADS_CONNECTOR_CODE:   MetaClient? _metaClient;
// ORIGINAL_ADS_CONNECTOR_CODE:   GoogleAdsClient? _googleAdsClient;
// ORIGINAL_ADS_CONNECTOR_CODE:   TikTokAdsClient? _tiktokAdsClient;
// ORIGINAL_ADS_CONNECTOR_CODE:   InstagramClient? _instagramClient;
// ORIGINAL_ADS_CONNECTOR_CODE:
// ORIGINAL_ADS_CONNECTOR_CODE:   // Scheduler per aggiornamento automatico
// ORIGINAL_ADS_CONNECTOR_CODE:   final Scheduler _scheduler = Scheduler();
// ORIGINAL_ADS_CONNECTOR_CODE:
// ORIGINAL_ADS_CONNECTOR_CODE:   // Callback per notificare la UI degli aggiornamenti
// ORIGINAL_ADS_CONNECTOR_CODE:   Function(AdsPlatformData)? onDataUpdated;
// ORIGINAL_ADS_CONNECTOR_CODE:
// ORIGINAL_ADS_CONNECTOR_CODE:   // Getter pubblico per verificare se lo scheduler è attivo
// ORIGINAL_ADS_CONNECTOR_CODE:   bool get isSchedulerRunning => _scheduler.isRunning;
// ORIGINAL_ADS_CONNECTOR_CODE:
// ORIGINAL_ADS_CONNECTOR_CODE:   /// Inizializza il service e carica i token salvati
// ORIGINAL_ADS_CONNECTOR_CODE:   Future<void> initialize() async {
// ORIGINAL_ADS_CONNECTOR_CODE:     // Carica token salvati per ogni provider
// ORIGINAL_ADS_CONNECTOR_CODE:     final metaToken = await OAuthManager.loadSavedToken("meta");
// ORIGINAL_ADS_CONNECTOR_CODE:     final googleToken = await OAuthManager.loadSavedToken("google");
// ORIGINAL_ADS_CONNECTOR_CODE:     final tiktokToken = await OAuthManager.loadSavedToken("tiktok");
// ORIGINAL_ADS_CONNECTOR_CODE:
// ORIGINAL_ADS_CONNECTOR_CODE:     // Inizializza i client se i token esistono
// ORIGINAL_ADS_CONNECTOR_CODE:     if (metaToken != null) {
// ORIGINAL_ADS_CONNECTOR_CODE:       _metaClient = MetaClient(metaToken);
// ORIGINAL_ADS_CONNECTOR_CODE:       _instagramClient = InstagramClient(metaToken);
// ORIGINAL_ADS_CONNECTOR_CODE:     }
// ORIGINAL_ADS_CONNECTOR_CODE:     if (googleToken != null) {
// ORIGINAL_ADS_CONNECTOR_CODE:       _googleAdsClient = GoogleAdsClient(googleToken);
// ORIGINAL_ADS_CONNECTOR_CODE:     }
// ORIGINAL_ADS_CONNECTOR_CODE:     if (tiktokToken != null) {
// ORIGINAL_ADS_CONNECTOR_CODE:       _tiktokAdsClient = TikTokAdsClient(tiktokToken);
// ORIGINAL_ADS_CONNECTOR_CODE:     }
// ORIGINAL_ADS_CONNECTOR_CODE:
// ORIGINAL_ADS_CONNECTOR_CODE:     // TODO: Configura logger quando disponibile
// ORIGINAL_ADS_CONNECTOR_CODE:     // Logger.enabled = true;
// ORIGINAL_ADS_CONNECTOR_CODE:     // Logger.minLevel = "INFO";
// ORIGINAL_ADS_CONNECTOR_CODE:     // Logger.addListener((level, tag, message) {
// ORIGINAL_ADS_CONNECTOR_CODE:     //   print('[$level] $tag: $message');
// ORIGINAL_ADS_CONNECTOR_CODE:     // });
// ORIGINAL_ADS_CONNECTOR_CODE:   }
// ORIGINAL_ADS_CONNECTOR_CODE:
// ORIGINAL_ADS_CONNECTOR_CODE:   /// Login Meta (Facebook/Instagram)
// ORIGINAL_ADS_CONNECTOR_CODE:   Future<bool> loginMeta() async {
// ORIGINAL_ADS_CONNECTOR_CODE:     try {
// ORIGINAL_ADS_CONNECTOR_CODE:       final token = await OAuthManager.loginMeta();
// ORIGINAL_ADS_CONNECTOR_CODE:       if (token != null) {
// ORIGINAL_ADS_CONNECTOR_CODE:         _metaClient = MetaClient(token);
// ORIGINAL_ADS_CONNECTOR_CODE:         _instagramClient = InstagramClient(token);
// ORIGINAL_ADS_CONNECTOR_CODE:         return true;
// ORIGINAL_ADS_CONNECTOR_CODE:       }
// ORIGINAL_ADS_CONNECTOR_CODE:       return false;
// ORIGINAL_ADS_CONNECTOR_CODE:     } catch (e) {
// ORIGINAL_ADS_CONNECTOR_CODE:       log.e('ADS_SERVICE - Login Meta fallito', e);
// ORIGINAL_ADS_CONNECTOR_CODE:       return false;
// ORIGINAL_ADS_CONNECTOR_CODE:     }
// ORIGINAL_ADS_CONNECTOR_CODE:   }
// ORIGINAL_ADS_CONNECTOR_CODE:
// ORIGINAL_ADS_CONNECTOR_CODE:   /// Login Google Ads
// ORIGINAL_ADS_CONNECTOR_CODE:   Future<bool> loginGoogle() async {
// ORIGINAL_ADS_CONNECTOR_CODE:     try {
// ORIGINAL_ADS_CONNECTOR_CODE:       final token = await OAuthManager.loginGoogle();
// ORIGINAL_ADS_CONNECTOR_CODE:       if (token != null) {
// ORIGINAL_ADS_CONNECTOR_CODE:         _googleAdsClient = GoogleAdsClient(token);
// ORIGINAL_ADS_CONNECTOR_CODE:         return true;
// ORIGINAL_ADS_CONNECTOR_CODE:       }
// ORIGINAL_ADS_CONNECTOR_CODE:       return false;
// ORIGINAL_ADS_CONNECTOR_CODE:     } catch (e) {
// ORIGINAL_ADS_CONNECTOR_CODE:       log.e('ADS_SERVICE - Login Google fallito', e);
// ORIGINAL_ADS_CONNECTOR_CODE:       return false;
// ORIGINAL_ADS_CONNECTOR_CODE:     }
// ORIGINAL_ADS_CONNECTOR_CODE:   }
// ORIGINAL_ADS_CONNECTOR_CODE:
// ORIGINAL_ADS_CONNECTOR_CODE:   /// Login TikTok Ads
// ORIGINAL_ADS_CONNECTOR_CODE:   Future<bool> loginTikTok() async {
// ORIGINAL_ADS_CONNECTOR_CODE:     try {
// ORIGINAL_ADS_CONNECTOR_CODE:       final token = await OAuthManager.loginTikTok();
// ORIGINAL_ADS_CONNECTOR_CODE:       if (token != null) {
// ORIGINAL_ADS_CONNECTOR_CODE:         _tiktokAdsClient = TikTokAdsClient(token);
// ORIGINAL_ADS_CONNECTOR_CODE:         return true;
// ORIGINAL_ADS_CONNECTOR_CODE:       }
// ORIGINAL_ADS_CONNECTOR_CODE:       return false;
// ORIGINAL_ADS_CONNECTOR_CODE:     } catch (e) {
// ORIGINAL_ADS_CONNECTOR_CODE:       log.e('ADS_SERVICE - Login TikTok fallito', e);
// ORIGINAL_ADS_CONNECTOR_CODE:       return false;
// ORIGINAL_ADS_CONNECTOR_CODE:     }
// ORIGINAL_ADS_CONNECTOR_CODE:   }
// ORIGINAL_ADS_CONNECTOR_CODE:
// ORIGINAL_ADS_CONNECTOR_CODE:   /// Logout da una piattaforma
// ORIGINAL_ADS_CONNECTOR_CODE:   Future<void> logout(String provider) async {
// ORIGINAL_ADS_CONNECTOR_CODE:     await OAuthManager.clearSavedToken(provider);
// ORIGINAL_ADS_CONNECTOR_CODE:
// ORIGINAL_ADS_CONNECTOR_CODE:     switch (provider) {
// ORIGINAL_ADS_CONNECTOR_CODE:       case "meta":
// ORIGINAL_ADS_CONNECTOR_CODE:         _metaClient = null;
// ORIGINAL_ADS_CONNECTOR_CODE:         _instagramClient = null;
// ORIGINAL_ADS_CONNECTOR_CODE:         break;
// ORIGINAL_ADS_CONNECTOR_CODE:       case "google":
// ORIGINAL_ADS_CONNECTOR_CODE:         _googleAdsClient = null;
// ORIGINAL_ADS_CONNECTOR_CODE:         break;
// ORIGINAL_ADS_CONNECTOR_CODE:       case "tiktok":
// ORIGINAL_ADS_CONNECTOR_CODE:         _tiktokAdsClient = null;
// ORIGINAL_ADS_CONNECTOR_CODE:         break;
// ORIGINAL_ADS_CONNECTOR_CODE:     }
// ORIGINAL_ADS_CONNECTOR_CODE:   }
// ORIGINAL_ADS_CONNECTOR_CODE:
// ORIGINAL_ADS_CONNECTOR_CODE:   /// Recupera tutti i dati dalle piattaforme connesse
// ORIGINAL_ADS_CONNECTOR_CODE:   Future<AdsPlatformData> fetchAllData({
// ORIGINAL_ADS_CONNECTOR_CODE:     String? metaAdAccountId,
// ORIGINAL_ADS_CONNECTOR_CODE:     String? googleCustomerId,
// ORIGINAL_ADS_CONNECTOR_CODE:     String? tiktokAdvertiserId,
// ORIGINAL_ADS_CONNECTOR_CODE:     String? instagramUserId,
// ORIGINAL_ADS_CONNECTOR_CODE:   }) async {
// ORIGINAL_ADS_CONNECTOR_CODE:     final data = AdsPlatformData();
// ORIGINAL_ADS_CONNECTOR_CODE:
// ORIGINAL_ADS_CONNECTOR_CODE:     // Fetch Meta Ads
// ORIGINAL_ADS_CONNECTOR_CODE:     if (_metaClient != null && metaAdAccountId != null) {
// ORIGINAL_ADS_CONNECTOR_CODE:       try {
// ORIGINAL_ADS_CONNECTOR_CODE:         data.metaCampaigns = await _metaClient!.fetchCampaignsRaw(
// ORIGINAL_ADS_CONNECTOR_CODE:           metaAdAccountId,
// ORIGINAL_ADS_CONNECTOR_CODE:         );
// ORIGINAL_ADS_CONNECTOR_CODE:         // TODO: Verificare firma corretta del metodo fetchInsightsRaw
// ORIGINAL_ADS_CONNECTOR_CODE:         // data.metaInsights = await _metaClient!.fetchInsightsRaw(
// ORIGINAL_ADS_CONNECTOR_CODE:         //   metaAdAccountId,
// ORIGINAL_ADS_CONNECTOR_CODE:         //   {
// ORIGINAL_ADS_CONNECTOR_CODE:         //     'time_range': {
// ORIGINAL_ADS_CONNECTOR_CODE:         //       'since': DateTime.now().subtract(Duration(days: 30)).toIso8601String().split('T')[0],
// ORIGINAL_ADS_CONNECTOR_CODE:         //       'until': DateTime.now().toIso8601String().split('T')[0],
// ORIGINAL_ADS_CONNECTOR_CODE:         //     },
// ORIGINAL_ADS_CONNECTOR_CODE:         //     'level': 'campaign',
// ORIGINAL_ADS_CONNECTOR_CODE:         //     'fields': 'campaign_name,impressions,clicks,spend,cpc,cpm,ctr',
// ORIGINAL_ADS_CONNECTOR_CODE:         //   },
// ORIGINAL_ADS_CONNECTOR_CODE:         // );
// ORIGINAL_ADS_CONNECTOR_CODE:       } catch (e) {
// ORIGINAL_ADS_CONNECTOR_CODE:         log.e('ADS_SERVICE - Errore fetch Meta Ads', e);
// ORIGINAL_ADS_CONNECTOR_CODE:       }
// ORIGINAL_ADS_CONNECTOR_CODE:     }
// ORIGINAL_ADS_CONNECTOR_CODE:
// ORIGINAL_ADS_CONNECTOR_CODE:     // Fetch Instagram
// ORIGINAL_ADS_CONNECTOR_CODE:     if (_instagramClient != null && instagramUserId != null) {
// ORIGINAL_ADS_CONNECTOR_CODE:       try {
// ORIGINAL_ADS_CONNECTOR_CODE:         data.instagramMedia = await _instagramClient!.fetchMedia(
// ORIGINAL_ADS_CONNECTOR_CODE:           instagramUserId,
// ORIGINAL_ADS_CONNECTOR_CODE:         );
// ORIGINAL_ADS_CONNECTOR_CODE:       } catch (e) {
// ORIGINAL_ADS_CONNECTOR_CODE:         log.e('ADS_SERVICE - Errore fetch Instagram', e);
// ORIGINAL_ADS_CONNECTOR_CODE:       }
// ORIGINAL_ADS_CONNECTOR_CODE:     }
// ORIGINAL_ADS_CONNECTOR_CODE:
// ORIGINAL_ADS_CONNECTOR_CODE:     // Fetch Google Ads
// ORIGINAL_ADS_CONNECTOR_CODE:     if (_googleAdsClient != null && googleCustomerId != null) {
// ORIGINAL_ADS_CONNECTOR_CODE:       try {
// ORIGINAL_ADS_CONNECTOR_CODE:         // TODO: Verificare firma corretta del metodo fetchCampaignsRaw
// ORIGINAL_ADS_CONNECTOR_CODE:         // data.googleCampaigns = await _googleAdsClient!.fetchCampaignsRaw(
// ORIGINAL_ADS_CONNECTOR_CODE:         //   googleCustomerId,
// ORIGINAL_ADS_CONNECTOR_CODE:         //   'SELECT campaign.id, campaign.name, metrics.impressions, metrics.clicks, metrics.cost_micros FROM campaign WHERE segments.date DURING LAST_30_DAYS',
// ORIGINAL_ADS_CONNECTOR_CODE:         // );
// ORIGINAL_ADS_CONNECTOR_CODE:       } catch (e) {
// ORIGINAL_ADS_CONNECTOR_CODE:         log.e('ADS_SERVICE - Errore fetch Google Ads', e);
// ORIGINAL_ADS_CONNECTOR_CODE:       }
// ORIGINAL_ADS_CONNECTOR_CODE:     }
// ORIGINAL_ADS_CONNECTOR_CODE:
// ORIGINAL_ADS_CONNECTOR_CODE:     // Fetch TikTok Ads
// ORIGINAL_ADS_CONNECTOR_CODE:     if (_tiktokAdsClient != null && tiktokAdvertiserId != null) {
// ORIGINAL_ADS_CONNECTOR_CODE:       try {
// ORIGINAL_ADS_CONNECTOR_CODE:         data.tiktokCampaigns = await _tiktokAdsClient!.fetchCampaignsRaw(
// ORIGINAL_ADS_CONNECTOR_CODE:           tiktokAdvertiserId,
// ORIGINAL_ADS_CONNECTOR_CODE:         );
// ORIGINAL_ADS_CONNECTOR_CODE:         data.tiktokReports = await _tiktokAdsClient!.fetchReportsRaw(
// ORIGINAL_ADS_CONNECTOR_CODE:           tiktokAdvertiserId,
// ORIGINAL_ADS_CONNECTOR_CODE:           {
// ORIGINAL_ADS_CONNECTOR_CODE:             'start_date': DateTime.now()
// ORIGINAL_ADS_CONNECTOR_CODE:                 .subtract(Duration(days: 30))
// ORIGINAL_ADS_CONNECTOR_CODE:                 .toIso8601String()
// ORIGINAL_ADS_CONNECTOR_CODE:                 .split('T')[0],
// ORIGINAL_ADS_CONNECTOR_CODE:             'end_date': DateTime.now().toIso8601String().split('T')[0],
// ORIGINAL_ADS_CONNECTOR_CODE:             'metrics': ['spend', 'impressions', 'clicks', 'conversions'],
// ORIGINAL_ADS_CONNECTOR_CODE:           },
// ORIGINAL_ADS_CONNECTOR_CODE:         );
// ORIGINAL_ADS_CONNECTOR_CODE:       } catch (e) {
// ORIGINAL_ADS_CONNECTOR_CODE:         log.e('ADS_SERVICE - Errore fetch TikTok Ads', e);
// ORIGINAL_ADS_CONNECTOR_CODE:       }
// ORIGINAL_ADS_CONNECTOR_CODE:     }
// ORIGINAL_ADS_CONNECTOR_CODE:
// ORIGINAL_ADS_CONNECTOR_CODE:     return data;
// ORIGINAL_ADS_CONNECTOR_CODE:   }
// ORIGINAL_ADS_CONNECTOR_CODE:
// ORIGINAL_ADS_CONNECTOR_CODE:   /// Avvia scheduler per aggiornamento automatico ogni X minuti
// ORIGINAL_ADS_CONNECTOR_CODE:   void startAutoRefresh({
// ORIGINAL_ADS_CONNECTOR_CODE:     required Duration interval,
// ORIGINAL_ADS_CONNECTOR_CODE:     String? metaAdAccountId,
// ORIGINAL_ADS_CONNECTOR_CODE:     String? googleCustomerId,
// ORIGINAL_ADS_CONNECTOR_CODE:     String? tiktokAdvertiserId,
// ORIGINAL_ADS_CONNECTOR_CODE:     String? instagramUserId,
// ORIGINAL_ADS_CONNECTOR_CODE:   }) {
// ORIGINAL_ADS_CONNECTOR_CODE:     _scheduler.start(
// ORIGINAL_ADS_CONNECTOR_CODE:       interval: interval,
// ORIGINAL_ADS_CONNECTOR_CODE:       onRefresh: () async {
// ORIGINAL_ADS_CONNECTOR_CODE:         log.d('ADS_SERVICE - Auto-refresh dati ads...');
// ORIGINAL_ADS_CONNECTOR_CODE:         final data = await fetchAllData(
// ORIGINAL_ADS_CONNECTOR_CODE:           metaAdAccountId: metaAdAccountId,
// ORIGINAL_ADS_CONNECTOR_CODE:           googleCustomerId: googleCustomerId,
// ORIGINAL_ADS_CONNECTOR_CODE:           tiktokAdvertiserId: tiktokAdvertiserId,
// ORIGINAL_ADS_CONNECTOR_CODE:           instagramUserId: instagramUserId,
// ORIGINAL_ADS_CONNECTOR_CODE:         );
// ORIGINAL_ADS_CONNECTOR_CODE:
// ORIGINAL_ADS_CONNECTOR_CODE:         // Notifica la UI
// ORIGINAL_ADS_CONNECTOR_CODE:         onDataUpdated?.call(data);
// ORIGINAL_ADS_CONNECTOR_CODE:       },
// ORIGINAL_ADS_CONNECTOR_CODE:     );
// ORIGINAL_ADS_CONNECTOR_CODE:   }
// ORIGINAL_ADS_CONNECTOR_CODE:
// ORIGINAL_ADS_CONNECTOR_CODE:   /// Ferma lo scheduler
// ORIGINAL_ADS_CONNECTOR_CODE:   void stopAutoRefresh() {
// ORIGINAL_ADS_CONNECTOR_CODE:     _scheduler.stop();
// ORIGINAL_ADS_CONNECTOR_CODE:   }
// ORIGINAL_ADS_CONNECTOR_CODE:
// ORIGINAL_ADS_CONNECTOR_CODE:   /// Verifica se una piattaforma è connessa
// ORIGINAL_ADS_CONNECTOR_CODE:   bool isConnected(String provider) {
// ORIGINAL_ADS_CONNECTOR_CODE:     switch (provider) {
// ORIGINAL_ADS_CONNECTOR_CODE:       case "meta":
// ORIGINAL_ADS_CONNECTOR_CODE:         return _metaClient != null;
// ORIGINAL_ADS_CONNECTOR_CODE:       case "google":
// ORIGINAL_ADS_CONNECTOR_CODE:         return _googleAdsClient != null;
// ORIGINAL_ADS_CONNECTOR_CODE:       case "tiktok":
// ORIGINAL_ADS_CONNECTOR_CODE:         return _tiktokAdsClient != null;
// ORIGINAL_ADS_CONNECTOR_CODE:       default:
// ORIGINAL_ADS_CONNECTOR_CODE:         return false;
// ORIGINAL_ADS_CONNECTOR_CODE:     }
// ORIGINAL_ADS_CONNECTOR_CODE:   }
// ORIGINAL_ADS_CONNECTOR_CODE:
// ORIGINAL_ADS_CONNECTOR_CODE:   /// Cleanup
// ORIGINAL_ADS_CONNECTOR_CODE:   void dispose() {
// ORIGINAL_ADS_CONNECTOR_CODE:     _scheduler.stop();
// ORIGINAL_ADS_CONNECTOR_CODE:     // TODO: Rimuovere listener quando Logger sarà disponibile
// ORIGINAL_ADS_CONNECTOR_CODE:     // Logger.removeListener((level, tag, message) {
// ORIGINAL_ADS_CONNECTOR_CODE:     //   print('[$level] $tag: $message');
// ORIGINAL_ADS_CONNECTOR_CODE:     // });
// ORIGINAL_ADS_CONNECTOR_CODE:   }
// ORIGINAL_ADS_CONNECTOR_CODE: }
// ORIGINAL_ADS_CONNECTOR_CODE:
// ORIGINAL_ADS_CONNECTOR_CODE: /// Modello dati per contenere tutti i dati delle piattaforme
// ORIGINAL_ADS_CONNECTOR_CODE: class AdsPlatformData {
// ORIGINAL_ADS_CONNECTOR_CODE:   // Meta Ads
// ORIGINAL_ADS_CONNECTOR_CODE:   dynamic metaCampaigns;
// ORIGINAL_ADS_CONNECTOR_CODE:   dynamic metaInsights;
// ORIGINAL_ADS_CONNECTOR_CODE:
// ORIGINAL_ADS_CONNECTOR_CODE:   // Instagram
// ORIGINAL_ADS_CONNECTOR_CODE:   dynamic instagramMedia;
// ORIGINAL_ADS_CONNECTOR_CODE:
// ORIGINAL_ADS_CONNECTOR_CODE:   // Google Ads
// ORIGINAL_ADS_CONNECTOR_CODE:   dynamic googleCampaigns;
// ORIGINAL_ADS_CONNECTOR_CODE:
// ORIGINAL_ADS_CONNECTOR_CODE:   // TikTok Ads
// ORIGINAL_ADS_CONNECTOR_CODE:   dynamic tiktokCampaigns;
// ORIGINAL_ADS_CONNECTOR_CODE:   dynamic tiktokReports;
// ORIGINAL_ADS_CONNECTOR_CODE:
// ORIGINAL_ADS_CONNECTOR_CODE:   AdsPlatformData({
// ORIGINAL_ADS_CONNECTOR_CODE:     this.metaCampaigns,
// ORIGINAL_ADS_CONNECTOR_CODE:     this.metaInsights,
// ORIGINAL_ADS_CONNECTOR_CODE:     this.instagramMedia,
// ORIGINAL_ADS_CONNECTOR_CODE:     this.googleCampaigns,
// ORIGINAL_ADS_CONNECTOR_CODE:     this.tiktokCampaigns,
// ORIGINAL_ADS_CONNECTOR_CODE:     this.tiktokReports,
// ORIGINAL_ADS_CONNECTOR_CODE:   });
// ORIGINAL_ADS_CONNECTOR_CODE:
// ORIGINAL_ADS_CONNECTOR_CODE:   /// Calcola metriche aggregate
// ORIGINAL_ADS_CONNECTOR_CODE:   AdsMetrics getAggregateMetrics() {
// ORIGINAL_ADS_CONNECTOR_CODE:     double totalSpend = 0.0;
// ORIGINAL_ADS_CONNECTOR_CODE:     int totalImpressions = 0;
// ORIGINAL_ADS_CONNECTOR_CODE:     int totalClicks = 0;
// ORIGINAL_ADS_CONNECTOR_CODE:     int totalConversions = 0;
// ORIGINAL_ADS_CONNECTOR_CODE:
// ORIGINAL_ADS_CONNECTOR_CODE:     // Aggrega Meta Ads
// ORIGINAL_ADS_CONNECTOR_CODE:     if (metaInsights != null && metaInsights['data'] != null) {
// ORIGINAL_ADS_CONNECTOR_CODE:       for (var insight in metaInsights['data']) {
// ORIGINAL_ADS_CONNECTOR_CODE:         totalSpend +=
// ORIGINAL_ADS_CONNECTOR_CODE:             double.tryParse(insight['spend']?.toString() ?? '0') ?? 0.0;
// ORIGINAL_ADS_CONNECTOR_CODE:         totalImpressions +=
// ORIGINAL_ADS_CONNECTOR_CODE:             int.tryParse(insight['impressions']?.toString() ?? '0') ?? 0;
// ORIGINAL_ADS_CONNECTOR_CODE:         totalClicks += int.tryParse(insight['clicks']?.toString() ?? '0') ?? 0;
// ORIGINAL_ADS_CONNECTOR_CODE:       }
// ORIGINAL_ADS_CONNECTOR_CODE:     }
// ORIGINAL_ADS_CONNECTOR_CODE:
// ORIGINAL_ADS_CONNECTOR_CODE:     // Aggrega Google Ads
// ORIGINAL_ADS_CONNECTOR_CODE:     if (googleCampaigns != null) {
// ORIGINAL_ADS_CONNECTOR_CODE:       // Parsing specifico per Google Ads query results
// ORIGINAL_ADS_CONNECTOR_CODE:       // Dipende dalla struttura della risposta
// ORIGINAL_ADS_CONNECTOR_CODE:     }
// ORIGINAL_ADS_CONNECTOR_CODE:
// ORIGINAL_ADS_CONNECTOR_CODE:     // Aggrega TikTok Ads
// ORIGINAL_ADS_CONNECTOR_CODE:     if (tiktokReports != null && tiktokReports['data'] != null) {
// ORIGINAL_ADS_CONNECTOR_CODE:       for (var report in tiktokReports['data']) {
// ORIGINAL_ADS_CONNECTOR_CODE:         totalSpend +=
// ORIGINAL_ADS_CONNECTOR_CODE:             double.tryParse(report['spend']?.toString() ?? '0') ?? 0.0;
// ORIGINAL_ADS_CONNECTOR_CODE:         totalImpressions +=
// ORIGINAL_ADS_CONNECTOR_CODE:             int.tryParse(report['impressions']?.toString() ?? '0') ?? 0;
// ORIGINAL_ADS_CONNECTOR_CODE:         totalClicks += int.tryParse(report['clicks']?.toString() ?? '0') ?? 0;
// ORIGINAL_ADS_CONNECTOR_CODE:         totalConversions +=
// ORIGINAL_ADS_CONNECTOR_CODE:             int.tryParse(report['conversions']?.toString() ?? '0') ?? 0;
// ORIGINAL_ADS_CONNECTOR_CODE:       }
// ORIGINAL_ADS_CONNECTOR_CODE:     }
// ORIGINAL_ADS_CONNECTOR_CODE:
// ORIGINAL_ADS_CONNECTOR_CODE:     return AdsMetrics(
// ORIGINAL_ADS_CONNECTOR_CODE:       totalSpend: totalSpend,
// ORIGINAL_ADS_CONNECTOR_CODE:       totalImpressions: totalImpressions,
// ORIGINAL_ADS_CONNECTOR_CODE:       totalClicks: totalClicks,
// ORIGINAL_ADS_CONNECTOR_CODE:       totalConversions: totalConversions,
// ORIGINAL_ADS_CONNECTOR_CODE:       ctr: totalImpressions > 0 ? (totalClicks / totalImpressions) * 100 : 0.0,
// ORIGINAL_ADS_CONNECTOR_CODE:       cpc: totalClicks > 0 ? totalSpend / totalClicks : 0.0,
// ORIGINAL_ADS_CONNECTOR_CODE:     );
// ORIGINAL_ADS_CONNECTOR_CODE:   }
// ORIGINAL_ADS_CONNECTOR_CODE: }
// ORIGINAL_ADS_CONNECTOR_CODE:
// ORIGINAL_ADS_CONNECTOR_CODE: /// Metriche aggregate di tutte le piattaforme
// ORIGINAL_ADS_CONNECTOR_CODE: class AdsMetrics {
// ORIGINAL_ADS_CONNECTOR_CODE:   final double totalSpend;
// ORIGINAL_ADS_CONNECTOR_CODE:   final int totalImpressions;
// ORIGINAL_ADS_CONNECTOR_CODE:   final int totalClicks;
// ORIGINAL_ADS_CONNECTOR_CODE:   final int totalConversions;
// ORIGINAL_ADS_CONNECTOR_CODE:   final double ctr; // Click-through rate
// ORIGINAL_ADS_CONNECTOR_CODE:   final double cpc; // Cost per click
// ORIGINAL_ADS_CONNECTOR_CODE:
// ORIGINAL_ADS_CONNECTOR_CODE:   AdsMetrics({
// ORIGINAL_ADS_CONNECTOR_CODE:     required this.totalSpend,
// ORIGINAL_ADS_CONNECTOR_CODE:     required this.totalImpressions,
// ORIGINAL_ADS_CONNECTOR_CODE:     required this.totalClicks,
// ORIGINAL_ADS_CONNECTOR_CODE:     required this.totalConversions,
// ORIGINAL_ADS_CONNECTOR_CODE:     required this.ctr,
// ORIGINAL_ADS_CONNECTOR_CODE:     required this.cpc,
// ORIGINAL_ADS_CONNECTOR_CODE:   });
// ORIGINAL_ADS_CONNECTOR_CODE: }
