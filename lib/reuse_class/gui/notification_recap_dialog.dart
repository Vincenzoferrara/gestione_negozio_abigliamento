import 'package:flutter/material.dart';

/// Recap uniforme per tutte le operazioni persistenti.
///
/// Le API [delete] ed [edit] definiscono titoli, testi e bottoni standard.
/// Il chiamante fornisce esclusivamente gli elementi coinvolti e, quando
/// serve, la specifica chiamata dati da eseguire dopo la conferma.
class NotificationRecapDialog {
  NotificationRecapDialog._();

  static Future<bool> delete<T>(
    BuildContext context, {
    required Iterable<T> items,
    required String Function(T item) itemLabel,
    required bool isDestructive,
  }) {
    final labels = items.map(itemLabel).toList(growable: false);
    final isBulk = labels.length > 1;
    return _show(
      context,
      title: isBulk ? 'Recap eliminazione' : 'Eliminazione',
      summary: isBulk
          ? 'Stai per eliminare ${labels.length} elementi.'
          : 'Stai per eliminare questo elemento.',
      changes: labels,
      confirmLabel: 'Elimina',
      isDestructive: isDestructive,
    );
  }

  static Future<bool> edit(
    BuildContext context, {
    required Iterable<String> changes,
    required int affectedItemsCount,
    bool isDestructive = false,
  }) {
    final isBulk = affectedItemsCount > 1;
    return _show(
      context,
      title: isBulk ? 'Recap modifica in massa' : 'Recap modifica',
      summary: isBulk
          ? 'Stai per applicare le modifiche a $affectedItemsCount elementi.'
          : 'Stai per applicare le modifiche a questo elemento.',
      changes: changes.toList(growable: false),
      confirmLabel: isBulk ? 'Applica modifiche' : 'Applica modifica',
      isDestructive: isDestructive,
    );
  }

  static Future<bool> _show(
    BuildContext context, {
    required String title,
    required String summary,
    required List<String> changes,
    required String confirmLabel,
    bool isDestructive = false,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(summary),
              if (changes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: changes
                          .map(
                            (change) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text('• $change'),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            style: isDestructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(dialogContext).colorScheme.error,
                    foregroundColor: Theme.of(
                      dialogContext,
                    ).colorScheme.onError,
                  )
                : null,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return confirmed == true;
  }
}
