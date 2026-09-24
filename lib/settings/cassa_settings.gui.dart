import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'cassa_settings.dart';

/// Vista impostazioni del modulo Cassa: nome/numero cassa fisica e turno.
class CassaSettingsTab extends StatefulWidget {
  const CassaSettingsTab({super.key});

  @override
  State<CassaSettingsTab> createState() => _CassaSettingsTabState();
}

class _CassaSettingsTabState extends State<CassaSettingsTab> {
  late final TextEditingController _cassaController;

  @override
  void initState() {
    super.initState();
    _cassaController = TextEditingController(text: cassaSettings.nomeCassa);
  }

  @override
  void dispose() {
    _cassaController.dispose();
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
              'Cassa fisica',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nome o numero della cassa (es. Cassa 1). Opzionale: serve solo '
              'a distinguere le giornate quando ci sono piu casse. Se vuoto, '
              'lo storico usa un nome neutro.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cassaController,
              decoration: const InputDecoration(
                labelText: 'Nome/numero cassa (opzionale)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.point_of_sale),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: settings.turnoObbligatorio,
              title: const Text('Turno cassa obbligatorio'),
              subtitle: const Text(
                'Se disattivato, apri/chiudi turno restano disponibili ma non '
                'bloccano piu inserimento prodotti e checkout.',
              ),
              secondary: const Icon(Icons.lock_clock),
              onChanged: (value) async {
                try {
                  await settings.setTurnoObbligatorio(value);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value
                              ? 'Turno cassa obbligatorio attivato'
                              : 'Turno cassa obbligatorio disattivato',
                        ),
                      ),
                    );
                  }
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Impostazione non salvata: $error'),
                      ),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () async {
                await settings.setValori(nomeCassa: _cassaController.text);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Impostazioni cassa salvate')),
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
