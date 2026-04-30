import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_settings.dart';

class ShortcutsSettingsTab extends StatelessWidget {
  const ShortcutsSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettings>(
      builder: (context, settings, child) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Shortcut prodotti_gestisci',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            const SizedBox(height: 12),
            _ShortcutField(
              label: 'Toggle edit',
              value: settings.shortcutToggleEdit,
              onSave: settings.setShortcutToggleEdit,
            ),
            _ShortcutField(
              label: 'Salva',
              value: settings.shortcutSave,
              onSave: settings.setShortcutSave,
            ),
            _ShortcutField(
              label: 'Seleziona tutti filtrati',
              value: settings.shortcutSelectAll,
              onSave: settings.setShortcutSelectAll,
            ),
            _ShortcutField(
              label: 'Elimina selezionati',
              value: settings.shortcutDelete,
              onSave: settings.setShortcutDelete,
            ),
            _ShortcutField(
              label: 'Annulla/esci',
              value: settings.shortcutEscape,
              onSave: settings.setShortcutEscape,
            ),
            const SizedBox(height: 12),
            Card(
              child: SwitchListTile(
                title: const Text('Eliminazione definitiva di default'),
                subtitle: const Text(
                  'Disattivo = soft delete (cestino), attivo = hard delete.',
                ),
                value: settings.forceDelete,
                onChanged: (v) => settings.setForceDelete(v),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: settings.resetShortcutsToDefault,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reset shortcut default'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ShortcutField extends StatefulWidget {
  final String label;
  final String value;
  final Future<void> Function(String value) onSave;

  const _ShortcutField({
    required this.label,
    required this.value,
    required this.onSave,
  });

  @override
  State<_ShortcutField> createState() => _ShortcutFieldState();
}

class _ShortcutFieldState extends State<_ShortcutField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _ShortcutField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(widget.label),
        subtitle: TextField(
          controller: _controller,
          decoration: const InputDecoration(
            isDense: true,
            hintText: 'Es: Ctrl+S, Delete, Esc',
          ),
          onSubmitted: (value) => widget.onSave(value),
        ),
        trailing: IconButton(
          onPressed: () => widget.onSave(_controller.text),
          icon: const Icon(Icons.save_outlined),
          tooltip: 'Salva shortcut',
        ),
      ),
    );
  }
}
