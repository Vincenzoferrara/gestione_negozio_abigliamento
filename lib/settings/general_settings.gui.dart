import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'cassa_settings.dart';

/// Impostazioni generali operative dell'app.
class GeneralSettingsTab extends StatefulWidget {
  const GeneralSettingsTab({super.key});

  @override
  State<GeneralSettingsTab> createState() => _GeneralSettingsTabState();
}

class _GeneralSettingsTabState extends State<GeneralSettingsTab> {
  late final TextEditingController _sedeController;

  @override
  void initState() {
    super.initState();
    _sedeController = TextEditingController(text: cassaSettings.sede);
  }

  @override
  void dispose() {
    _sedeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChangeNotifierProvider.value(
      value: cassaSettings,
      child: Consumer<CassaSettings>(
        builder: (context, settings, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Generale',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Impostazioni operative comuni a piu moduli.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _sedeController,
              decoration: const InputDecoration(
                labelText: 'Sede in uso (opzionale)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.store),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Text(
              'Usata da cassa e storico POS per indicare il negozio o punto '
              'vendita corrente. Se vuota, non viene salvata negli scontrini.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () async {
                await settings.setValori(sede: _sedeController.text);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Impostazioni generali salvate'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Salva'),
            ),
          ],
        ),
      ),
    );
  }
}
