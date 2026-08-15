import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'inventory_quick_load_settings.dart';

class InventorySettingsTab extends StatefulWidget {
  const InventorySettingsTab({super.key});

  @override
  State<InventorySettingsTab> createState() => _InventorySettingsTabState();
}

class _InventorySettingsTabState extends State<InventorySettingsTab> {
  final _warehouseController = TextEditingController();
  final _roomController = TextEditingController();
  final _rackController = TextEditingController();
  final _shelfController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _didSeed = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didSeed) return;
    final settings = context.read<InventoryQuickLoadSettings>();
    _warehouseController.text = settings.warehouseOptions.join(', ');
    _roomController.text = settings.roomOptions.join(', ');
    _rackController.text = settings.rackOptions.join(', ');
    _shelfController.text = settings.shelfOptions.join(', ');
    _reasonController.text = settings.reasonOptions.join(', ');
    _didSeed = true;
  }

  @override
  void dispose() {
    _warehouseController.dispose();
    _roomController.dispose();
    _rackController.dispose();
    _shelfController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _saveOptions(InventoryQuickLoadSettings settings) async {
    setState(() => _saving = true);
    await settings.setWarehouseOptions(
      parseInventoryQuickLoadOptions(_warehouseController.text),
    );
    await settings.setRoomOptions(
      parseInventoryQuickLoadOptions(_roomController.text),
    );
    await settings.setRackOptions(
      parseInventoryQuickLoadOptions(_rackController.text),
    );
    await settings.setShelfOptions(
      parseInventoryQuickLoadOptions(_shelfController.text),
    );
    await settings.setReasonOptions(
      parseInventoryQuickLoadOptions(_reasonController.text),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opzioni carico rapido salvate')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryQuickLoadSettings>(
      builder: (context, settings, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Inventario MGWS',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Configura le scelte disponibili e i valori proposti nel Carico rapido.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Valori selezionabili',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Separa più valori con virgola, punto e virgola o una nuova riga. '
                            'Lascia vuoto un livello per disattivarlo e nasconderlo nel Carico rapido.',
                          ),
                          const SizedBox(height: 16),
                          _OptionsField(
                            controller: _warehouseController,
                            label: 'ID magazzini',
                            hint: '1, 2, 3',
                          ),
                          _OptionsField(
                            controller: _roomController,
                            label: 'Stanze',
                            hint: 'A, B, Retro',
                          ),
                          _OptionsField(
                            controller: _rackController,
                            label: 'Scaffali',
                            hint: '1, 2, Parete nord',
                          ),
                          _OptionsField(
                            controller: _shelfController,
                            label: 'Ripiani',
                            hint: '1, 2, Alto',
                          ),
                          _OptionsField(
                            controller: _reasonController,
                            label: 'Motivi carico',
                            hint: 'Carico merce, Carico scaffale',
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.icon(
                              onPressed: _saving
                                  ? null
                                  : () => _saveOptions(settings),
                              icon: _saving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: const Text('Salva opzioni'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Valori predefiniti',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              if (settings.warehouseEnabled)
                                _defaultSelector(
                                  label: 'Magazzino',
                                  options: settings.warehouseOptions,
                                  value: settings.defaultWarehouse,
                                  onChanged: (value) => settings.setDefaults(
                                    warehouse: value,
                                    room: settings.defaultRoom,
                                    rack: settings.defaultRack,
                                    shelf: settings.defaultShelf,
                                    reason: settings.defaultReason,
                                  ),
                                ),
                              if (settings.roomEnabled)
                                _defaultSelector(
                                  label: 'Stanza',
                                  options: settings.roomOptions,
                                  value: settings.defaultRoom,
                                  onChanged: (value) => settings.setDefaults(
                                    warehouse: settings.defaultWarehouse,
                                    room: value,
                                    rack: settings.defaultRack,
                                    shelf: settings.defaultShelf,
                                    reason: settings.defaultReason,
                                  ),
                                ),
                              if (settings.rackEnabled)
                                _defaultSelector(
                                  label: 'Scaffale',
                                  options: settings.rackOptions,
                                  value: settings.defaultRack,
                                  onChanged: (value) => settings.setDefaults(
                                    warehouse: settings.defaultWarehouse,
                                    room: settings.defaultRoom,
                                    rack: value,
                                    shelf: settings.defaultShelf,
                                    reason: settings.defaultReason,
                                  ),
                                ),
                              if (settings.shelfEnabled)
                                _defaultSelector(
                                  label: 'Ripiano',
                                  options: settings.shelfOptions,
                                  value: settings.defaultShelf,
                                  onChanged: (value) => settings.setDefaults(
                                    warehouse: settings.defaultWarehouse,
                                    room: settings.defaultRoom,
                                    rack: settings.defaultRack,
                                    shelf: value,
                                    reason: settings.defaultReason,
                                  ),
                                ),
                              _defaultSelector(
                                label: 'Motivo',
                                options: settings.reasonOptions,
                                value: settings.defaultReason,
                                allowUnset: false,
                                onChanged: (value) => settings.setDefaults(
                                  warehouse: settings.defaultWarehouse,
                                  room: settings.defaultRoom,
                                  rack: settings.defaultRack,
                                  shelf: settings.defaultShelf,
                                  reason: value,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _defaultSelector({
    required String label,
    required List<String> options,
    required String? value,
    required ValueChanged<String?> onChanged,
    bool allowUnset = true,
  }) {
    return SizedBox(
      width: 260,
      child: DropdownButtonFormField<String>(
        key: ValueKey('$label-$value-${options.length}'),
        initialValue: options.contains(value) ? value : null,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [
          if (allowUnset)
            const DropdownMenuItem<String>(value: null, child: Text('Nessuno')),
          for (final option in options)
            DropdownMenuItem<String>(value: option, child: Text(option)),
        ],
        onChanged: options.isEmpty && !allowUnset ? null : onChanged,
      ),
    );
  }
}

class _OptionsField extends StatelessWidget {
  const _OptionsField({
    required this.controller,
    required this.label,
    required this.hint,
  });

  final TextEditingController controller;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        minLines: 1,
        maxLines: 2,
        decoration: InputDecoration(labelText: label, hintText: hint),
      ),
    );
  }
}
