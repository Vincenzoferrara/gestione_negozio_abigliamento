import 'package:flutter/material.dart';

import '../login/jwt_api/query_mgws/query_mgws_inventory.dart';
import '../theme/theme.dart';
import 'inventory.code.dart';

class InventoryMovementDetailPanel extends StatelessWidget {
  const InventoryMovementDetailPanel({super.key, required this.movement});
  final MgwsMovement? movement;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorExtension>()!;
    final item = movement;
    if (item == null) {
      return _box(
        colors,
        const Text('Seleziona un movimento per vedere il dettaglio audit.'),
      );
    }
    return _box(
      colors,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dettaglio movimento #${item.id}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text('Before ${movementStock(item.stockBefore)}')),
              Chip(label: Text('After ${movementStock(item.stockAfter)}')),
              Chip(label: Text('Delta ${movementSigned(item.quantityDelta)}')),
              Chip(label: Text('Effetto ${item.stockEffect}')),
              Chip(label: Text('Operatore #${item.operatorUserId}')),
              Chip(label: Text('Origine ${item.sourceType} #${item.sourceId}')),
              Chip(label: Text('Riga origine #${item.sourceLineId}')),
              for (final link in item.sourceLinks.entries)
                Chip(label: Text('${link.key} #${link.value}')),
            ],
          ),
          const SizedBox(height: 8),
          Text('Motivo: ${item.reasonCode}'),
          Text('Nota: ${item.note.isEmpty ? '-' : item.note}'),
          Text(
            'Ubicazione: W${item.location.warehouseId} '
            '${item.location.room}/${item.location.rack}/${item.location.shelf}',
          ),
        ],
      ),
    );
  }

  Widget _box(AppColorExtension colors, Widget child) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: colors.priceBackground.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(14),
    ),
    child: child,
  );
}

class InventoryMovementFeedback extends StatelessWidget {
  const InventoryMovementFeedback({super.key, required this.feedback});
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

String movementSigned(int value) => value > 0 ? '+$value' : value.toString();
String movementStock(int? value) => value?.toString() ?? '-';
