import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'cassa_settings.dart';
import '../theme/theme.dart';
import '../traduzioni/estensioni.dart';
import '../traduzioni/locale_settings.dart';

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
          padding: context.spacing.iL,
          children: [
            Text(
              context.l10n.settingsGeneral,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.settingsGeneralDescription,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            const _SezioneLingua(),
            const SizedBox(height: 20),
            TextField(
              controller: _sedeController,
              decoration: InputDecoration(
                labelText: context.l10n.settingsGeneralSede,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.store),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.settingsGeneralSedeDescription,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () async {
                await settings.setValori(sede: _sedeController.text);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.settingsGeneralSaved),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.save),
              label: Text(context.l10n.commonSave),
            ),
          ],
        ),
      ),
    );
  }
}

/// Selettore della lingua dell'interfaccia.
///
/// La prima voce lascia l'app seguire il sistema operativo, che e il default.
/// Cambiare lingua ricostruisce l'intera interfaccia senza riavviare l'app.
class _SezioneLingua extends StatelessWidget {
  const _SezioneLingua();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final impostazioni = context.watch<LocaleSettings>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.translate, size: 18),
            const SizedBox(width: 8),
            Text(
              context.l10n.settingsLanguage,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.settingsLanguageDescription,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        RadioGroup<Locale?>(
          groupValue: impostazioni.lingua,
          onChanged: impostazioni.impostaLingua,
          child: Column(
            children: [
              RadioListTile<Locale?>(
                value: LocaleSettings.sistema,
                title: Text(context.l10n.settingsLanguageSystem),
                // Con il sistema l'utente non vede a cosa si risolve la scelta,
                // quindi mostriamo la lingua effettiva accanto all'opzione.
                subtitle: Text(
                  impostazioni.nomeLinguaAttiva,
                  style: theme.textTheme.bodySmall,
                ),
                contentPadding: EdgeInsets.zero,
              ),
              ...LocaleSettings.supportate.map(
                (locale) => RadioListTile<Locale?>(
                  value: locale,
                  title: Text(
                    LocaleSettings.nomiNativi[locale.languageCode] ??
                        locale.languageCode,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
