import 'package:flutter/material.dart';

class DataGridViewColumn {
  final String id;
  final String label;
  final double width;
  final bool numeric;

  /// La colonna assorbe la larghezza che resta dopo tutte le altre.
  ///
  /// Senza questo, con colonne tutte a larghezza fissa la tabella si ferma
  /// alla somma delle larghezze e lascia uno spazio morto a destra. Con
  /// `flexible` la colonna non ha larghezza fissa: `DataTable2` le distribuisce
  /// tutto il residuo, e [width] resta la sua larghezza minima, raggiunta
  /// facendo scorrere la tabella in orizzontale.
  final bool flexible;

  const DataGridViewColumn({
    required this.id,
    required this.label,
    this.width = 120,
    this.numeric = false,
    this.flexible = false,
  });
}

class DataGridViewRowData<T> {
  final String id;
  final T value;
  final Map<String, Widget> cells;
  final Color? foregroundColor;
  final Color? backgroundColor;

  const DataGridViewRowData({
    required this.id,
    required this.value,
    required this.cells,
    this.foregroundColor,
    this.backgroundColor,
  });
}

/// Azione del menu contestuale mostrato dalla [DataGridView] sul click destro
/// (o pressione prolungata sulle card mobili che riusano lo stesso menu).
///
/// La voce di menu (etichetta + icona) e la logica di dispatcher vivono nella
/// griglia riusabile; il chiamante fornisce solo le azioni e il callback
/// applicato alla riga selezionata.
class DataGridViewContextAction<T> {
  final String label;
  final IconData icon;
  final Future<void> Function(T value) onSelected;

  const DataGridViewContextAction({
    required this.label,
    required this.icon,
    required this.onSelected,
  });
}
