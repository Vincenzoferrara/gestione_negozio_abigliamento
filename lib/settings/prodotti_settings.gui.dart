import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_settings.dart';

/// Tab delle impostazioni prodotti
class ProdottiSettingsTab extends StatelessWidget {
  const ProdottiSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettings>(
      builder: (context, settings, child) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader(context, 'Eliminazione'),
            _buildForceDeleteSwitch(context, settings),
            const SizedBox(height: 8),
            _buildConfirmDeleteSwitch(context, settings),
            const Divider(height: 32),
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
        secondary: Icon(
          Icons.warning,
          color: Theme.of(context).primaryColor,
        ),
        value: settings.confirmDelete,
        onChanged: (value) => settings.setConfirmDelete(value),
      ),
    );
  }
}
