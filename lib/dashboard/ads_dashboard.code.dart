// Ads Dashboard Code - Logica per gestione piattaforme ads
//
// Service layer per Meta Ads, Google Ads, TikTok Ads
// Gestisce OAuth, recupero dati, caching, scheduler

import 'package:ads_connector/ads_connector.dart';
import '../log_viewer/app_logger.dart';

/// Service per gestione completa delle piattaforme ads
class AdsPlatformService {
  // Clients per ogni piattaforma
  MetaClient? _metaClient;
  GoogleAdsClient? _googleAdsClient;
  TikTokAdsClient? _tiktokAdsClient;
  InstagramClient? _instagramClient;

  // Scheduler per aggiornamento automatico
  final Scheduler _scheduler = Scheduler();

  // Callback per notificare la UI degli aggiornamenti
  Function(AdsPlatformData)? onDataUpdated;

  // Getter pubblico per verificare se lo scheduler è attivo
  bool get isSchedulerRunning => _scheduler.isRunning;

  /// Inizializza il service e carica i token salvati
  Future<void> initialize() async {
    // Carica token salvati per ogni provider
    final metaToken = await OAuthManager.loadSavedToken("meta");
    final googleToken = await OAuthManager.loadSavedToken("google");
    final tiktokToken = await OAuthManager.loadSavedToken("tiktok");

    // Inizializza i client se i token esistono
    if (metaToken != null) {
      _metaClient = MetaClient(metaToken);
      _instagramClient = InstagramClient(metaToken);
    }
    if (googleToken != null) {
      _googleAdsClient = GoogleAdsClient(googleToken);
    }
    if (tiktokToken != null) {
      _tiktokAdsClient = TikTokAdsClient(tiktokToken);
    }

    // TODO: Configura logger quando disponibile
    // Logger.enabled = true;
    // Logger.minLevel = "INFO";
    // Logger.addListener((level, tag, message) {
    //   print('[$level] $tag: $message');
    // });
  }

  /// Login Meta (Facebook/Instagram)
  Future<bool> loginMeta() async {
    try {
      final token = await OAuthManager.loginMeta();
      if (token != null) {
        _metaClient = MetaClient(token);
        _instagramClient = InstagramClient(token);
        return true;
      }
      return false;
    } catch (e) {
      log.e('ADS_SERVICE - Login Meta fallito', e);
      return false;
    }
  }

  /// Login Google Ads
  Future<bool> loginGoogle() async {
    try {
      final token = await OAuthManager.loginGoogle();
      if (token != null) {
        _googleAdsClient = GoogleAdsClient(token);
        return true;
      }
      return false;
    } catch (e) {
      log.e('ADS_SERVICE - Login Google fallito', e);
      return false;
    }
  }

  /// Login TikTok Ads
  Future<bool> loginTikTok() async {
    try {
      final token = await OAuthManager.loginTikTok();
      if (token != null) {
        _tiktokAdsClient = TikTokAdsClient(token);
        return true;
      }
      return false;
    } catch (e) {
      log.e('ADS_SERVICE - Login TikTok fallito', e);
      return false;
    }
  }

  /// Logout da una piattaforma
  Future<void> logout(String provider) async {
    await OAuthManager.clearSavedToken(provider);

    switch (provider) {
      case "meta":
        _metaClient = null;
        _instagramClient = null;
        break;
      case "google":
        _googleAdsClient = null;
        break;
      case "tiktok":
        _tiktokAdsClient = null;
        break;
    }
  }

  /// Recupera tutti i dati dalle piattaforme connesse
  Future<AdsPlatformData> fetchAllData({
    String? metaAdAccountId,
    String? googleCustomerId,
    String? tiktokAdvertiserId,
    String? instagramUserId,
  }) async {
    final data = AdsPlatformData();

    // Fetch Meta Ads
    if (_metaClient != null && metaAdAccountId != null) {
      try {
        data.metaCampaigns = await _metaClient!.fetchCampaignsRaw(
          metaAdAccountId,
        );
        // TODO: Verificare firma corretta del metodo fetchInsightsRaw
        // data.metaInsights = await _metaClient!.fetchInsightsRaw(
        //   metaAdAccountId,
        //   {
        //     'time_range': {
        //       'since': DateTime.now().subtract(Duration(days: 30)).toIso8601String().split('T')[0],
        //       'until': DateTime.now().toIso8601String().split('T')[0],
        //     },
        //     'level': 'campaign',
        //     'fields': 'campaign_name,impressions,clicks,spend,cpc,cpm,ctr',
        //   },
        // );
      } catch (e) {
        log.e('ADS_SERVICE - Errore fetch Meta Ads', e);
      }
    }

    // Fetch Instagram
    if (_instagramClient != null && instagramUserId != null) {
      try {
        data.instagramMedia = await _instagramClient!.fetchMedia(
          instagramUserId,
        );
      } catch (e) {
        log.e('ADS_SERVICE - Errore fetch Instagram', e);
      }
    }

    // Fetch Google Ads
    if (_googleAdsClient != null && googleCustomerId != null) {
      try {
        // TODO: Verificare firma corretta del metodo fetchCampaignsRaw
        // data.googleCampaigns = await _googleAdsClient!.fetchCampaignsRaw(
        //   googleCustomerId,
        //   'SELECT campaign.id, campaign.name, metrics.impressions, metrics.clicks, metrics.cost_micros FROM campaign WHERE segments.date DURING LAST_30_DAYS',
        // );
      } catch (e) {
        log.e('ADS_SERVICE - Errore fetch Google Ads', e);
      }
    }

    // Fetch TikTok Ads
    if (_tiktokAdsClient != null && tiktokAdvertiserId != null) {
      try {
        data.tiktokCampaigns = await _tiktokAdsClient!.fetchCampaignsRaw(
          tiktokAdvertiserId,
        );
        data.tiktokReports = await _tiktokAdsClient!.fetchReportsRaw(
          tiktokAdvertiserId,
          {
            'start_date': DateTime.now()
                .subtract(Duration(days: 30))
                .toIso8601String()
                .split('T')[0],
            'end_date': DateTime.now().toIso8601String().split('T')[0],
            'metrics': ['spend', 'impressions', 'clicks', 'conversions'],
          },
        );
      } catch (e) {
        log.e('ADS_SERVICE - Errore fetch TikTok Ads', e);
      }
    }

    return data;
  }

