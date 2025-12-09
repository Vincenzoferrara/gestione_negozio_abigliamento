// TikTok Ads Detail - Finestra dettagliata per TikTok Ads

import 'package:flutter/material.dart';
import 'ads_dashboard.code.dart';

/// Finestra dettagliata per visualizzare campagne e report TikTok Ads
class TikTokAdsDetailPage extends StatefulWidget {
  final AdsPlatformService adsService;
  final String? advertiserId;

  const TikTokAdsDetailPage({
    super.key,
    required this.adsService,
    this.advertiserId,
  });

  @override
  State<TikTokAdsDetailPage> createState() => _TikTokAdsDetailPageState();
}

class _TikTokAdsDetailPageState extends State<TikTokAdsDetailPage> {
  AdsPlatformData? _data;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!widget.adsService.isConnected("tiktok")) {
      setState(() {
        _errorMessage =
            "Non sei connesso a TikTok Ads. Effettua il login dalla dashboard principale.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await widget.adsService.fetchAllData(
        tiktokAdvertiserId: widget.advertiserId,
      );

      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Errore caricamento dati TikTok Ads: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.tiktok, size: 28),
            SizedBox(width: 8),
            Text("TikTok Ads - Dettagli"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadData,
            tooltip: "Ricarica dati",
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(_errorMessage!, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text("Riprova")),
          ],
        ),
      );
    }

    if (_data == null || _data!.tiktokCampaigns == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text("Nessun dato disponibile. Configura l'Advertiser ID."),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCampaignsSection(),
          const SizedBox(height: 24),
          if (_data!.tiktokReports != null) _buildReportsSection(),
        ],
      ),
    );
  }

  Widget _buildCampaignsSection() {
    final campaigns = _data!.tiktokCampaigns;
    final campaignList = campaigns['data'] as List<dynamic>? ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Campagne TikTok",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (campaignList.isEmpty)
              const Center(child: Text("Nessuna campagna trovata"))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: campaignList.length,
                itemBuilder: (context, index) {
                  final campaign = campaignList[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 2,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.black,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        campaign['campaign_name'] ?? 'N/A',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ID: ${campaign['campaign_id'] ?? 'N/A'}'),
                          Text(
                            'Obiettivo: ${campaign['objective_type'] ?? 'N/A'}',
                          ),
                        ],
                      ),
                      trailing: _buildCampaignStatusChip(campaign['status']),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignStatusChip(String? status) {
    Color color;
    IconData icon;

    switch (status?.toUpperCase()) {
      case 'ENABLE':
      case 'ACTIVE':
        color = Colors.green;
        icon = Icons.play_circle;
        break;
      case 'DISABLE':
      case 'PAUSED':
        color = Colors.orange;
        icon = Icons.pause_circle;
        break;
      default:
        color = Colors.grey;
        icon = Icons.info;
    }

    return Chip(
      avatar: Icon(icon, color: color, size: 16),
      label: Text(status ?? 'N/A', style: const TextStyle(fontSize: 12)),
      backgroundColor: color.withValues(alpha: 0.1),
    );
  }

  Widget _buildReportsSection() {
    final reports = _data!.tiktokReports;
    final reportsList = reports['data'] as List<dynamic>? ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Report & Metriche (Ultimi 30 giorni)",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (reportsList.isEmpty)
              const Center(child: Text("Nessun report disponibile"))
            else
              _buildReportsGrid(reportsList),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsGrid(List<dynamic> reports) {
    // Calcola totali
    double totalSpend = 0;
    int totalImpressions = 0;
    int totalClicks = 0;
    int totalConversions = 0;

    for (var report in reports) {
      totalSpend += double.tryParse(report['spend']?.toString() ?? '0') ?? 0;
      totalImpressions +=
          int.tryParse(report['impressions']?.toString() ?? '0') ?? 0;
      totalClicks += int.tryParse(report['clicks']?.toString() ?? '0') ?? 0;
      totalConversions +=
          int.tryParse(report['conversions']?.toString() ?? '0') ?? 0;
    }

    final ctr = totalImpressions > 0
        ? (totalClicks / totalImpressions) * 100
        : 0;
    final cpc = totalClicks > 0 ? totalSpend / totalClicks : 0;

    return Column(
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildMetricCard(
              "Spesa Totale",
              "€${totalSpend.toStringAsFixed(2)}",
              Icons.euro,
              Colors.red,
            ),
            _buildMetricCard(
              "Impressioni",
              totalImpressions.toString(),
              Icons.visibility,
              Colors.blue,
            ),
            _buildMetricCard(
              "Click",
              totalClicks.toString(),
              Icons.touch_app,
              Colors.green,
            ),
            _buildMetricCard(
              "Conversioni",
              totalConversions.toString(),
              Icons.shopping_cart,
              Colors.orange,
            ),
            _buildMetricCard(
              "CTR",
              "${ctr.toStringAsFixed(2)}%",
              Icons.percent,
              Colors.purple,
            ),
            _buildMetricCard(
              "CPC",
              "€${cpc.toStringAsFixed(2)}",
              Icons.monetization_on,
              Colors.teal,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// Estensione per icona TikTok
extension TikTokIcon on Icons {
  static const IconData tiktok = IconData(0xe900, fontFamily: 'MaterialIcons');
}
