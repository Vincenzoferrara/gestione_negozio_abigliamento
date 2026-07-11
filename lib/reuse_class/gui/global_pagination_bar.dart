import 'package:flutter/material.dart';

import '../../settings/app_settings.dart';
import '../logic/global_pagination_controller.dart';

class GlobalPaginationBar extends StatefulWidget {
  final AppSettings settings;
  final GlobalPaginationController<dynamic> controller;
  final Future<void> Function()? onFirstPage;
  final Future<void> Function()? onPreviousPage;
  final Future<void> Function()? onNextPage;
  final Future<void> Function()? onLastPage;
  final Future<void> Function(GlobalPageMode mode, int pageSize)?
  onModeOrPageSizeChanged;
  final int? totalRows;
  final int selectedRows;

  const GlobalPaginationBar({
    super.key,
    required this.settings,
    required this.controller,
    this.onFirstPage,
    this.onPreviousPage,
    this.onNextPage,
    this.onLastPage,
    this.onModeOrPageSizeChanged,
    this.totalRows,
    this.selectedRows = 0,
  });

  @override
  State<GlobalPaginationBar> createState() => _GlobalPaginationBarState();
}

class _GlobalPaginationBarState extends State<GlobalPaginationBar> {
  late final TextEditingController _pageSizeController;

  @override
  void initState() {
    super.initState();
    _pageSizeController = TextEditingController(
      text: widget.controller.pageSizeText,
    );
    widget.controller.addListener(_syncControllerText);
  }

  @override
  void didUpdateWidget(covariant GlobalPaginationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_syncControllerText);
      widget.controller.addListener(_syncControllerText);
      _syncControllerText();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncControllerText);
    _pageSizeController.dispose();
    super.dispose();
  }

  void _syncControllerText() {
    final next = widget.controller.pageSizeText;
    if (_pageSizeController.text == next) return;
    _pageSizeController.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
  }

  Future<void> _applyPageSizeValue(String raw) async {
    if (GlobalPaginationOptions.isInfiniteLabel(raw)) {
      widget.controller.setMode(GlobalPageMode.infinite);
      await widget.onModeOrPageSizeChanged?.call(
        GlobalPageMode.infinite,
        GlobalPaginationOptions.infiniteChunkSize,
      );
      return;
    }

    final parsed = GlobalPaginationOptions.tryParsePageSize(raw);
    if (parsed == null) {
      _syncControllerText();
      return;
    }

    await widget.controller.persistPageSize(widget.settings, parsed);
    widget.controller.setMode(GlobalPageMode.paged, resetPage: false);
    await widget.onModeOrPageSizeChanged?.call(
      GlobalPageMode.paged,
      widget.controller.pageSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return Material(
          elevation: 1,
          color: Theme.of(context).cardColor,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 8,
              spacing: 12,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 180,
                      child: DropdownMenu<String>(
                        controller: _pageSizeController,
                        initialSelection: widget.controller.pageSizeText,
                        requestFocusOnTap: true,
                        enableFilter: true,
                        label: const Text('Righe per pagina'),
                        onSelected: (value) {
                          if (value == null) return;
                          _applyPageSizeValue(value);
                        },
                        dropdownMenuEntries: <DropdownMenuEntry<String>>[
                          for (final option
                              in GlobalPaginationOptions.defaultPageSizes)
                            DropdownMenuEntry<String>(
                              value: option.toString(),
                              label: option.toString(),
                            ),
                          const DropdownMenuEntry<String>(
                            value: GlobalPaginationOptions.infiniteLabel,
                            label: GlobalPaginationOptions.infiniteLabel,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      tooltip: 'Applica righe per pagina',
                      onPressed: () {
                        _applyPageSizeValue(_pageSizeController.text);
                      },
                      icon: const Icon(Icons.check),
                    ),
                  ],
                ),
                _PaginationStats(
                  progressLabel: widget.controller.progressLabel,
                  totalRows: widget.totalRows ?? widget.controller.totalItems,
                  selectedRows: widget.selectedRows,
                ),
                if (!widget.controller.isInfinite)
                  Wrap(
                    spacing: 6,
                    children: [
                      IconButton(
                        tooltip: 'Prima pagina',
                        onPressed: widget.controller.canGoFirst
                            ? () async {
                                widget.controller.goToFirstPage();
                                await widget.onFirstPage?.call();
                              }
                            : null,
                        icon: const Icon(Icons.first_page),
                      ),
                      IconButton(
                        tooltip: 'Pagina precedente',
                        onPressed: widget.controller.canGoPrevious
                            ? () async {
                                widget.controller.goToPreviousPage();
                                await widget.onPreviousPage?.call();
                              }
                            : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      IconButton(
                        tooltip: 'Pagina successiva',
                        onPressed: widget.controller.canGoNext
                            ? () async {
                                widget.controller.goToNextPage();
                                await widget.onNextPage?.call();
                              }
                            : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                      IconButton(
                        tooltip: 'Ultima pagina',
                        onPressed: widget.controller.canGoLast
                            ? () async {
                                widget.controller.goToLastPage();
                                await widget.onLastPage?.call();
                              }
                            : null,
                        icon: const Icon(Icons.last_page),
                      ),
                    ],
                  )
                else if (widget.controller.isLoadingMore)
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Caricamento delle prossime 50 righe in corso...'),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PaginationStats extends StatelessWidget {
  final String progressLabel;
  final int? totalRows;
  final int selectedRows;

  const _PaginationStats({
    required this.progressLabel,
    required this.totalRows,
    required this.selectedRows,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipStyle = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w700,
    );
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          progressLabel,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        _StatPill(
          label: 'Righe tot:',
          value: totalRows?.toString() ?? '-',
          style: chipStyle,
        ),
        _StatPill(
          label: 'Righe selezionate:',
          value: selectedRows.toString(),
          style: chipStyle,
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? style;

  const _StatPill({
    required this.label,
    required this.value,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text('$label $value', style: style),
    );
  }
}
