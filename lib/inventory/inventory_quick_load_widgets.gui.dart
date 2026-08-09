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
            Text('Quantita da aggiungere: ${request.quantityDelta}'),
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
        'Aggiungi stock MGWS con ID prodotto, eventuale variante/barcode, quantita positiva e motivo obbligatorio.',
        style: theme.textTheme.bodySmall?.copyWith(color: colors.subtitleColor),
      ),
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
