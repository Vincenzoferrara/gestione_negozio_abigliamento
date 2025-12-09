// Google Ads Detail - Finestra dettagliata per Google Ads

import 'package:flutter/material.dart';
import 'ads_dashboard.code.dart';

/// Finestra dettagliata per visualizzare campagne Google Ads
class GoogleAdsDetailPage extends StatefulWidget {
  final AdsPlatformService adsService;
  final String? customerId;

  const GoogleAdsDetailPage({
    super.key,
    required this.adsService,
    this.customerId,
  });

  @override
  State<GoogleAdsDetailPage> createState() => _GoogleAdsDetailPageState();
}

class _GoogleAdsDetailPageState extends State<GoogleAdsDetailPage> {
  AdsPlatformData? _data;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!widget.adsService.isConnected("google")) {
      setState(() {
        _errorMessage =
            "Non sei connesso a Google Ads. Effettua il login dalla dashboard principale.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await widget.adsService.fetchAllData(
        googleCustomerId: widget.customerId,
      );

      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Errore caricamento dati Google Ads: $e";
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
            Icon(Icons.g_mobiledata, color: Colors.red, size: 32),
            SizedBox(width: 8),
            Text("Google Ads - Dettagli"),
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

    if (_data == null || _data!.googleCampaigns == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text("Nessun dato disponibile. Configura il Customer ID."),
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
          _buildMetricsOverview(),
        ],
      ),
    );
  }

  Widget _buildCampaignsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Campagne Google Ads",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Column(
                children: [
                  Icon(Icons.construction, size: 48, color: Colors.orange),
                  SizedBox(height: 8),
                  Text("Dati campagne Google Ads in arrivo"),
                  SizedBox(height: 4),
                  Text(
                    "Implementazione query Google Ads API in corso",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Metriche Prestazioni",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildMetricCard(
                  "Impressioni",
                  "0",
                  Icons.visibility,
                  Colors.blue,
                ),
                _buildMetricCard("Click", "0", Icons.touch_app, Colors.green),
                _buildMetricCard("Costo", "€0.00", Icons.euro, Colors.red),
                _buildMetricCard(
                  "Conversioni",
                  "0",
                  Icons.shopping_cart,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
