// inventory_movements.gui.dart
//
// Il ledger MGWS, letto per operazione.
//
// Una riga e' un'operazione, non un prodotto: MGWS registra una riga per
// prodotto, quindi i movimenti che condividono origine e documento vengono
// accorpati da `groupMovements`. L'operatore ragiona per operazione ("quel
// carico di ieri sera"), quindi e' questo il taglio giusto.
//
// Il pannello non modifica il ledger: lo legge, e le due azioni che offre
// partono da un movimento per produrre un movimento nuovo. Il doppio click
// apre la schermata dell'operazione, da li' si sceglie se riaprirla nel pannello
// che l'ha prodotta o se annullarla per contromovimento.

import 'package:flutter/material.dart';

import '../reuse_class/datagridview/datagridview.code.dart';
import '../reuse_class/datagridview/datagridview.gui.dart';
import '../theme/theme.dart';
import 'inventory.code.dart';
import 'inventory_movement_groups.code.dart';
import 'inventory_movements_detail.gui.dart';

class InventoryMovementLedgerPanel extends StatefulWidget {
  InventoryMovementLedgerPanel({
    super.key,
    InventoryMovementController? controller,
    this.onReopen,
  }) : controller = controller ?? InventoryMovementController();

  final InventoryMovementController controller;

  /// Chiamata quando l'operatore sceglie "Modifica": la pagina che ospita il
  /// pannello fa il salto di modulo. Qui non si sa cosa ci sia fuori, quindi
  /// il pannello passa il seme e non decide nulla.
  final void Function(InventoryPanelSeed seed)? onReopen;

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

  /// L'annullamento ha il suo controller perche' il piano di ripristino e'
  /// diverso da quello di una rettifica normale: verifica lo stock attuale
  /// prima di toccare qualcosa.
  final _revert = InventoryMovementRevertController();

  InventoryActionFeedback? _feedback;
  InventoryMovementGroup? _selected;
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

  List<InventoryMovementGroup> get _groups =>
      groupMovements(widget.controller.movements);

  /// `true` se il backend ha tagliato la risposta.
  ///
  /// Il raggruppamento per operazione si regge su una cosa sola: i prodotti della
  /// stessa operazione devono arrivare insieme. MGWS pagina e non filtra per
  /// documento, quindi un'operazione piu' grande di una pagina verrebbe
  /// accordata in due righe, e l'operatore vedrebbe due operazioni dove ce
  /// n'e' una sola. Meglio dirlo che farlo notare a metta.
  bool get _pageIsTruncated {
    final page = widget.controller.movementPage;
    if (page == null) return false;
    return widget.controller.movements.length < page.total;
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final feedback = await widget.controller.load(_form());
    if (!mounted) return;
    setState(() {
      _feedback = feedback;
      _loading = false;
      _selected = null;
    });
  }

  Future<void> _openGroup(InventoryMovementGroup group) async {
    setState(() => _selected = group);
    final action = await showInventoryMovementDialog(context, group);
    if (!mounted) return;
    switch (action) {
      case InventoryMovementAction.reopen:
        _reopen(group);
      case InventoryMovementAction.revert:
        await _revertGroup(group);
      case null:
        break;
    }
  }

  /// Riapre l'operazione nel pannello che l'ha prodotta.
  ///
  /// Il seme porta solo i prodotti, il motivo e i dettagli: sono i dati che il
  /// ledger registra davvero. Se il pannello non e' collegato a nessuna pagina
  /// non si fa niente in silenzio, si dice.
  void _reopen(InventoryMovementGroup group) {
    final callback = widget.onReopen;
    final module = group.resumeModule;
    if (callback == null || module == null) return;
    callback(
      InventoryPanelSeed(
        module: module,
        movements: group.movements,
        products: group.products,
        reason: group.reason,
        details: group.note,
      ),
    );
  }

  /// Prepara il contromovimento, mostra cosa succedera' e solo dopo chiede.
  ///
  /// Il piano si costruisce leggendo lo stock attuale di ogni prodotto: se
  /// nel frattempo qualcun altro ha mosso la merce, l'annullamento di quel
  /// prodotto viene bloccato e l'operatore vede il nome del prodotto e il
  /// motivo, non un errore generico.
  Future<void> _revertGroup(InventoryMovementGroup group) async {
    setState(() => _feedback = null);
    final prepared = await _revert.prepare(group);
    if (!mounted) return;
    final plan = _revert.lastPlan;
    if (plan == null || !plan.canRevert) {
      setState(() => _feedback = prepared);
      return;
    }
    final confirmed = await _confirmRevert(plan);
    if (!mounted || confirmed != true) return;
    final feedback = await _revert.execute(plan);
    if (!mounted) return;
    setState(() => _feedback = feedback);
    // Il ledger e' cambiato: senza ricaricare la lista mostrerebbe uno stock
    // che non esiste piu' e l'operatore prenderebbe decisioni su numeri vecchi.
    await _load();
  }

