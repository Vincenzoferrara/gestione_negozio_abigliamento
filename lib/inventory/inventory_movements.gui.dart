import 'package:flutter/material.dart';

import '../login/jwt_api/query_mgws/query_mgws_inventory.dart';
import '../reuse_class/datagridview/datagridview.code.dart';
import '../reuse_class/datagridview/datagridview.gui.dart';
import '../theme/theme.dart';
import 'inventory.code.dart';
import 'inventory_movements_detail.gui.dart';

class InventoryMovementLedgerPanel extends StatefulWidget {
  InventoryMovementLedgerPanel({
    super.key,
    InventoryMovementController? controller,
  }) : controller = controller ?? InventoryMovementController();

  final InventoryMovementController controller;

  @override
  State<InventoryMovementLedgerPanel> createState() =>
      _InventoryMovementLedgerPanelState();
}

class _InventoryMovementLedgerPanelState
    extends State<InventoryMovementLedgerPanel> {
  final _productController = TextEditingController();
  final _variationController = TextEditingController();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _sourceController = TextEditingController();
  final _operatorController = TextEditingController();
  final _reasonController = TextEditingController();
  final _effectController = TextEditingController();
  InventoryActionFeedback? _feedback;
  MgwsMovement? _selected;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _productController.dispose();
    _variationController.dispose();
    _fromController.dispose();
    _toController.dispose();
    _sourceController.dispose();
    _operatorController.dispose();
    _reasonController.dispose();
    _effectController.dispose();
    super.dispose();
  }

  InventoryMovementFilterForm _form() => InventoryMovementFilterForm(
    productIdText: _productController.text,
    variationIdText: _variationController.text,
    dateFromText: _fromController.text,
    dateToText: _toController.text,
    sourceTypeText: _sourceController.text,
    operatorUserIdText: _operatorController.text,
    reasonCodeText: _reasonController.text,
    stockEffectText: _effectController.text,
  );

  Future<void> _load() async {
    setState(() => _loading = true);
    final feedback = await widget.controller.load(_form());
    if (!mounted) return;
    setState(() {
      _feedback = feedback;
      _loading = false;
      final movements = widget.controller.movements;
      if (_selected == null && movements.isNotEmpty)
        _selected = movements.first;
      if (_selected != null &&
          !movements.any((item) => item.id == _selected!.id)) {
        _selected = movements.isEmpty ? null : movements.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorExtension>()!;
    return Card(
      key: const ValueKey('inventory-movements-panel'),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.timeline, color: theme.colorScheme.primary),
                title: Text(
                  'Movimenti stock MGWS',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Text(
                  'Ledger autorevole in sola lettura: quick load, POS, ricezioni, conte, reconcile e RFID quando MGWS li espone.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.subtitleColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _filters(),
              const SizedBox(height: 12),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (widget.controller.movements.isEmpty)
                _empty(colors)
              else
                SizedBox(height: 270, child: _grid()),
              const SizedBox(height: 12),
              InventoryMovementDetailPanel(movement: _selected),
              const SizedBox(height: 12),
              if (_feedback != null)
                InventoryMovementFeedback(feedback: _feedback!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filters() => Wrap(
    spacing: 12,
    runSpacing: 12,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      _field(
        _productController,
        'Product ID',
        'inventory-movement-product-field',
      ),
      _field(
        _variationController,
        'Variation ID',
        'inventory-movement-variation-field',
      ),
      _field(_fromController, 'Da data', 'inventory-movement-from-field'),
      _field(_toController, 'A data', 'inventory-movement-to-field'),
      _field(_sourceController, 'Source', 'inventory-movement-source-field'),
      _field(
        _operatorController,
        'Operatore',
        'inventory-movement-operator-field',
      ),
      _field(_reasonController, 'Reason', 'inventory-movement-reason-field'),
      _field(_effectController, 'Effetto', 'inventory-movement-effect-field'),
      OutlinedButton.icon(
        key: const ValueKey('inventory-movement-refresh'),
        onPressed: _loading ? null : _load,
        icon: const Icon(Icons.refresh),
        label: const Text('Aggiorna movimenti'),
      ),
    ],
  );

  Widget _grid() => DataGridView<MgwsMovement>(
    columns: const [
      DataGridViewColumn(id: 'time', label: 'Data', width: 180),
      DataGridViewColumn(id: 'product', label: 'Prodotto/Variante', width: 190),
      DataGridViewColumn(id: 'delta', label: 'Delta', width: 90, numeric: true),
      DataGridViewColumn(
        id: 'stock',
        label: 'Stock',
        width: 130,
        numeric: true,
      ),
      DataGridViewColumn(id: 'source', label: 'Origine', width: 150),
      DataGridViewColumn(id: 'reason', label: 'Motivo', width: 160),
    ],
    rows: [for (final movement in widget.controller.movements) _row(movement)],
    selectedRowId: _selected?.id.toString(),
    onRowSelected: (movement) => setState(() => _selected = movement),
    onRowDoubleTap: (movement) => setState(() => _selected = movement),
  );

  DataGridViewRowData<MgwsMovement> _row(MgwsMovement movement) {
    final colors = Theme.of(context).extension<AppColorExtension>()!;
    final tone = movement.quantityDelta >= 0
        ? colors.successColor
        : colors.errorColorStatus;
    return DataGridViewRowData(
      id: movement.id.toString(),
      value: movement,
      foregroundColor: tone,
      cells: {
        'time': Text(movement.occurredAtGmt),
        'product': Text(
          'Prodotto #${movement.productId} / Variante ${movement.variationId}',
        ),
        'delta': Text(movementSigned(movement.quantityDelta)),
        'stock': Text(
          '${movementStock(movement.stockBefore)} -> ${movementStock(movement.stockAfter)}',
        ),
        'source': Text('${movement.sourceType} #${movement.sourceId}'),
        'reason': Text(movement.reasonCode),
      },
    );
  }

  Widget _field(TextEditingController controller, String label, String key) {
    return SizedBox(
      width: 180,
      child: TextField(
        key: ValueKey(key),
        controller: controller,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _empty(AppColorExtension colors) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: colors.priceBackground.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Text('Nessun movimento stock MGWS trovato per i filtri.'),
  );
}
