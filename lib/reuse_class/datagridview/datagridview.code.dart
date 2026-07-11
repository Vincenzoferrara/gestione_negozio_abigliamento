import 'package:flutter/material.dart';

class DataGridViewColumn {
  final String id;
  final String label;
  final double width;
  final bool numeric;

  const DataGridViewColumn({
    required this.id,
    required this.label,
    this.width = 120,
    this.numeric = false,
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
