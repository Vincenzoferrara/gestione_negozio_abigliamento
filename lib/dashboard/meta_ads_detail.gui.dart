// Meta Ads Detail - Finestra dettagliata per Meta Ads (Facebook/Instagram)

import 'package:flutter/material.dart';
import 'ads_dashboard.code.dart';

/// Finestra dettagliata per visualizzare campagne e insights Meta Ads
class MetaAdsDetailPage extends StatefulWidget {
  final AdsPlatformService adsService;
  final String? adAccountId;

  const MetaAdsDetailPage({
    super.key,
    required this.adsService,
    this.adAccountId,
  });

  @override
  State<MetaAdsDetailPage> createState() => _MetaAdsDetailPageState();
}

class _MetaAdsDetailPageState extends State<MetaAdsDetailPage> {
  AdsPlatformData? _data;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!widget.adsService.isConnected("meta")) {
      setState(() {
        _errorMessage =
            "Non sei connesso a Meta Ads. Effettua il login dalla dashboard principale.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await widget.adsService.fetchAllData(
        metaAdAccountId: widget.adAccountId,
      );

      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Errore caricamento dati Meta Ads: $e";
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
            Icon(Icons.facebook, color: Colors.blue),
            SizedBox(width: 8),
            Text("Meta Ads - Dettagli"),
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

    if (_data == null || _data!.metaCampaigns == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text("Nessun dato disponibile. Configura l'Ad Account ID."),
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
          if (_data!.metaInsights != null) _buildInsightsSection(),
        ],
      ),
    );
  }

  Widget _buildCampaignsSection() {
    final campaigns = _data!.metaCampaigns;
    final campaignList = campaigns['data'] as List<dynamic>? ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Campagne Attive",
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
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Text('${index + 1}'),
                      ),
                      title: Text(campaign['name'] ?? 'N/A'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ID: ${campaign['id'] ?? 'N/A'}'),
                          Text('Status: ${campaign['status'] ?? 'N/A'}'),
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
      case 'ACTIVE':
        color = Colors.green;
        icon = Icons.play_circle;
        break;
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
      label: Text(status ?? 'N/A'),
      backgroundColor: color.withValues(alpha: 0.1),
    );
  }

  Widget _buildInsightsSection() {
    final insights = _data!.metaInsights;
    final insightsList = insights['data'] as List<dynamic>? ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Insights & Metriche",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (insightsList.isEmpty)
              const Center(child: Text("Nessun insight disponibile"))
            else
              _buildInsightsTable(insightsList),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsTable(List<dynamic> insights) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Campagna')),
          DataColumn(label: Text('Impressioni')),
          DataColumn(label: Text('Click')),
          DataColumn(label: Text('Spesa')),
          DataColumn(label: Text('CPC')),
          DataColumn(label: Text('CTR')),
        ],
        rows: insights.map((insight) {
          return DataRow(
            cells: [
              DataCell(Text(insight['campaign_name']?.toString() ?? 'N/A')),
              DataCell(Text(insight['impressions']?.toString() ?? '0')),
              DataCell(Text(insight['clicks']?.toString() ?? '0')),
              DataCell(Text('€${insight['spend']?.toString() ?? '0'}')),
              DataCell(Text('€${insight['cpc']?.toString() ?? '0'}')),
              DataCell(Text('${insight['ctr']?.toString() ?? '0'}%')),
            ],
          );
        }).toList(),
      ),
    );
  }
}
