import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_settings.dart';
import '../background_removal_cli/background_removal_desktop_page.dart';

class ProdottiSettingsTab extends StatefulWidget {
  const ProdottiSettingsTab({super.key});

  @override
  State<ProdottiSettingsTab> createState() => _ProdottiSettingsTabState();
}

class _ProdottiSettingsTabState extends State<ProdottiSettingsTab> {
  late final TextEditingController _widthController;
  late final TextEditingController _heightController;
  late final TextEditingController _bgApiEndpointController;
  late final TextEditingController _bgApiKeyController;
  bool _didInitControllers = false;

  @override
  void initState() {
    super.initState();
    _widthController = TextEditingController();
    _heightController = TextEditingController();
    _bgApiEndpointController = TextEditingController();
    _bgApiKeyController = TextEditingController();
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    _bgApiEndpointController.dispose();
    _bgApiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettings>(
      builder: (context, settings, child) {
        if (!_didInitControllers) {
          _widthController.text = settings.imageResizeWidth.toString();
          _heightController.text = settings.imageResizeHeight.toString();
          _bgApiEndpointController.text = settings.imageBackgroundApiEndpoint;
          _bgApiKeyController.text = settings.imageBackgroundApiKey;
          _didInitControllers = true;
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader(context, 'Eliminazione'),
            _buildForceDeleteSwitch(context, settings),
            const SizedBox(height: 8),
            _buildConfirmDeleteSwitch(context, settings),
            const SizedBox(height: 8),
            _buildAttributeCaseModeCard(context, settings),
            const SizedBox(height: 8),
            _buildPersistFiltersSwitch(context, settings),
            const SizedBox(height: 8),
            _buildHideOutOfStockSwitch(context, settings),
            const Divider(height: 32),
            _buildSectionHeader(context, 'Immagini (default)'),
            _buildImageResizeSwitch(context, settings),
            const SizedBox(height: 8),
            _buildImageBackgroundSwitch(context, settings),
            const SizedBox(height: 8),
            _buildImageBackgroundModeCard(context, settings),
            const SizedBox(height: 8),
            if (settings.imageBackgroundMode == 'api')
              _buildImageBackgroundApiCard(context, settings),
            if (settings.imageBackgroundMode == 'api')
              const SizedBox(height: 8),
            _buildImageFormatSwitch(context, settings),
            const SizedBox(height: 8),
            _buildImageFormatDropdown(context, settings),
            const SizedBox(height: 8),
            _buildResizeValuesCard(context, settings),
            const SizedBox(height: 8),
            _buildImageTesterCard(context),
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

  Widget _buildImageResizeSwitch(BuildContext context, AppSettings settings) {
    return Card(
      child: SwitchListTile(
        title: const Text('Resize immagine predefinito'),
        subtitle: const Text('Attivo in creazione prodotto'),
        value: settings.imageResizeEnabled,
        onChanged: (value) => settings.setImageResizeEnabled(value),
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

  Widget _buildImageBackgroundSwitch(
    BuildContext context,
    AppSettings settings,
  ) {
    return Card(
      child: SwitchListTile(
        title: const Text('Rimuovi background predefinito'),
        subtitle: const Text('Attivo in creazione prodotto'),
        value: settings.imageBackgroundRemoveEnabled,
        onChanged: (value) => settings.setImageBackgroundRemoveEnabled(value),
      ),
    );
  }

  Widget _buildImageBackgroundModeCard(
    BuildContext context,
    AppSettings settings,
  ) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.layers_clear),
        title: const Text('Modalita scontorno'),
        subtitle: DropdownButtonFormField<String>(
          initialValue: settings.imageBackgroundMode,
          decoration: const InputDecoration(isDense: true),
          items: const [
            DropdownMenuItem(
              value: 'auto',
              child: Text('Automatico (consigliato)'),
            ),
            DropdownMenuItem(
              value: 'local',
              child: Text('Locale ONNX (image_background_remover)'),
            ),
            DropdownMenuItem(
              value: 'api',
              child: Text('API esterna (con fallback locale)'),
            ),
          ],
          onChanged: (value) {
            if (value == null) return;
            settings.setImageBackgroundMode(value);
          },
        ),
      ),
    );
  }

  Widget _buildImageBackgroundApiCard(
    BuildContext context,
    AppSettings settings,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configurazione API scontorno',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bgApiEndpointController,
              decoration: const InputDecoration(
                labelText: 'Endpoint',
                isDense: true,
              ),
              onFieldSubmitted: (value) {
                settings.setImageBackgroundApiEndpoint(value);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bgApiKeyController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'API Key / Bearer token',
                isDense: true,
              ),
              onFieldSubmitted: (value) {
                settings.setImageBackgroundApiKey(value);
              },
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () async {
                  await settings.setImageBackgroundApiEndpoint(
                    _bgApiEndpointController.text,
                  );
                  await settings.setImageBackgroundApiKey(
                    _bgApiKeyController.text,
                  );
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Salva API'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageFormatSwitch(BuildContext context, AppSettings settings) {
    return Card(
      child: SwitchListTile(
        title: const Text('Cambio formato predefinito'),
        subtitle: const Text('Attivo in creazione prodotto'),
        value: settings.imageFormatChangeEnabled,
        onChanged: (value) => settings.setImageFormatChangeEnabled(value),
      ),
    );
  }

  Widget _buildImageFormatDropdown(BuildContext context, AppSettings settings) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.image),
        title: const Text('Formato output predefinito'),
        subtitle: DropdownButtonFormField<String>(
          initialValue: settings.imageOutputFormat,
          decoration: const InputDecoration(isDense: true),
          items: const [
            DropdownMenuItem(value: 'webp', child: Text('WEBP')),
            DropdownMenuItem(value: 'jpg', child: Text('JPG')),
            DropdownMenuItem(value: 'png', child: Text('PNG')),
          ],
          onChanged: (value) {
            if (value == null) return;
            settings.setImageOutputFormat(value);
          },
        ),
      ),
    );
  }

  Widget _buildResizeValuesCard(BuildContext context, AppSettings settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dimensioni resize predefinite',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _widthController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Larghezza',
                      isDense: true,
                    ),
                    onFieldSubmitted: (value) {
                      final parsed = int.tryParse(value.trim());
                      if (parsed != null) {
                        settings.setImageResizeWidth(parsed);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _heightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Altezza',
                      isDense: true,
                    ),
                    onFieldSubmitted: (value) {
                      final parsed = int.tryParse(value.trim());
                      if (parsed != null) {
                        settings.setImageResizeHeight(parsed);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Suggerimento: premi invio nel campo per salvare.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageTesterCard(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.science_outlined),
        title: const Text('Tester desktop binary'),
        subtitle: const Text('Pipeline locale con motore CLI bundlato'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const BackgroundRemovalDesktopPage(),
            ),
          );
        },
      ),
    );
  }
}
