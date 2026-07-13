import 'package:flutter/material.dart';

import 'updater.code.dart';

class UpdaterPage extends StatefulWidget {
  const UpdaterPage({super.key});

  @override
  State<UpdaterPage> createState() => _UpdaterPageState();
}

class _UpdaterPageState extends State<UpdaterPage> {
  late final UpdaterLogic _logic;

  @override
  void initState() {
    super.initState();
    _logic = UpdaterLogic()..addListener(_onLogicChanged);
    _logic.init();
  }

  @override
  void dispose() {
    _logic.removeListener(_onLogicChanged);
    _logic.dispose();
    super.dispose();
  }

  void _onLogicChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canInstall = _logic.status == UpdaterStatus.updateAvailable;

    return Scaffold(
      appBar: AppBar(title: const Text('Aggiornamenti')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_statusIcon(), color: _statusColor(theme)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _logic.message,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(label: 'Piattaforma', value: _logic.platformLabel),
                  _InfoRow(
                    label: 'Versione installata',
                    value: _logic.installedVersion.isEmpty
                        ? 'Caricamento...'
                        : _logic.installedVersion,
                  ),
                  _InfoRow(label: 'Origine update', value: _logic.updateUrl),
                  if (_logic.error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _logic.error!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                  if (_logic.isBusy) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: _logic.isSupported && !_logic.isBusy
                    ? _logic.checkForUpdates
                    : null,
                icon: const Icon(Icons.search),
                label: const Text('Controlla aggiornamenti'),
              ),
              FilledButton.tonalIcon(
                onPressed: canInstall && !_logic.isBusy
                    ? _logic.installAndRestart
                    : null,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Installa e riavvia'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Canali gestiti'),
              subtitle: Text(
                'Velopack gestisce Windows e Linux AppImage. Android, iOS, apt e AUR sono gestiti da canali separati.',
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _statusIcon() {
    switch (_logic.status) {
      case UpdaterStatus.updateAvailable:
        return Icons.system_update;
      case UpdaterStatus.upToDate:
        return Icons.check_circle_outline;
      case UpdaterStatus.error:
        return Icons.error_outline;
      case UpdaterStatus.unsupported:
        return Icons.block;
      case UpdaterStatus.checking:
      case UpdaterStatus.installing:
        return Icons.sync;
      case UpdaterStatus.idle:
        return Icons.update;
    }
  }

  Color _statusColor(ThemeData theme) {
    switch (_logic.status) {
      case UpdaterStatus.updateAvailable:
        return theme.colorScheme.primary;
      case UpdaterStatus.upToDate:
        return Colors.green;
      case UpdaterStatus.error:
        return theme.colorScheme.error;
      case UpdaterStatus.unsupported:
        return theme.disabledColor;
      case UpdaterStatus.checking:
      case UpdaterStatus.installing:
      case UpdaterStatus.idle:
        return theme.colorScheme.secondary;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
