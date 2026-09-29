import 'package:flutter/material.dart';

import '../login/jwt_api/query_mgws/query_mgws_inventory.dart';
import '../theme/theme.dart';
import 'inventory.code.dart';

Future<bool?> showInventoryQuickLoadConfirmDialog({
  required BuildContext context,
  required MgwsQuickLoadRequest request,
  required String preview,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Conferma carico rapido'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Prodotto: ${request.productId}'),
            Text('Variante: ${request.variationId}'),
            if ((request.barcode ?? '').isNotEmpty)
              Text('Barcode: ${request.barcode}'),
            Text('Quantità da aggiungere: ${request.quantityDelta}'),
            Text('Motivo: ${request.reason}'),
            if ((request.note ?? '').isNotEmpty) Text('Nota: ${request.note}'),
            const SizedBox(height: 12),
            Text(preview, key: const ValueKey('inventory-quick-load-preview')),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          key: const ValueKey('inventory-quick-load-confirm'),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Conferma carico'),
        ),
      ],
    ),
  );
}

Future<bool?> showInventoryQuickLoadBatchConfirmDialog({
  required BuildContext context,
  required InventoryQuickLoadSubmissionPlan plan,
}) {
  final listHeight = (plan.lines.length * 56.0).clamp(56.0, 280.0);
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Conferma carico rapido'),
      content: SizedBox(
        width: 620,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${plan.lines.length} righe · ${plan.totalQuantity} pezzi',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text('Motivo: $kInventoryCaricoReason'),
            if (plan.warehouseId != null || plan.room != null)
              Text(
                'Posizione condivisa: ${[if (plan.warehouseId != null) 'Mag. ${plan.warehouseId}', if (plan.room != null) 'Stanza ${plan.room}'].join(' · ')}',
              ),
            if ((plan.note ?? '').isNotEmpty) Text('Nota: ${plan.note}'),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'MGWS riceverà un carico per ogni riga, in sequenza. '
                    'Se alcune righe falliscono, potrai riprovare solo quelle.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            SizedBox(
              height: listHeight,
              child: ListView.separated(
                itemCount: plan.lines.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final line = plan.lines[index];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(line.label),
                    subtitle: Text(
                      [
                        if (line.barcodeInterno?.trim().isNotEmpty == true)
                          'Barcode interno ${line.barcodeInterno}',
                        if (line.rack?.trim().isNotEmpty == true)
                          'Scaffale ${line.rack}',
                        if (line.shelf?.trim().isNotEmpty == true)
                          'Ripiano ${line.shelf}',
                      ].join(' · '),
                    ),
                    trailing: Text('× ${line.quantity}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Annulla'),
        ),
        ElevatedButton.icon(
          key: const ValueKey('inventory-quick-load-confirm'),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          icon: const Icon(Icons.playlist_add_check),
          label: const Text('Conferma carico'),
        ),
      ],
    ),
  );
}

