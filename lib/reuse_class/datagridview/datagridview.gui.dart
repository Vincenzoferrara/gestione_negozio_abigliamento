import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'datagridview.code.dart';

class DataGridView<T> extends StatefulWidget {
  final List<DataGridViewColumn> columns;
  final List<DataGridViewRowData<T>> rows;
  final String? selectedRowId;
  final Set<String> selectedRowIds;
  final ValueChanged<T>? onRowSelected;
  final ValueChanged<T>? onRowDoubleTap;
  final Future<void> Function(TapDownDetails details, T value)?
  onRowSecondaryTap;
  final void Function(T value, bool selected)? onRowChecked;
  final ValueChanged<bool>? onSelectAll;
  final ValueChanged<T?>? onDeleteShortcut;
  final VoidCallback? onEscapeShortcut;
  final String selectAllShortcut;
  final String deleteShortcut;
  final String escapeShortcut;
  final ScrollController? verticalScrollController;
  final bool showCheckboxes;

  const DataGridView({
    super.key,
    this.columns = const <DataGridViewColumn>[],
    this.rows = const [],
    this.selectedRowId,
    this.selectedRowIds = const <String>{},
    this.onRowSelected,
    this.onRowDoubleTap,
    this.onRowSecondaryTap,
    this.onRowChecked,
    this.onSelectAll,
    this.onDeleteShortcut,
    this.onEscapeShortcut,
    this.selectAllShortcut = 'Ctrl+A',
    this.deleteShortcut = 'Delete',
    this.escapeShortcut = 'Esc',
    this.verticalScrollController,
    this.showCheckboxes = false,
  });

  @override
  State<DataGridView<T>> createState() => _DataGridViewState<T>();
}

