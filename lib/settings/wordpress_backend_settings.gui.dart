import 'package:flutter/material.dart';

class WordPressBackendSettingsTab extends StatelessWidget {
  const WordPressBackendSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Backend WordPress',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          'L\'app usa WooCommerce direttamente per tutte le API esposte dal plugin. '
          'MGWS contiene internamente inventory, loyalty e le funzioni custom.',
        ),
        const SizedBox(height: 16),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('WooCommerce diretto + MGWS nativo'),
          subtitle: Text(
            'Non esiste scelta provider lato app: nessun failback verso plugin terzi.',
          ),
        ),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Stato: WooCommerce resta intoccato e viene solo consumato via API. '
              'Tutto cio che non appartiene a WooCommerce deve stare dentro MGWS.',
            ),
          ),
        ),
      ],
    );
  }
}