/// Chiede quanti pezzi aggiungere per un prodotto.
///
/// Serve quando l'operatore ha tolto la spunta "aggiungi automaticamente":
/// in quel caso nessuna quantita' viene indovinata, la chiede lui. Restituisce
/// null se annulla, cosi' il chiamante distingue "non ho deciso" da "ho
/// deciso zero" — che non e' una risposta valida.
Future<int?> showInventoryQuantityPrompt({
  required BuildContext context,
  required String label,
  int initial = 1,
}) {
  final controller = TextEditingController(text: '$initial');
  final error = ValueNotifier<String?>(null);

  int? parse() {
    final value = int.tryParse(controller.text.trim());
    if (value == null || value <= 0) {
      error.value = 'Inserisci un numero maggiore di zero';
      return null;
    }
    return value;
  }

  return showDialog<int>(
    context: context,
    builder: (dialogContext) {
      void add(int step) {
        final current = int.tryParse(controller.text.trim()) ?? 0;
        final next = (current + step).clamp(1, 9999);
        controller.text = '$next';
        error.value = null;
      }

      return AlertDialog(
        title: const Text('Quanti pezzi?'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('inventory-quantity-prompt-field'),
                      controller: controller,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Pezzi',
                        isDense: true,
                      ),
                      onChanged: (_) => error.value = null,
                      onSubmitted: (_) {
                        final value = parse();
                        if (value != null) {
                          Navigator.of(dialogContext).pop(value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Aggiungi 1',
                    onPressed: () => add(1),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                  IconButton(
                    tooltip: 'Aggiungi 5',
                    onPressed: () => add(5),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              ValueListenableBuilder<String?>(
                valueListenable: error,
                builder: (context, message, _) => message == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          message,
                          key: const ValueKey(
                            'inventory-quantity-prompt-error',
                          ),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            key: const ValueKey('inventory-quantity-prompt-confirm'),
            onPressed: () {
              final value = parse();
              if (value != null) Navigator.of(dialogContext).pop(value);
            },
            child: const Text('Aggiungi'),
          ),
        ],
      );
    },
  ).whenComplete(() {
    controller.dispose();
    error.dispose();
  });
}

class InventoryQuickLoadHeader extends StatelessWidget {
  const InventoryQuickLoadHeader({super.key, required this.colors});

  final AppColorExtension colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.flash_on, color: theme.colorScheme.primary),
      title: Text(
        'Carico rapido',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        'Scegli la posizione, seleziona prodotti o varianti e assegna la quantità a ogni riga.',
        style: theme.textTheme.bodySmall?.copyWith(color: colors.subtitleColor),
      ),
    );
  }
}

/// Dropdown con le opzioni di posizione e motivo configurate nelle settings.
///
/// Riutilizzato dai pannelli che scrivono su magazzino, cosi la lista di
/// opzioni, il valore di default e la chiave di ricerca restano uguali in
/// ogni schermata.
class InventoryQuickLoadSelector extends StatelessWidget {
  const InventoryQuickLoadSelector({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.options,
    required this.onChanged,
    this.keyName,
    this.allowUnset = true,
  });

  final String label;
  final IconData icon;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  /// Prefisso della chiave di ricerca: tiene i test distinguibili per campo.
  final String? keyName;
  final bool allowUnset;

  @override
  Widget build(BuildContext context) {
    final effectiveValue = options.contains(value) ? value : null;
    return DropdownButtonFormField<String>(
      key: ValueKey('${keyName ?? label}-$effectiveValue-${options.length}'),
      initialValue: effectiveValue,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      items: [
        if (allowUnset)
          const DropdownMenuItem<String>(value: null, child: Text('Nessuno')),
        for (final option in options)
          DropdownMenuItem<String>(value: option, child: Text(option)),
      ],
      onChanged: options.isEmpty && !allowUnset ? null : onChanged,
    );
  }
}

class InventoryQuickLoadFeedbackPanel extends StatelessWidget {
  const InventoryQuickLoadFeedbackPanel({
    super.key,
    required this.feedback,
    required this.result,
  });

  final InventoryActionFeedback feedback;
  final MgwsQuickLoad? result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorExtension>()!;
    final tone = feedback.success
        ? colors.successColor
        : colors.errorColorStatus;
    return Container(
      key: const ValueKey('inventory-quick-load-feedback'),
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
            style: theme.textTheme.titleSmall?.copyWith(
              color: tone,
              fontWeight: FontWeight.w800,
            ),
          ),
          for (final detail in feedback.details)
            Text(detail, style: theme.textTheme.bodySmall),
          if (feedback.success && result != null) ...[
            const SizedBox(height: 8),
            // Solo l'operazione interessa all'operatore. Il numero della riga
            // di libro e' un id interno di MGWS: mostrarlo porta a cercarlo
            // nel database, che non e' dove l'operatore verifica un carico.
            if (result!.movementId > 0)
              Text(
                'Movimento MGWS #${result!.movementId}',
                style: theme.textTheme.labelLarge,
              ),
            Text(
              'Stock: ${result!.previousStock} -> ${result!.currentStock}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