class _DataGridViewState<T> extends State<DataGridView<T>> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'DataGridView');
  int _selectedIndex = 0;
  static const double _headingRowHeight = 46;
  static const double _dataRowHeight = 68;

  List<DataGridViewColumn> get _columns => widget.columns;

  List<DataGridViewRowData<T>> get _rows => widget.rows;

  bool get _hasRows => _rows.isNotEmpty;
  bool get _allChecked =>
      _rows.isNotEmpty &&
      _rows.every((row) => widget.selectedRowIds.contains(row.id));
  bool get _someChecked =>
      _rows.any((row) => widget.selectedRowIds.contains(row.id));

  @override
  void didUpdateWidget(covariant DataGridView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedIndex >= _rows.length) {
      _selectedIndex = _rows.isEmpty ? 0 : _rows.length - 1;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (!_hasRows) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _selectIndex((_selectedIndex + 1).clamp(0, _rows.length - 1));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _selectIndex((_selectedIndex - 1).clamp(0, _rows.length - 1));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      widget.onRowDoubleTap?.call(_rows[_selectedIndex].value);
      return KeyEventResult.handled;
    }
    if (_matchesShortcut(event, widget.selectAllShortcut)) {
      widget.onSelectAll?.call(true);
      _focusNode.requestFocus();
      return KeyEventResult.handled;
    }
    if (_matchesShortcut(event, widget.deleteShortcut)) {
      widget.onDeleteShortcut?.call(
        _hasRows ? _rows[_selectedIndex].value : null,
      );
      _focusNode.requestFocus();
      return KeyEventResult.handled;
    }
    if (_matchesShortcut(event, widget.escapeShortcut)) {
      widget.onEscapeShortcut?.call();
      _focusNode.requestFocus();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  bool _matchesShortcut(KeyEvent event, String shortcut) {
    final parts = shortcut
        .toLowerCase()
        .split('+')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toSet();
    if (parts.isEmpty) return false;

    final wantsCtrl = parts.remove('ctrl') || parts.remove('control');
    final wantsAlt = parts.remove('alt');
    final wantsShift = parts.remove('shift');
    final wantsMeta = parts.remove('meta') || parts.remove('cmd');

    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isControlPressed != wantsCtrl) return false;
    if (keyboard.isAltPressed != wantsAlt) return false;
    if (keyboard.isShiftPressed != wantsShift) return false;
    if (keyboard.isMetaPressed != wantsMeta) return false;

    if (parts.length != 1) return false;
    return _shortcutKeyName(event.logicalKey) == parts.single;
  }

  String _shortcutKeyName(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.escape) return 'esc';
    if (key == LogicalKeyboardKey.delete) return 'delete';
    if (key == LogicalKeyboardKey.enter) return 'enter';
    final label = key.keyLabel.toLowerCase();
    if (label.length == 1) return label;
    return (key.debugName ?? '').toLowerCase().replaceAll(' ', '');
  }

  void _selectIndex(int index) {
    if (index < 0 || index >= _rows.length) return;
    setState(() => _selectedIndex = index);
    _ensureRowVisible(index);
    _focusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _selectedIndex != index) return;
      widget.onRowSelected?.call(_rows[index].value);
    });
  }

  void _ensureRowVisible(int index) {
    final controller = widget.verticalScrollController;
    if (controller == null || !controller.hasClients) return;

    final position = controller.position;
    final rowTop = _headingRowHeight + index * _dataRowHeight;
    final rowBottom = rowTop + _dataRowHeight;
    final viewportTop = position.pixels;
    final viewportBottom = viewportTop + position.viewportDimension;

    if (rowTop >= viewportTop && rowBottom <= viewportBottom) return;

    final target = rowTop - (_dataRowHeight * 0.35);
    final maxScroll = position.maxScrollExtent;
    final safeTarget = target.clamp(position.minScrollExtent, maxScroll);
    controller.jumpTo(safeTarget);
  }

  Widget _cell(DataGridViewRowData<T> row, DataGridViewColumn column) {
    final child = row.cells[column.id] ?? const Text('-');
    final styledChild = row.foregroundColor == null
        ? child
        : DefaultTextStyle.merge(
            style: TextStyle(color: row.foregroundColor),
            child: IconTheme.merge(
              data: IconThemeData(color: row.foregroundColor),
              child: child,
            ),
          );
    return Align(
      alignment: column.numeric ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: styledChild,
      ),
    );
  }

  List<DataColumn2> _buildColumns() {
    final dataColumns = _columns
        .map(
          (column) => DataColumn2(
            label: Text(
              column.label.toUpperCase(),
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            fixedWidth: column.width,
            numeric: column.numeric,
          ),
        )
        .toList();
    if (!widget.showCheckboxes) return dataColumns;
    return <DataColumn2>[
      DataColumn2(
        label: Checkbox(
          value: _allChecked ? true : (_someChecked ? null : false),
          tristate: true,
          onChanged: widget.onSelectAll == null
              ? null
              : (value) => widget.onSelectAll!(value ?? false),
        ),
        fixedWidth: 48,
      ),
      ...dataColumns,
    ];
  }

  List<DataRow2> _buildRows() {
    return _rows.asMap().entries.map((entry) {
      final index = entry.key;
      final row = entry.value;
      final selected =
          row.id == widget.selectedRowId || index == _selectedIndex;
      final checked = widget.selectedRowIds.contains(row.id);
      final cells = _columns
          .map(
            (column) => DataCell(
              _cell(row, column),
              onTapDown: (_) => _selectIndex(index),
            ),
          )
          .toList();
      if (widget.showCheckboxes) {
        cells.insert(
          0,
          DataCell(
            Checkbox(
              value: checked,
              onChanged: widget.onRowChecked == null
                  ? null
                  : (value) => widget.onRowChecked!(row.value, value ?? false),
            ),
            onTapDown: (_) => _selectIndex(index),
          ),
        );
      }
      return DataRow2(
        selected: selected,
        color: WidgetStateProperty.resolveWith<Color?>((states) {
          if (selected) {
            return Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.78);
          }
          if (checked) {
            return Theme.of(
              context,
            ).colorScheme.secondaryContainer.withValues(alpha: 0.5);
          }
          if (row.backgroundColor != null) return row.backgroundColor;
          if (index.isEven)
            return Theme.of(
              context,
            ).colorScheme.surfaceContainerLowest.withValues(alpha: 0.65);
          return null;
        }),
        onDoubleTap: () => widget.onRowDoubleTap?.call(row.value),
        onSecondaryTapDown: widget.onRowSecondaryTap == null
            ? null
            : (details) {
                widget.onRowSecondaryTap!(details, row.value);
              },
        cells: cells,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    const columnSpacing = 12.0;
    const horizontalMargin = 16.0;
    final theme = Theme.of(context);
    final columnCount = _columns.length + (widget.showCheckboxes ? 1 : 0);
    final fixedColumnsWidth =
        _columns.fold<double>(0, (sum, col) => sum + col.width) +
        (widget.showCheckboxes ? 48 : 0);
    final tableMinWidth =
        fixedColumnsWidth +
        (horizontalMargin * 2) +
        (columnSpacing * (columnCount > 1 ? columnCount - 1 : 0));

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border.all(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return DataTable2(
                      scrollController: widget.verticalScrollController,
                      columnSpacing: columnSpacing,
                      horizontalMargin: horizontalMargin,
                      minWidth: tableMinWidth,
                      headingRowHeight: _headingRowHeight,
                      dataRowHeight: _dataRowHeight,
                      showCheckboxColumn: false,
                      fixedTopRows: 1,
                      isHorizontalScrollBarVisible:
                          tableMinWidth > constraints.maxWidth,
                      headingRowColor: WidgetStatePropertyAll(
                        theme.colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.82,
                        ),
                      ),
                      dividerThickness: 0.35,
                      columns: _buildColumns(),
                      rows: _buildRows(),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
