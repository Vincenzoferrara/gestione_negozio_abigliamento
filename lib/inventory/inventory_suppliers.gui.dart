import 'package:flutter/material.dart';

import '../login/jwt_api/query_mgws/query_mgws_inventory.dart';
import '../reuse_class/datagridview/datagridview.code.dart';
import '../reuse_class/datagridview/datagridview.gui.dart';
import '../theme/theme.dart';
import 'inventory.code.dart';

class InventorySupplierPanel extends StatefulWidget {
  InventorySupplierPanel({super.key, InventorySupplierController? controller})
    : controller = controller ?? InventorySupplierController();

  final InventorySupplierController controller;

  @override
  State<InventorySupplierPanel> createState() => _InventorySupplierPanelState();
}

class _InventorySupplierPanelState extends State<InventorySupplierPanel> {
  final _siteController = TextEditingController(text: '1');
  final _idController = TextEditingController();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _taxController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  InventoryActionFeedback? _feedback;
  MgwsSupplier? _selected;
  bool _active = true;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _siteController.dispose();
    _idController.dispose();
    _codeController.dispose();
    _nameController.dispose();
    _taxController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final feedback = await widget.controller.load(_siteController.text);
    if (!mounted) return;
    setState(() {
      _feedback = feedback;
      _loading = false;
      if (_selected == null && widget.controller.suppliers.isNotEmpty) {
        _select(widget.controller.suppliers.first);
      }
    });
  }

  void _select(MgwsSupplier supplier) {
    _selected = supplier;
    _idController.text = supplier.id.toString();
    _siteController.text = supplier.siteId.toString();
    _codeController.text = supplier.supplierCode;
    _nameController.text = supplier.name;
    _taxController.text = supplier.taxId;
    _emailController.text = supplier.email;
    _phoneController.text = supplier.phone;
    _notesController.text = supplier.notes;
    _active = supplier.active;
  }

  Future<void> _loadDetail(MgwsSupplier supplier) async {
    final feedback = await widget.controller.get(supplier.id.toString());
    if (!mounted) return;
    setState(() {
      _feedback = feedback;
      if (widget.controller.lastSupplier != null) {
        _select(widget.controller.lastSupplier!);
      }
    });
  }

  void _selectFromGrid(MgwsSupplier supplier) {
    setState(() => _select(supplier));
    _loadDetail(supplier);
  }

  void _newSupplier() {
    setState(() {
      _selected = null;
      _idController.clear();
      _codeController.clear();
      _nameController.clear();
      _taxController.clear();
      _emailController.clear();
      _phoneController.clear();
      _notesController.clear();
      _active = true;
      _feedback = null;
    });
  }

  InventorySupplierForm _form() => InventorySupplierForm(
    siteIdText: _siteController.text,
    supplierCodeText: _codeController.text,
    nameText: _nameController.text,
    taxIdText: _taxController.text,
    emailText: _emailController.text,
    phoneText: _phoneController.text,
    notesText: _notesController.text,
    active: _active,
  );

  Future<void> _save() async {
    setState(() => _saving = true);
    final selected = _selected;
    final feedback = selected == null
        ? await widget.controller.create(_form())
        : await widget.controller.update(
            supplierIdText: selected.id.toString(),
            form: _form(),
          );
    if (!mounted) return;
    setState(() {
      _feedback = feedback;
      _saving = false;
      if (widget.controller.lastSupplier != null) {
        _select(widget.controller.lastSupplier!);
      }
    });
  }

  Future<void> _delete() async {
    final selected = _selected;
    if (selected == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina fornitore'),
        content: Text('Eliminare ${selected.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            key: const ValueKey('inventory-supplier-delete-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final feedback = await widget.controller.delete(selected.id.toString());
    if (!mounted) return;
    setState(() => _feedback = feedback);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorExtension>()!;
    return Card(
      key: const ValueKey('inventory-suppliers-panel'),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(colors: colors),
              const SizedBox(height: 12),
              _Toolbar(onLoad: _load, onNew: _newSupplier, loading: _loading),
              const SizedBox(height: 12),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (widget.controller.suppliers.isEmpty)
                _EmptyState(colors: colors)
              else
                SizedBox(height: 240, child: _grid()),
              const SizedBox(height: 12),
              _formFields(),
              const SizedBox(height: 12),
              if (_feedback != null) _Feedback(feedback: _feedback!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _grid() {
    return DataGridView<MgwsSupplier>(
      columns: const [
        DataGridViewColumn(id: 'code', label: 'Codice', width: 120),
        DataGridViewColumn(id: 'name', label: 'Fornitore', width: 220),
        DataGridViewColumn(id: 'contact', label: 'Contatto', width: 240),
        DataGridViewColumn(id: 'state', label: 'Stato', width: 110),
      ],
      rows: [
        for (final supplier in widget.controller.suppliers) _row(supplier),
      ],
      selectedRowId: _selected?.id.toString(),
      onRowSelected: _selectFromGrid,
      onRowDoubleTap: _selectFromGrid,
    );
  }

  DataGridViewRowData<MgwsSupplier> _row(MgwsSupplier supplier) {
    final tone = supplier.active
        ? Theme.of(context).extension<AppColorExtension>()!.successColor
        : Theme.of(context).extension<AppColorExtension>()!.warningColor;
    return DataGridViewRowData(
      id: supplier.id.toString(),
      value: supplier,
      cells: {
        'code': Text(supplier.supplierCode),
        'name': Text(supplier.name),
        'contact': Text(
          [
            supplier.email,
            supplier.phone,
          ].where((v) => v.isNotEmpty).join(' | '),
        ),
        'state': Chip(
          label: Text(supplier.active ? 'Attivo' : 'Inattivo'),
          side: BorderSide(color: tone),
        ),
      },
    );
  }

  Widget _formFields() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _field(_siteController, 'Site ID *', 'inventory-supplier-site-field'),
        _field(
          _idController,
          'Supplier ID',
          'inventory-supplier-id-field',
          enabled: false,
        ),
        _field(_codeController, 'Codice *', 'inventory-supplier-code-field'),
        _field(_nameController, 'Nome *', 'inventory-supplier-name-field'),
        _field(_taxController, 'P.IVA / Tax', 'inventory-supplier-tax-field'),
        _field(_emailController, 'Email', 'inventory-supplier-email-field'),
        _field(_phoneController, 'Telefono', 'inventory-supplier-phone-field'),
        _field(_notesController, 'Note', 'inventory-supplier-notes-field'),
        FilterChip(
          label: Text(_active ? 'Attivo' : 'Inattivo'),
          selected: _active,
          onSelected: (value) => setState(() => _active = value),
        ),
        ElevatedButton.icon(
          key: const ValueKey('inventory-supplier-save'),
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: Text(_selected == null ? 'Crea fornitore' : 'Salva modifiche'),
        ),
        OutlinedButton.icon(
          key: const ValueKey('inventory-supplier-delete'),
          onPressed: _selected == null ? null : _delete,
          icon: const Icon(Icons.delete_outline),
          label: const Text('Elimina'),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    String key, {
    bool enabled = true,
  }) {
    return SizedBox(
      width: 250,
      child: TextField(
        key: ValueKey(key),
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.colors});
  final AppColorExtension colors;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(
      Icons.storefront_outlined,
      color: Theme.of(context).colorScheme.primary,
    ),
    title: Text(
      'Fornitori',
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
    ),
    subtitle: Text(
      'Anagrafica fornitori MGWS senza movimenti stock.',
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: colors.subtitleColor),
    ),
  );
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.onLoad,
    required this.onNew,
    required this.loading,
  });
  final VoidCallback onLoad;
  final VoidCallback onNew;
  final bool loading;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    children: [
      OutlinedButton.icon(
        onPressed: loading ? null : onLoad,
        icon: const Icon(Icons.refresh),
        label: const Text('Aggiorna'),
      ),
      ElevatedButton.icon(
        key: const ValueKey('inventory-supplier-new'),
        onPressed: onNew,
        icon: const Icon(Icons.add_business),
        label: const Text('Nuovo'),
      ),
    ],
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.colors});
  final AppColorExtension colors;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: colors.priceBackground.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Text('Nessun fornitore MGWS trovato.'),
  );
}

class _Feedback extends StatelessWidget {
  const _Feedback({required this.feedback});
  final InventoryActionFeedback feedback;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorExtension>()!;
    final tone = feedback.success
        ? colors.successColor
        : colors.errorColorStatus;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tone.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            feedback.message,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: tone,
              fontWeight: FontWeight.w800,
            ),
          ),
          for (final detail in feedback.details)
            Text(detail, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