  /// Avvia scheduler per aggiornamento automatico ogni X minuti
  void startAutoRefresh({
    required Duration interval,
    String? metaAdAccountId,
    String? googleCustomerId,
    String? tiktokAdvertiserId,
    String? instagramUserId,
  }) {
    _scheduler.start(
      interval: interval,
      onRefresh: () async {
        log.d('ADS_SERVICE - Auto-refresh dati ads...');
        final data = await fetchAllData(
          metaAdAccountId: metaAdAccountId,
          googleCustomerId: googleCustomerId,
          tiktokAdvertiserId: tiktokAdvertiserId,
          instagramUserId: instagramUserId,
        );

        // Notifica la UI
        onDataUpdated?.call(data);
      },
    );
  }

  /// Ferma lo scheduler
  void stopAutoRefresh() {
    _scheduler.stop();
  }

  /// Verifica se una piattaforma è connessa
  bool isConnected(String provider) {
    switch (provider) {
      case "meta":
        return _metaClient != null;
      case "google":
        return _googleAdsClient != null;
      case "tiktok":
        return _tiktokAdsClient != null;
      default:
        return false;
    }
  }

  /// Cleanup
  void dispose() {
    _scheduler.stop();
    // TODO: Rimuovere listener quando Logger sarà disponibile
    // Logger.removeListener((level, tag, message) {
    //   print('[$level] $tag: $message');
    // });
  }
}

/// Modello dati per contenere tutti i dati delle piattaforme
class AdsPlatformData {
  // Meta Ads
  dynamic metaCampaigns;
  dynamic metaInsights;

  // Instagram
  dynamic instagramMedia;

  // Google Ads
  dynamic googleCampaigns;

  // TikTok Ads
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

  /// Calcola metriche aggregate
  AdsMetrics getAggregateMetrics() {
    double totalSpend = 0.0;
    int totalImpressions = 0;
    int totalClicks = 0;
    int totalConversions = 0;

    // Aggrega Meta Ads
    if (metaInsights != null && metaInsights['data'] != null) {
      for (var insight in metaInsights['data']) {
        totalSpend +=
            double.tryParse(insight['spend']?.toString() ?? '0') ?? 0.0;
        totalImpressions +=
            int.tryParse(insight['impressions']?.toString() ?? '0') ?? 0;
        totalClicks += int.tryParse(insight['clicks']?.toString() ?? '0') ?? 0;
      }
    }

    // Aggrega Google Ads
    if (googleCampaigns != null) {
      // Parsing specifico per Google Ads query results
      // Dipende dalla struttura della risposta
    }

    // Aggrega TikTok Ads
    if (tiktokReports != null && tiktokReports['data'] != null) {
      for (var report in tiktokReports['data']) {
        totalSpend +=
            double.tryParse(report['spend']?.toString() ?? '0') ?? 0.0;
        totalImpressions +=
            int.tryParse(report['impressions']?.toString() ?? '0') ?? 0;
        totalClicks += int.tryParse(report['clicks']?.toString() ?? '0') ?? 0;
        totalConversions +=
            int.tryParse(report['conversions']?.toString() ?? '0') ?? 0;
      }
    }

    return AdsMetrics(
      totalSpend: totalSpend,
      totalImpressions: totalImpressions,
      totalClicks: totalClicks,
      totalConversions: totalConversions,
      ctr: totalImpressions > 0 ? (totalClicks / totalImpressions) * 100 : 0.0,
      cpc: totalClicks > 0 ? totalSpend / totalClicks : 0.0,
    );
  }
}

/// Metriche aggregate di tutte le piattaforme
class AdsMetrics {
  final double totalSpend;
  final int totalImpressions;
  final int totalClicks;
  final int totalConversions;
  final double ctr; // Click-through rate
  final double cpc; // Cost per click

  AdsMetrics({
    required this.totalSpend,
    required this.totalImpressions,
    required this.totalClicks,
    required this.totalConversions,
    required this.ctr,
    required this.cpc,
  });
}
