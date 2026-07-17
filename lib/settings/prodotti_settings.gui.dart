import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_settings.dart';
import 'prodotti_image_settings.dart';

class ProdottiSettingsTab extends StatefulWidget {
  const ProdottiSettingsTab({super.key});

  @override
  State<ProdottiSettingsTab> createState() => _ProdottiSettingsTabState();
}

class _ProdottiSettingsTabState extends State<ProdottiSettingsTab> {
  late final TextEditingController _widthController;
  late final TextEditingController _heightController;
  bool _didInitControllers = false;

  @override
  void initState() {
    super.initState();
    _widthController = TextEditingController();
    _heightController = TextEditingController();
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppSettings, ProductImageWarningSettings>(
      builder: (context, appSettings, imageSettings, child) {
        if (!_didInitControllers) {
          _widthController.text = imageSettings.thresholdWidth.toString();
          _heightController.text = imageSettings.thresholdHeight.toString();
          _didInitControllers = true;
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader(context, 'Eliminazione'),
            _buildForceDeleteSwitch(context, appSettings),
            const SizedBox(height: 8),
            _buildConfirmDeleteSwitch(context, appSettings),
            const SizedBox(height: 8),
            _buildAttributeCaseModeCard(context, appSettings),
            const SizedBox(height: 8),
            _buildPersistFiltersSwitch(context, appSettings),
            const SizedBox(height: 8),
            _buildHideOutOfStockSwitch(context, appSettings),
            const Divider(height: 32),
            _buildSectionHeader(context, 'Immagini prodotto'),
            _buildImageWarningSwitch(context, imageSettings),
            const SizedBox(height: 8),
            _buildWarningThresholdsCard(context, imageSettings),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildForceDeleteSwitch(BuildContext context, AppSettings settings) {
    return Card(
      child: SwitchListTile(
        title: const Text('Eliminazione definitiva'),
        subtitle: Text(
          settings.forceDelete
              ? 'Gli elementi eliminati non andranno nel cestino'
              : 'Gli elementi eliminati andranno nel cestino',
        ),
        secondary: Icon(
          settings.forceDelete ? Icons.delete_forever : Icons.delete,
          color: Theme.of(context).primaryColor,
        ),
        value: settings.forceDelete,
        onChanged: (value) => settings.setForceDelete(value),
      ),
    );
  }

  Widget _buildConfirmDeleteSwitch(BuildContext context, AppSettings settings) {
    return Card(
      child: SwitchListTile(
        title: const Text('Richiedi conferma'),
        subtitle: Text(
          settings.confirmDelete
              ? 'Mostra dialog di conferma prima di eliminare'
              : 'Elimina direttamente senza conferma',
        ),
        secondary: Icon(Icons.warning, color: Theme.of(context).primaryColor),
        value: settings.confirmDelete,
        onChanged: (value) => settings.setConfirmDelete(value),
      ),
    );
  }

  Widget _buildAttributeCaseModeCard(
    BuildContext context,
    AppSettings settings,
  ) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.text_fields),
        title: const Text('Formato testo nuovi parametri'),
        subtitle: DropdownButtonFormField<String>(
          initialValue: settings.attributeCaseMode,
          decoration: const InputDecoration(isDense: true),
          items: const [
            DropdownMenuItem(value: 'upper', child: Text('Grande (MAIUSCOLO)')),
            DropdownMenuItem(
              value: 'lower',
              child: Text('Piccolo (minuscolo)'),
            ),
          ],
          onChanged: (value) {
            if (value == null) return;
            settings.setAttributeCaseMode(value);
          },
        ),
      ),
    );
  }

  Widget _buildPersistFiltersSwitch(
    BuildContext context,
    AppSettings settings,
  ) {
    return Card(
      child: SwitchListTile(
        title: const Text('Mantieni filtri in Prodotti > Gestisci'),
        subtitle: Text(
          settings.persistProductFilters
              ? 'I filtri restano attivi quando riapri la pagina'
              : 'Al refresh o riapertura i filtri vengono azzerati',
        ),
        secondary: Icon(
          Icons.filter_alt,
          color: Theme.of(context).primaryColor,
        ),
        value: settings.persistProductFilters,
        onChanged: (value) => settings.setPersistProductFilters(value),
      ),
    );
  }

  Widget _buildHideOutOfStockSwitch(
    BuildContext context,
    AppSettings settings,
  ) {
    return Card(
      child: SwitchListTile(
        title: const Text('Nascondi esauriti nella lista prodotti'),
        subtitle: const Text("Ricorda la scelta e la ripristina all'apertura"),
        secondary: Icon(
          Icons.visibility_off,
          color: Theme.of(context).primaryColor,
        ),
        value: settings.hideOutOfStockProducts,
        onChanged: (value) => settings.setHideOutOfStockProducts(value),
      ),
    );
  }

  Widget _buildImageWarningSwitch(
    BuildContext context,
    ProductImageWarningSettings settings,
  ) {
    return Card(
      child: SwitchListTile(
        title: const Text('Avvisa immagini oltre soglia'),
        subtitle: Text(
          settings.warningsEnabled
              ? 'Mostra un avviso informativo sulle foto troppo grandi'
              : 'Non mostra avvisi sulle dimensioni delle foto',
        ),
        secondary: Icon(
          Icons.warning_amber_outlined,
          color: Theme.of(context).primaryColor,
        ),
        value: settings.warningsEnabled,
        onChanged: (value) => settings.setWarningsEnabled(value),
      ),
    );
  }

  Widget _buildWarningThresholdsCard(
    BuildContext context,
    ProductImageWarningSettings settings,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Soglie dimensioni avviso',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Questi valori non ridimensionano e non convertono le immagini: servono solo per evidenziare le foto che superano le dimensioni indicate.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _widthController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Larghezza soglia',
                      suffixText: 'px',
                      isDense: true,
                    ),
                    onFieldSubmitted: (value) {
                      final parsed = int.tryParse(value.trim());
                      if (parsed != null) settings.setThresholdWidth(parsed);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _heightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Altezza soglia',
                      suffixText: 'px',
                      isDense: true,
                    ),
                    onFieldSubmitted: (value) {
                      final parsed = int.tryParse(value.trim());
                      if (parsed != null) settings.setThresholdHeight(parsed);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () async {
                  final width = int.tryParse(_widthController.text.trim());
                  final height = int.tryParse(_heightController.text.trim());
                  if (width != null) await settings.setThresholdWidth(width);
                  if (height != null) await settings.setThresholdHeight(height);
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Salva soglie'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
