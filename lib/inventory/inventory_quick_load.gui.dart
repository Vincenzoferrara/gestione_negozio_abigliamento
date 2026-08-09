import 'package:flutter/material.dart';

import '../login/jwt_api/query_mgws/query_mgws_inventory.dart';
import '../theme/theme.dart';
import 'inventory.code.dart';
import 'inventory_quick_load_widgets.gui.dart';

class InventoryQuickLoadPanel extends StatefulWidget {
  InventoryQuickLoadPanel({super.key, InventoryQuickLoadController? controller})
    : controller = controller ?? InventoryQuickLoadController();

  final InventoryQuickLoadController controller;

  @override
  State<InventoryQuickLoadPanel> createState() =>
      _InventoryQuickLoadPanelState();
}

class _InventoryQuickLoadPanelState extends State<InventoryQuickLoadPanel> {
  String _idempotencyKey = _newQuickLoadIdempotencyKey();
  final _productController = TextEditingController();
  final _variationController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  final _noteController = TextEditingController();
  final _warehouseController = TextEditingController();
  final _roomController = TextEditingController();
  final _rackController = TextEditingController();
  final _shelfController = TextEditingController();
  InventoryActionFeedback? _feedback;
  bool _submitting = false;

  @override
  void dispose() {
    _productController.dispose();
    _variationController.dispose();
    _barcodeController.dispose();
    _quantityController.dispose();
    _reasonController.dispose();
    _noteController.dispose();
    _warehouseController.dispose();
    _roomController.dispose();
    _rackController.dispose();
    _shelfController.dispose();
    super.dispose();
  }

  InventoryQuickLoadForm _form() => InventoryQuickLoadForm(
    productIdText: _productController.text,
    variationIdText: _variationController.text,
    barcodeText: _barcodeController.text,
    quantityText: _quantityController.text,
    reasonText: _reasonController.text,
    noteText: _noteController.text,
    warehouseIdText: _warehouseController.text,
    roomText: _roomController.text,
    rackText: _rackController.text,
    shelfText: _shelfController.text,
    idempotencyKeyText: _idempotencyKey,
  );

  Future<void> _startSubmit() async {
    final form = _form();
    final parsed = form.parse();
    switch (parsed) {
      case InventoryFormInvalid(:final message):
        _showFeedback(
          InventoryActionFeedback(success: false, message: message),
        );
      case InventoryFormValid(:final value):
        final confirmed = await _confirm(value);
        if (confirmed != true || !mounted) return;
        setState(() => _submitting = true);
        final feedback = await widget.controller.submit(form);
        if (!mounted) return;
        setState(() {
          _feedback = feedback;
          _submitting = false;
          if (feedback.success) {
            _idempotencyKey = _newQuickLoadIdempotencyKey();
          }
        });
        _snack(feedback.message, success: feedback.success);
    }
  }

  Future<bool?> _confirm(MgwsQuickLoadRequest request) {
    return showInventoryQuickLoadConfirmDialog(
      context: context,
      request: request,
      preview: _stockPreview(request),
    );
  }

  String _stockPreview(MgwsQuickLoadRequest request) {
    final last = widget.controller.lastQuickLoad;
    if (last == null ||
        last.productId != request.productId ||
        last.variationId != request.variationId) {
      return 'Anteprima stock non disponibile: MGWS non ha fornito un valore precedente per questa selezione.';
    }
    final next = last.currentStock + request.quantityDelta;
    return 'Stock previsto: ${last.currentStock} -> $next';
  }

  void _showFeedback(InventoryActionFeedback feedback) {
    setState(() => _feedback = feedback);
    _snack(feedback.message, success: feedback.success);
  }

  void _snack(String message, {required bool success}) {
    final colors = Theme.of(context).extension<AppColorExtension>()!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success
            ? colors.successColor
            : colors.errorColorStatus,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorExtension>()!;
    return Card(
      key: const ValueKey('inventory-quick-load-card'),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InventoryQuickLoadHeader(colors: colors),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _field(
                  _productController,
                  'ID prodotto *',
                  Icons.inventory_2_outlined,
                  'inventory-quick-load-product-field',
                ),
                _field(
                  _variationController,
                  'ID variante',
                  Icons.account_tree_outlined,
                  'inventory-quick-load-variation-field',
                ),
                _field(
                  _barcodeController,
                  'Barcode',
                  Icons.qr_code_2_outlined,
                  'inventory-quick-load-barcode-field',
                ),
                _field(
                  _quantityController,
                  'Quantita da aggiungere *',
                  Icons.add_circle_outline,
                  'inventory-quick-load-quantity-field',
                ),
                _field(
                  _reasonController,
                  'Motivo carico *',
                  Icons.fact_check_outlined,
                  'inventory-quick-load-reason-field',
                ),
                _field(
                  _noteController,
                  'Nota operativa',
                  Icons.notes_outlined,
                  'inventory-quick-load-note-field',
                ),
                _field(
                  _warehouseController,
                  'Magazzino',
                  Icons.warehouse_outlined,
                  'inventory-quick-load-warehouse-field',
                ),
                _field(
                  _roomController,
                  'Stanza',
                  Icons.meeting_room_outlined,
                  'inventory-quick-load-room-field',
                ),
                _field(
                  _rackController,
                  'Scaffale',
                  Icons.view_list_outlined,
                  'inventory-quick-load-rack-field',
                ),
                _field(
                  _shelfController,
                  'Ripiano',
                  Icons.view_agenda_outlined,
                  'inventory-quick-load-shelf-field',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_feedback != null)
              InventoryQuickLoadFeedbackPanel(
                feedback: _feedback!,
                result: widget.controller.lastQuickLoad,
              ),
            if (_feedback != null) const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                key: const ValueKey('inventory-quick-load-submit'),
                onPressed: _submitting ? null : _startSubmit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.playlist_add_check),
                label: Text(
                  _submitting ? 'Invio in corso' : 'Prepara conferma',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon,
    String key,
  ) {
    return SizedBox(
      width: 330,
      child: TextField(
        key: ValueKey(key),
        controller: controller,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        onChanged: (_) => _idempotencyKey = _newQuickLoadIdempotencyKey(),
      ),
    );
  }
}

String _newQuickLoadIdempotencyKey() =>
    'quick-load-${DateTime.now().microsecondsSinceEpoch}';