  Future<bool?> _confirmRevert(InventoryMovementRevertPlan plan) {
    final isMove = plan.group.isMove;
    // Su uno spostamento la riga non riporta il totale a un numero: dice
    // quanti pezzi tornano indietro e da quale magazzino a quale. Dire "da 40 a
    // 40" sarebbe un annullamento che non annulla niente.
    final lines = <String>[
      for (final line in plan.revertable)
        if (line.isReverseMove)
          '${line.productLabel}: ${line.quantity} pezzi, ${line.routeText}'
        else
          '${line.productLabel}: da ${line.currentStock ?? '?'} '
              'a ${line.restoreTo}',
      for (final line in plan.blocked)
        '${line.productLabel}: saltato, ${line.blockMessage}',
    ];
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const ValueKey('inventory-movement-revert-confirm'),
        title: const Text('Annullare il movimento'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isMove
                      ? 'Il ledger non si cancella: verra\' registrato uno '
                            'spostamento al contrario, che porta gli stessi pezzi '
                            'dal magazzino di arrivo a quello di partenza. La '
                            'riga originale resta, con accanto '
                            'l\'annullamento.'
                      : 'Il ledger non si cancella: verra\' registrato un '
                            'movimento nuovo che riporta lo stock al valore di '
                            'prima. La riga originale resta, con accanto '
                            'l\'annullamento.',
                ),
                const SizedBox(height: 12),
                for (final line in lines) Text(line),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(isMove ? 'Sposta indietro' : 'Riporta indietro'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorExtension>()!;
    final groups = _groups;
    return Card(
      key: const ValueKey('inventory-movements-panel'),
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.timeline, color: theme.colorScheme.primary),
                title: Text(
                  'Movimenti di magazzino',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Text(
                  'Una riga per operazione, con i prodotti che ha toccato. '
                  'Doppio click per aprirla.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.subtitleColor,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _filters(),
              const SizedBox(height: 10),
              if (_pageIsTruncated) ...[
                _truncationNotice(),
                const SizedBox(height: 10),
              ],
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (groups.isEmpty)
                _empty(colors)
              else
                SizedBox(height: 320, child: _grid(groups)),
              const SizedBox(height: 10),
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

  Widget _grid(List<InventoryMovementGroup> groups) =>
      DataGridView<InventoryMovementGroup>(
        columns: const [
          DataGridViewColumn(id: 'time', label: 'Data', width: 175),
          DataGridViewColumn(id: 'kind', label: 'Tipo', width: 120),
          DataGridViewColumn(id: 'operator', label: 'Operatore', width: 110),
          DataGridViewColumn(
            id: 'delta',
            label: 'Pezzi',
            width: 80,
            numeric: true,
          ),
          DataGridViewColumn(
            id: 'products',
            label: 'Prodotti',
            width: 90,
            numeric: true,
          ),
          DataGridViewColumn(id: 'last', label: 'Ultima modifica', width: 175),
          DataGridViewColumn(
            id: 'reason',
            label: 'Motivo e dettagli',
            flexible: true,
          ),
        ],
        rows: [for (final group in groups) _row(group)],
        selectedRowId: _selected?.key,
        onRowSelected: (group) => setState(() => _selected = group),
        onRowDoubleTap: _openGroup,
        contextActions: [
          DataGridViewContextAction<InventoryMovementGroup>(
            label: 'Apri il movimento',
            icon: Icons.open_in_new,
            onSelected: _openGroup,
          ),
        ],
      );

  DataGridViewRowData<InventoryMovementGroup> _row(
    InventoryMovementGroup group,
  ) {
    final colors = Theme.of(context).extension<AppColorExtension>()!;
    // Il colore del delta ha tre casi, non due. Lo spostamento non cambia il
    // totale, quindi il suo delta e' zero per costruzione: colorarlo di verde
    // come un aumento direbbe "e' andata bene", che e' un'altra informazione da
    // quella che la riga sta dando. Un delta zero dice solo che il totale non si
    // e' mosso, e il totale non muoversi e' il fatto normale, non una buona
    // notizia. Il colore del testo di base e' quello giusto per un dato che non
    // ha un peso.
    final tone = group.quantityDelta == 0
        ? Theme.of(context).colorScheme.onSurface
        : (group.quantityDelta > 0
              ? colors.successColor
              : colors.errorColorStatus);
    // Sullo spostamento la colonna del delta mostrerebbe uno zero che non dice
    // niente, mentre l'informazione utile e' quanti pezzi hanno cambiato
    // magazzino. La riga e' gia' etichettata come spostamento nella colonna
    // della tipologia, quindi qui basta il numero senza segno: il segno
    // suggerirebbe una variazione che non c'e' stata.
    final deltaCell = group.isMove
        ? Text('${group.movedQuantity} pezzi')
        : Text(movementSigned(group.quantityDelta));
    return DataGridViewRowData(
      id: group.key,
      value: group,
      foregroundColor: tone,
      cells: {
        'time': Text(group.occurredAtGmt),
        // Il tipo che MGWS scrive resta visibile accanto all'etichetta quando
        // non e' uno che l'app conosce: meglio una parola grezza che un
        //-etichetta indovinata.
        'kind': Text(
          group.kind == InventoryMovementKind.altro
              ? '${group.kindLabel} (${group.rawType})'
              : group.kindLabel,
        ),
        'operator': Text('#${group.operatorUserId}'),
        'delta': deltaCell,
        'products': Text('${group.productCount}'),
        'last': Text(group.lastModifiedGmt),
        'reason': Text(group.reasonAndDetails),
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

  /// Avviso che la risposta e' stata tagliata dal backend.
  Widget _truncationNotice() {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorExtension>()!;
    final total = widget.controller.movementPage!.total;
    final shown = widget.controller.movements.length;
    return Container(
      key: const ValueKey('inventory-movement-truncated'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.warningColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.warningColor.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: colors.warningColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Mostro $shown movimenti su $total: MGWS pagina e non filtra per '
              'documento, quindi un\'operazione con piu\' di $shown prodotti puo\' '
              'essere spezzata in due righe. Stringi i filtri per vederla intera.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(AppColorExtension colors) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: colors.priceBackground.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Text('Nessun movimento MGWS trovato per i filtri.'),
  );
}
