import 'dart:async';

import 'package:flutter/material.dart';
import 'prodotti_gestisci.code.dart';
import '../class_prodotti.dart';
import '../prodotto_filters.dart';
import '../prodotti_crea/prodotti_crea.gui.dart';
import 'prodotti_gestisci_view.gui.dart';
import '../../theme/theme.dart';
import '../../importer/csv_import_dialog.dart';
import '../../importer/csv_export_dialog.dart';
import '../../notification/notification_service.dart';
import '../../settings/app_settings.dart';
import '../../reuse_class/gui/global_pagination_bar.dart';
import '../../reuse_class/logic/global_pagination_controller.dart';
import '../../reuse_class/gui/searchable_checkbox_dialog.dart';
import '../../reuse_class/datagridview/datagridview.code.dart';
import '../../reuse_class/datagridview/datagridview.gui.dart';
import '../../reuse_class/datagridview/datagridview_image_preview.dart';

// ---------------------------------------------------------------------------
// Costanti
// ---------------------------------------------------------------------------

const double _kDesktopBreakpoint = 800;
// TEST DISATTIVATO 1: field della colonna checkbox nativa.
// const String _kFieldSelection = '__selection';
// TEST DISATTIVATO: field prodotto usato dalla griglia reale, non dal demo docs.
// const String _kFieldProductId = '__productId';

// TEST DISATTIVATO 4: logger usato solo dalla selezione custom.
// final _log = AppLogger();

// ---------------------------------------------------------------------------
// Enum azioni contesto
// ---------------------------------------------------------------------------

enum _ProductContextAction { modifica, elimina, crea }

// ---------------------------------------------------------------------------
// Utility globale: viewer immagine
// ---------------------------------------------------------------------------

// DISATTIVATO baseline DataGrid: viewer immagine usato dal renderer custom.
// ignore: unused_element
Future<void> _openImageViewer(
  BuildContext context,
  String? imageUrl, {
  required String title,
}) async {
  final safeUrl = (imageUrl ?? '').trim();
  if (safeUrl.isEmpty) return;

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980, maxHeight: 760),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: InteractiveViewer(
                  minScale: 0.7,
                  maxScale: 5,
                  child: ColoredBox(
                    color: Colors.black,
                    child: Center(
                      child: Image.network(
                        safeUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.broken_image_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// ---------------------------------------------------------------------------
// Dialogo conferma eliminazione
// ---------------------------------------------------------------------------

Future<bool> _confirmDeleteDialog(
  BuildContext context, {
  required List<ProdottoGlobal> products,
}) async {
  final isBulk = products.length > 1;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(isBulk ? 'Elimina prodotti selezionati' : 'Elimina prodotto'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isBulk
                  ? 'Confermi eliminazione dei seguenti ${products.length} prodotti?'
                  : 'Confermi eliminazione di "${products.first.nome}"?',
            ),
            if (isBulk) ...[
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: products
                        .map(
                          (p) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              '- ${p.nome ?? 'Prodotto senza nome'}'
                              '${(p.sku ?? '').trim().isEmpty ? '' : ' (SKU: ${p.sku})'}',
                            ),
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
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Elimina'),
        ),
      ],
    ),
  );
  return result == true;
}

// ===========================================================================
// ProdottiGestisciPage — root widget
// ===========================================================================

class ProdottiGestisciPage extends StatefulWidget {
  const ProdottiGestisciPage({super.key});

  @override
  ProdottiGestisciPageState createState() => ProdottiGestisciPageState();
}

class ProdottiGestisciPageState extends State<ProdottiGestisciPage>
    with AutomaticKeepAliveClientMixin<ProdottiGestisciPage> {
  // ── Controller e settings ────────────────────────────────────────────────
  final _controller = ProdottiGestioneController();
  final _appSettings = AppSettings();
  final _paginationController = GlobalPaginationController<ProdottoGlobal>();
  final _scrollController = ScrollController();
  final _gridKey = GlobalKey<_ProductsGridState>();
  final ValueNotifier<ProdottoGlobal?> _selectedProductNotifier =
      ValueNotifier<ProdottoGlobal?>(null);
  final ValueNotifier<bool> _selectedProductVariantsLoading =
      ValueNotifier<bool>(false);

  // ── Stato colonne ────────────────────────────────────────────────────────
  Set<ProductGridColumnId> _visibleColumns = defaultProductGridColumns.toSet();
  bool _hasStoredColumns = false;

  // ── Busy overlay ─────────────────────────────────────────────────────────
  int _busyDepth = 0;
  String _busyMessage = 'Caricamento in corso...';

  bool get _isBusy => _busyDepth > 0;
  List<ProdottoGlobal> get _visibleProducts => _paginationController.items;

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadProducts();
    _initSettings();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _paginationController.dispose();
    _selectedProductNotifier.dispose();
    _selectedProductVariantsLoading.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  // ── Busy helpers ─────────────────────────────────────────────────────────

  void _pushBusy(String message) => _setBusy(_busyDepth + 1, message);
  void _popBusy() {
    if (_busyDepth <= 0) return;
    _setBusy(
      _busyDepth - 1,
      _busyDepth == 1 ? 'Caricamento in corso...' : _busyMessage,
    );
  }

  void _setBusy(int depth, String message) {
    _busyDepth = depth;
    _busyMessage = message;
    if (mounted) setState(() {});
  }

  Future<T> _runBusy<T>(String message, Future<T> Function() action) async {
    _pushBusy(message);
    try {
      return await action();
    } finally {
      _popBusy();
    }
  }

  // ── Inizializzazione ─────────────────────────────────────────────────────

  Future<void> _initSettings() async {
    await _runBusy('Inizializzazione...', () async {
      await _appSettings.init();
      await _paginationController.loadFromSettings(_appSettings);
      _controller.setPersistedAdvancedFiltersEnabled(
        _appSettings.persistProductFilters,
      );
      _controller.setNascondiProdottiEsauriti(
        _appSettings.hideOutOfStockProducts,
      );
      _hasStoredColumns = _appSettings.visibleProductGridColumns.isNotEmpty;
      _visibleColumns = _resolveColumns(_appSettings.visibleProductGridColumns);
      _syncPagination();
      if (mounted) setState(() {});
    });
  }

  Future<void> _setHideOutOfStockProducts(bool value) async {
    _controller.setNascondiProdottiEsauriti(value);
    await _appSettings.setHideOutOfStockProducts(value);
    _refresh();
  }

  Set<ProductGridColumnId> _resolveColumns(List<String> keys) {
    if (keys.isEmpty) return defaultProductGridColumns.toSet();
    final resolved = <ProductGridColumnId>{};
    for (final key in keys) {
      for (final col in ProductGridColumnId.values) {
        if (col.storageKey == key) {
          resolved.add(col);
          break;
        }
      }
    }
    return resolved.isEmpty ? defaultProductGridColumns.toSet() : resolved;
  }

  // ── Caricamento prodotti ─────────────────────────────────────────────────

  Future<void> _loadProducts({bool forceRefresh = false}) async {
    await _runBusy('Caricamento prodotti in corso...', () async {
      await _controller.caricaProdotti(forceRefresh: forceRefresh);
      _paginationController.goToFirstPage();
      _syncPagination(jumpTop: true);
      _syncSelectedProductDisplay();
      final warning = _controller.consumeLastLoadWarning();
      if (mounted && warning != null && warning.isNotEmpty) {
        NotificationService.instance.messageBar(
          'warning',
          'prodotti_gestisci',
          warning,
        );
      }
      if (mounted) setState(() {});
    });
  }

  void _syncPagination({bool jumpTop = false}) {
    _paginationController.syncLocalItems(_visibleProductsSource);
    if (jumpTop && _scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  List<ProdottoGlobal> get _visibleProductsSource => _controller.prodotti;

  void _syncSelectedProductDisplay() {
    _selectedProductNotifier.value = _controller.prodottoSelezionato;
    if (_selectedProductNotifier.value == null) {
      _selectedProductVariantsLoading.value = false;
    }
  }

  void _handleProductSelected(ProdottoGlobal product) {
    _selectedProductNotifier.value = _controller.prodottoSelezionato;
    final needsVariants = product.variations?.isNotEmpty ?? false;
    if (!needsVariants || (product.varianti?.isNotEmpty ?? false)) {
      _selectedProductVariantsLoading.value = false;
      return;
    }
    _selectedProductVariantsLoading.value = true;
    unawaited(_loadSelectedProductVariants(product));
  }

  Future<void> _loadSelectedProductVariants(ProdottoGlobal product) async {
    final productId = product.id;
    if (productId == null || productId <= 0) {
      _selectedProductVariantsLoading.value = false;
      return;
    }

    await _controller.caricaVariantiProdottoSelezionato();
    if (!mounted) return;

    if (_selectedProductNotifier.value?.id == productId) {
      _selectedProductNotifier.value =
          _controller.prodottoSelezionato ?? product;
    }
    _selectedProductVariantsLoading.value = false;
  }

  // ── Scroll infinito ──────────────────────────────────────────────────────

  void _onScroll() {
    if (_isBusy ||
        !_paginationController.isInfinite ||
        !_paginationController.hasMore ||
        !_scrollController.hasClients) {
      return;
    }
    if (_scrollController.position.extentAfter > 240) return;

    _paginationController.goToNextPage();
    _syncPagination();
  }

  // ── Paginazione ──────────────────────────────────────────────────────────

  Future<void> _handlePageSizeOrModeChanged(GlobalPageMode _, int __) async {
    if (_isBusy) return;
    _syncPagination(jumpTop: true);
    if (mounted) setState(() {});
  }

  Future<void> _goFirstPage() async {
    if (_isBusy) return;
    _paginationController.goToFirstPage();
    _syncPagination(jumpTop: true);
  }

  Future<void> _goPreviousPage() async {
    if (_isBusy) return;
    _paginationController.goToPreviousPage();
    _syncPagination(jumpTop: true);
  }

  Future<void> _goNextPage() async {
    if (_isBusy) return;
    _paginationController.goToNextPage();
    _syncPagination(jumpTop: true);
  }

  Future<void> _goLastPage() async {
    if (_isBusy) return;
    _paginationController.goToLastPage();
    _syncPagination(jumpTop: true);
  }

  // ── Azioni prodotto ──────────────────────────────────────────────────────

  Future<void> _handleProductAction(
    _ProductContextAction action,
    ProdottoGlobal product,
  ) async {
    switch (action) {
      case _ProductContextAction.crea:
        final created = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => const ProdottiCreaPage()),
        );
        if (created == true) await _loadProducts(forceRefresh: true);

      case _ProductContextAction.modifica:
        final updated = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => ProdottiCreaPage(prodottoDaModificare: product),
          ),
        );
        if (updated == true) await _loadProducts(forceRefresh: true);

      case _ProductContextAction.elimina:
        await _deleteProducts(product);
    }
  }

  Future<void> _deleteProducts(ProdottoGlobal anchor) async {
    final selected = _controller.selectedProducts;
    final useBulk =
        _controller.selectedProductsCount > 1 &&
        selected.any((p) => p.id == anchor.id);
    final toDelete = useBulk ? selected : [anchor];

    final confirmed = await _confirmDeleteDialog(context, products: toDelete);
    if (!confirmed || !mounted) return;

    final label = useBulk
        ? 'Eliminazione ${toDelete.length} prodotti...'
        : 'Eliminazione prodotto...';

    final (bulkResult, success) = await _runBusy(label, () async {
      if (useBulk) {
        final r = await _controller.deleteSelectedProducts(
          force: _appSettings.forceDelete,
        );
        return (r, r.failedCount == 0);
      } else {
        final ok = await _controller.eliminaProdotto(anchor.id ?? 0);
        return (null, ok);
      }
    });

    if (!mounted) return;

    final severity = success
        ? 'successo'
        : (bulkResult?.successCount ?? 0) > 0
        ? 'warning'
        : 'errore';

    final message = success
        ? useBulk
              ? bulkResult!.message
              : 'Prodotto eliminato con successo.'
        : useBulk
        ? (bulkResult?.message ?? 'Eliminazione parziale.')
        : 'Eliminazione non riuscita.';

    NotificationService.instance.messageBar(
      'prodotti_gestisci',
      severity,
      message,
    );
    if (success || (bulkResult?.successCount ?? 0) > 0) {
      await _loadProducts(forceRefresh: true);
    }
  }

  Future<void> _handleBulkDelete() async {
    if (_isBusy || !_controller.hasSelectedProducts) return;
    final result = await _runBusy(
      'Eliminazione prodotti selezionati...',
      () => _controller.deleteSelectedProducts(force: _appSettings.forceDelete),
    );
    if (!mounted) return;
    NotificationService.instance.messageBar(
      result.failedCount == 0 ? 'successo' : 'warning',
      'prodotti_gestisci',
      result.message,
    );
    await _loadProducts(forceRefresh: true);
    if (mounted) setState(() {});
  }

  Future<void> _deleteFromGrid(ProdottoGlobal? product) async {
    if (_isBusy) return;
    if (_controller.hasSelectedProducts) {
      await _handleBulkDelete();
      return;
    }
    if (product != null) await _deleteProducts(product);
  }

  void _selectAllVisibleProducts() {
    if (_isBusy || _visibleProducts.isEmpty) return;
    final ids = _visibleProducts
        .map((product) => product.id)
        .whereType<int>()
        .where((id) => id > 0)
        .toSet();
    _controller.setBulkSelectionByIds(ids);
    _refresh();
  }

  void _clearGridSelection() {
    if (_controller.hasSelectedProducts) {
      _controller.clearBulkSelection();
      _refresh();
    }
  }

  Future<void> _showContextMenu(
    TapDownDetails details,
    ProdottoGlobal product,
  ) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final action = await showMenu<_ProductContextAction>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(details.globalPosition, details.globalPosition),
        Offset.zero & overlay.size,
      ),
      items: const [
        PopupMenuItem(
          value: _ProductContextAction.modifica,
          child: Row(
            children: [
              Icon(Icons.edit_outlined),
              SizedBox(width: 8),
              Text('Modifica'),
            ],
          ),
        ),
        PopupMenuItem(
          value: _ProductContextAction.elimina,
          child: Row(
            children: [
              Icon(Icons.delete_outline),
              SizedBox(width: 8),
              Text('Elimina'),
            ],
          ),
        ),
        PopupMenuItem(
          value: _ProductContextAction.crea,
          child: Row(
            children: [
              Icon(Icons.add_circle_outline),
              SizedBox(width: 8),
              Text('Crea'),
            ],
          ),
        ),
      ],
    );
    if (action != null && mounted) {
      await _handleProductAction(action, product);
      _refresh();
    }
  }

  // ── Colonne ──────────────────────────────────────────────────────────────

  Future<void> _openColumnPicker() async {
    if (_isBusy) return;
    final allLabels = ProductGridColumnId.values.map((c) => c.label).toList();
    final selected = await SearchableCheckboxDialog.show(
      context,
      title: 'Colonne visibili',
      inputLabel: 'Cerca colonna',
      input_list: allLabels,
      preselected_list: ProductGridColumnId.values
          .where(_visibleColumns.contains)
          .map((c) => c.label)
          .toList(),
    );
    if (!mounted || selected == null || selected.isEmpty) return;

    final next = ProductGridColumnId.values
        .where((c) => selected.contains(c.label))
        .toSet();
    if (next.isEmpty) return;

    await _appSettings.setVisibleProductGridColumns(
      ProductGridColumnId.values
          .where(next.contains)
          .map((c) => c.storageKey)
          .toList(),
    );
    setState(() => _visibleColumns = next);
  }

  Set<ProductGridColumnId> _effectiveColumns(BuildContext context) {
    if (_hasStoredColumns) return _visibleColumns;
    final isSmall = MediaQuery.sizeOf(context).width < _kDesktopBreakpoint;
    if (!isSmall) return _visibleColumns;
    return const {
      ProductGridColumnId.preview,
      ProductGridColumnId.nome,
      ProductGridColumnId.prezzo,
      ProductGridColumnId.disponibilita,
      ProductGridColumnId.quantita,
    };
  }

  // ── Refresh stato ────────────────────────────────────────────────────────

  void _refresh() {
    if (!mounted) return;
    _syncSelectedProductDisplay();
    setState(() => _syncPagination());
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < _kDesktopBreakpoint;
              return isSmall ? _buildMobileLayout() : _buildDesktopLayout();
            },
          ),
          floatingActionButton: LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < _kDesktopBreakpoint;
              return isSmall ? _buildFAB() : const SizedBox.shrink();
            },
          ),
        ),
        if (_isBusy)
          Positioned.fill(child: _BusyOverlay(message: _busyMessage)),
      ],
    );
  }

  Widget _buildMobileLayout() => Column(
    children: [Expanded(child: _buildProductList(showDetailsInPage: true))],
  );

  Widget _buildDesktopLayout() => Row(
    children: [
      Expanded(flex: 3, child: _buildProductList()),
      VerticalDivider(width: 1, color: Theme.of(context).dividerColor),
      Expanded(
        flex: 2,
        child: ValueListenableBuilder<ProdottoGlobal?>(
          valueListenable: _selectedProductNotifier,
          builder: (context, selectedProduct, _) {
            return Stack(
              children: [
                selectedProduct != null
                    ? ValueListenableBuilder<bool>(
                        valueListenable: _selectedProductVariantsLoading,
                        builder: (context, isLoading, __) {
                          return ProdottoDettagliView(
                            prodotto: selectedProduct,
                            varianteSelezionata:
                                _controller.varianteSelezionata,
                            controller: _controller,
                            variantsLoading: isLoading,
                            onReload: () => _loadProducts(forceRefresh: true),
                            onProductDeleted: _refresh,
                          );
                        },
                      )
                    : _buildEmptyState(),
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: _GradientFAB(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ProdottiCreaPage(),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ],
  );

  Widget _buildProductList({bool showDetailsInPage = false}) {
    return Column(
      children: [
        _FiltersBar(
          controller: _controller,
          selectedCount: _controller.selectedProductsCount,
          onStateChanged: _refresh,
          onHideOutOfStockChanged: _setHideOutOfStockProducts,
          onRefresh: () => _loadProducts(forceRefresh: true),
          onOpenColumns: _openColumnPicker,
        ),
        Expanded(
          child: _ProductsGrid(
            key: _gridKey,
            controller: _controller,
            products: _visibleProducts,
            scrollController: _scrollController,
            visibleColumns: _effectiveColumns(context),
            onStateChanged: _refresh,
            onSecondaryTapDown: _showContextMenu,
            onDeleteSelected: _handleBulkDelete,
            onSelectAllVisible: _selectAllVisibleProducts,
            onClearSelection: _clearGridSelection,
            onDeleteFromGrid: _deleteFromGrid,
            onProductSelected: _handleProductSelected,
            selectAllShortcut: _appSettings.shortcutSelectAll,
            deleteShortcut: _appSettings.shortcutDelete,
            escapeShortcut: _appSettings.shortcutEscape,
            onOpenProductDetails: showDetailsInPage
                ? (product) async {
                    await Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => ProdottoDettagliView(
                          prodotto: product,
                          varianteSelezionata: _controller.varianteSelezionata,
                          controller: _controller,
                          variantsLoading: false,
                          showCloseButton: true,
                          onReload: () => _loadProducts(forceRefresh: true),
                          onProductDeleted: _refresh,
                        ),
                      ),
                    );
                    if (mounted) setState(() {});
                  }
                : null,
          ),
        ),
        GlobalPaginationBar(
          settings: _appSettings,
          controller: _paginationController,
          totalRows: _controller.hasFiltroAttivo
              ? _controller.prodotti.length
              : _paginationController.totalItems ?? _controller.prodotti.length,
          selectedRows: _controller.selectedProductsCount,
          onFirstPage: _goFirstPage,
          onPreviousPage: _goPreviousPage,
          onNextPage: _goNextPage,
          onLastPage: _goLastPage,
          onModeOrPageSizeChanged: _handlePageSizeOrModeChanged,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: theme.iconTheme.color?.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Seleziona un prodotto',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
          ),
          Text(
            'per vedere i dettagli',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() => _GradientFAB(
    onPressed: () => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ProdottiCreaPage())),
  );
}

// ===========================================================================
// _ProductsGrid — griglia riusabile stile DataGridView C#
// ===========================================================================

class _ProductsGrid extends StatefulWidget {
  final ProdottiGestioneController controller;
  final List<ProdottoGlobal> products;
  final ScrollController scrollController;
  final Set<ProductGridColumnId> visibleColumns;
  final VoidCallback onStateChanged;
  final Future<void> Function(TapDownDetails, ProdottoGlobal)
  onSecondaryTapDown;
  final Future<void> Function(ProdottoGlobal)? onOpenProductDetails;
  final Future<void> Function()? onDeleteSelected;
  final VoidCallback onSelectAllVisible;
  final VoidCallback onClearSelection;
  final ValueChanged<ProdottoGlobal?> onDeleteFromGrid;
  final void Function(ProdottoGlobal product) onProductSelected;
  final String selectAllShortcut;
  final String deleteShortcut;
  final String escapeShortcut;

  const _ProductsGrid({
    super.key,
    required this.controller,
    required this.products,
    required this.scrollController,
    required this.visibleColumns,
    required this.onStateChanged,
    required this.onSecondaryTapDown,
    required this.onSelectAllVisible,
    required this.onClearSelection,
    required this.onDeleteFromGrid,
    required this.onProductSelected,
    required this.selectAllShortcut,
    required this.deleteShortcut,
    required this.escapeShortcut,
    this.onOpenProductDetails,
    this.onDeleteSelected,
  });

  @override
  State<_ProductsGrid> createState() => _ProductsGridState();
}

class _ProductsGridState extends State<_ProductsGrid> {
  List<DataGridViewColumn> _buildColumns() {
    return ProductGridColumnId.values
        .where(widget.visibleColumns.contains)
        .map(
          (colId) => DataGridViewColumn(
            id: colId.storageKey,
            label: colId.label,
            width: _columnWidth(colId),
            numeric: _isNumericColumn(colId),
          ),
        )
        .toList();
  }

  List<DataGridViewRowData<ProdottoGlobal>> _buildRows() {
    final errorColor = Theme.of(context).colorScheme.error;
    return widget.products.map((product) {
      final info = ProdottoDisplayInfo.fromProdotto(product);
      final pricing = ProdottoUtils.getPricingInfo(product);
      return DataGridViewRowData<ProdottoGlobal>(
        id: '${product.id ?? 0}',
        value: product,
        foregroundColor: info.inStock ? null : errorColor,
        cells: <String, Widget>{
          ProductGridColumnId.preview.storageKey: Center(
            child: DataGridViewImagePreview(
              imageUrl: product.immagineUrl,
              semanticLabel: 'Anteprima ${info.nome}',
              size: 56,
              muted: !info.inStock,
            ),
          ),
          ProductGridColumnId.nome.storageKey: Text(
            info.nome,
            overflow: TextOverflow.ellipsis,
          ),
          ProductGridColumnId.sku.storageKey: Text(
            info.sku,
            overflow: TextOverflow.ellipsis,
          ),
          ProductGridColumnId.categoria.storageKey: Text(
            info.categoria,
            overflow: TextOverflow.ellipsis,
          ),
          ProductGridColumnId.prezzo.storageKey: Text(pricing.prezzoLabel),
          ProductGridColumnId.sconto.storageKey: Text(pricing.scontoLabel),
          ProductGridColumnId.disponibilita.storageKey: Text(
            info.disponibilita,
            overflow: TextOverflow.ellipsis,
          ),
          ProductGridColumnId.quantita.storageKey: Text(
            '${product.quantitaTotaleVarianti}',
          ),
          ProductGridColumnId.varianti.storageKey: Text(
            '${product.varianti?.length ?? 0}',
          ),
          ProductGridColumnId.stato.storageKey: Text(
            info.status,
            overflow: TextOverflow.ellipsis,
          ),
          ProductGridColumnId.marca.storageKey: Text(
            product.marca ?? '-',
            overflow: TextOverflow.ellipsis,
          ),
        },
      );
    }).toList();
  }

  static double _columnWidth(ProductGridColumnId id) => switch (id) {
    ProductGridColumnId.preview => 112,
    ProductGridColumnId.nome => 240,
    ProductGridColumnId.sku => 150,
    ProductGridColumnId.categoria => 180,
    ProductGridColumnId.prezzo || ProductGridColumnId.sconto => 120,
    ProductGridColumnId.disponibilita => 140,
    ProductGridColumnId.quantita || ProductGridColumnId.varianti => 100,
    ProductGridColumnId.stato => 120,
    ProductGridColumnId.marca => 140,
  };

  static bool _isNumericColumn(ProductGridColumnId id) =>
      id == ProductGridColumnId.prezzo ||
      id == ProductGridColumnId.sconto ||
      id == ProductGridColumnId.quantita ||
      id == ProductGridColumnId.varianti;

  Future<void> _selectProduct(ProdottoGlobal product) async {
    widget.controller.selezionaProdottoLocal(product);
    widget.onProductSelected(product);
  }

  void _toggleBulkSelection(ProdottoGlobal product, bool selected) {
    final id = product.id;
    if (id == null || id <= 0) return;
    final current = widget.controller.selectedProductIds;
    final next = <int>{...current};
    if (selected) {
      next.add(id);
    } else {
      next.remove(id);
    }
    widget.controller.setBulkSelectionByIds(next);
    widget.onStateChanged();
  }

  void _toggleAllVisible(bool selected) {
    if (selected) {
      final ids = widget.products
          .map((product) => product.id)
          .whereType<int>()
          .where((id) => id > 0);
      widget.controller.setBulkSelectionByIds({
        ...widget.controller.selectedProductIds,
        ...ids,
      });
    } else {
      final visibleIds = widget.products
          .map((product) => product.id)
          .whereType<int>()
          .toSet();
      widget.controller.setBulkSelectionByIds(
        widget.controller.selectedProductIds.where(
          (id) => !visibleIds.contains(id),
        ),
      );
    }
    widget.onStateChanged();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = widget.controller.selectedProductsCount;
    return Container(
      padding: const EdgeInsets.all(15),
      child: Column(
        children: [
          if (selectedCount > 0) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '$selectedCount prodotti selezionati',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      widget.controller.clearBulkSelection();
                      widget.onStateChanged();
                    },
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Deseleziona'),
                  ),
                  FilledButton.icon(
                    onPressed: widget.onDeleteSelected,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Elimina'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: DataGridView<ProdottoGlobal>(
              columns: _buildColumns(),
              rows: _buildRows(),
              verticalScrollController: widget.scrollController,
              selectedRowId:
                  '${widget.controller.prodottoSelezionato?.id ?? ''}',
              selectedRowIds: widget.controller.selectedProductIds
                  .map((id) => '$id')
                  .toSet(),
              showCheckboxes: true,
              selectAllShortcut: widget.selectAllShortcut,
              deleteShortcut: widget.deleteShortcut,
              escapeShortcut: widget.escapeShortcut,
              onRowChecked: _toggleBulkSelection,
              onSelectAll: (selected) {
                if (selected) {
                  widget.onSelectAllVisible();
                } else {
                  _toggleAllVisible(false);
                }
              },
              onDeleteShortcut: widget.onDeleteFromGrid,
              onEscapeShortcut: widget.onClearSelection,
              onRowSelected: (product) {
                Future<void>(() => _selectProduct(product));
              },
              onRowDoubleTap: (product) {
                if (widget.onOpenProductDetails == null) return;
                Future<void>(() async {
                  await _selectProduct(product);
                  await widget.onOpenProductDetails!(product);
                });
              },
              onRowSecondaryTap: (details, product) {
                return Future<void>(() async {
                  await _selectProduct(product);
                  await widget.onSecondaryTapDown(details, product);
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// _BusyOverlay
// ===========================================================================

class _BusyOverlay extends StatelessWidget {
  final String message;
  const _BusyOverlay({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AbsorbPointer(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Material(
              elevation: 12,
              borderRadius: BorderRadius.circular(18),
              color: theme.dialogTheme.backgroundColor ?? theme.cardColor,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 22,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 34,
                      height: 34,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Operazione in corso',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// _GradientFAB
// ===========================================================================

class _GradientFAB extends StatelessWidget {
  final VoidCallback onPressed;
  const _GradientFAB({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<AppColorExtension>()!;
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: 'Crea Nuovo Prodotto',
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              customColors.fabGradientStart,
              customColors.fabGradientEnd,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          Icons.add,
          size: 28,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }
}

// ===========================================================================
// _PrimaryText
// ===========================================================================

// TEST DISATTIVATO: renderer custom della griglia reale.
// ignore: unused_element
class _PrimaryText extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;

  const _PrimaryText({
    required this.title,
    required this.subtitle,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: isSelected ? theme.primaryColor : null,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// _StatusChip
// ===========================================================================

// TEST DISATTIVATO: renderer custom della griglia reale.
// ignore: unused_element
class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// _ImageCell
// ===========================================================================

// TEST DISATTIVATO: renderer custom della griglia reale.
// ignore: unused_element
class _ImageCell extends StatelessWidget {
  final String? imageUrl;
  final String semanticLabel;
  final VoidCallback onOpenLarge;

  const _ImageCell({
    required this.imageUrl,
    required this.semanticLabel,
    required this.onOpenLarge,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = (imageUrl ?? '').trim().isNotEmpty;
    final theme = Theme.of(context);

    return Tooltip(
      waitDuration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.16),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      richMessage: hasImage
          ? TextSpan(
              children: [
                WidgetSpan(
                  child: SizedBox(
                    width: 132,
                    height: 132,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(imageUrl!, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ],
            )
          : const TextSpan(text: ''),
      child: GestureDetector(
        onTap: hasImage ? onOpenLarge : null,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.primaryColor.withValues(alpha: 0.18),
            ),
            color: theme.primaryColor.withValues(alpha: 0.04),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: hasImage
                ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(context),
                  )
                : _placeholder(context),
          ),
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) => Icon(
    Icons.image_outlined,
    color: Theme.of(context).primaryColor.withValues(alpha: 0.55),
    semanticLabel: semanticLabel,
  );
}

// ===========================================================================
// _FiltersBar
// ===========================================================================

class _FiltersBar extends StatefulWidget {
  final ProdottiGestioneController controller;
  final int selectedCount;
  final VoidCallback onStateChanged;
  final ValueChanged<bool> onHideOutOfStockChanged;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onOpenColumns;

  const _FiltersBar({
    required this.controller,
    required this.selectedCount,
    required this.onStateChanged,
    required this.onHideOutOfStockChanged,
    this.onRefresh,
    this.onOpenColumns,
  });

  @override
  _FiltersBarState createState() => _FiltersBarState();
}

class _FiltersBarState extends State<_FiltersBar> {
  final _valueCtrl = TextEditingController();
  final _campoCtrl = TextEditingController();
  CampoFiltroProdotto _campo = CampoFiltroProdotto.sku;
  OperatoreFiltroProdotto _operatore = OperatoreFiltroProdotto.contiene;

  @override
  void initState() {
    super.initState();
    _campoCtrl.text = _campoLabel(_campo);
    _valueCtrl.text = widget.controller.filtroRicerca;
  }

  @override
  void dispose() {
    _valueCtrl.dispose();
    _campoCtrl.dispose();
    super.dispose();
  }

  String _campoLabel(CampoFiltroProdotto c) =>
      ProdottoFilterEngine.campoLabel(c);
  String _operatoreLabel(OperatoreFiltroProdotto o) =>
      ProdottoFilterEngine.operatoreLabel(o);
  String _operatoreTooltip(OperatoreFiltroProdotto o) =>
      ProdottoFilterEngine.operatoreTooltip(o);
  bool _operatoreDisponibile(OperatoreFiltroProdotto o) =>
      ProdottoFilterEngine.supportsOperator(_campo, o);
  List<OperatoreFiltroProdotto> _operators() =>
      ProdottoFilterEngine.orderedOperators();

  String _ordinamentoLabel(OrdinamentoProdotti o) => switch (o) {
    OrdinamentoProdotti.nomeCrescente => 'Nome (A-Z)',
    OrdinamentoProdotti.nomeDecrescente => 'Nome (Z-A)',
    OrdinamentoProdotti.prezzoCrescente => 'Prezzo (Crescente)',
    OrdinamentoProdotti.prezzoDecrescente => 'Prezzo (Decrescente)',
    OrdinamentoProdotti.nessuno => 'Ordina per...',
  };

  void _onCampoChanged(CampoFiltroProdotto value) {
    final text = _valueCtrl.text;
    setState(() {
      if (_campo == CampoFiltroProdotto.ricercaRapida &&
          value != CampoFiltroProdotto.ricercaRapida) {
        widget.controller.cancellaFiltro();
      }
      _campo = value;
      _campoCtrl.text = _campoLabel(value);
      if (!_operatoreDisponibile(_operatore)) {
        _operatore =
            ProdottoFilterEngine.isNumericField(value) ||
                ProdottoFilterEngine.isBooleanField(value)
            ? OperatoreFiltroProdotto.uguale
            : OperatoreFiltroProdotto.contiene;
      }
      _valueCtrl.text = text;
      _valueCtrl.selection = TextSelection.collapsed(offset: text.length);
    });
    if (value == CampoFiltroProdotto.ricercaRapida) {
      widget.controller.setFiltroRicerca(text);
    }
    widget.onStateChanged();
  }

  void _applyFilter() {
    final raw = _valueCtrl.text.trim();
    if (raw.isEmpty) return;
    final resolved =
        ProdottoFilterEngine.resolveCampoFromInput(_campoCtrl.text) ?? _campo;
    if (resolved == CampoFiltroProdotto.ricercaRapida) {
      widget.controller.setFiltroRicerca(raw);
      widget.onStateChanged();
      return;
    }
    if (!_operatoreDisponibile(_operatore)) {
      NotificationService.instance.messageBar(
        'warning',
        'prodotti_gestisci',
        'Operatore non disponibile per il campo selezionato.',
      );
      return;
    }
    widget.controller.addFiltroProdotto(
      campo: resolved,
      operatore: _operatore,
      valoreInput: raw,
    );
    _valueCtrl.clear();
    widget.onStateChanged();
  }

  void _clearAll() {
    _valueCtrl.clear();
    widget.controller.cancellaFiltro();
    widget.controller.clearFiltriProdotto();
    widget.controller.setNascondiProdottiEsauriti(false);
    widget.onStateChanged();
    setState(() {});
  }

  Future<void> _showImport() async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CsvImportDialog(),
    );
    if (ok == true) {
      if (widget.onRefresh != null) {
        await widget.onRefresh!();
      } else {
        widget.onStateChanged();
      }
    }
  }

  Future<void> _showExport() async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CsvExportDialog(),
    );
    if (ok == true && context.mounted) {
      NotificationService.instance.messageBar(
        'successo',
        'prodotti_gestisci',
        'Export CSV completato con successo',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<AppColorExtension>()!;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Riga 1: input + pulsanti
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _valueCtrl,
                  decoration: InputDecoration(
                    labelText: _campo == CampoFiltroProdotto.ricercaRapida
                        ? 'Ricerca rapida'
                        : 'Valore filtro',
                    hintText: _campo == CampoFiltroProdotto.ricercaRapida
                        ? 'Cerca su tutti i campi'
                        : 'Es: Nike, 1, disponibile',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _valueCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() => _valueCtrl.clear());
                              if (_campo == CampoFiltroProdotto.ricercaRapida) {
                                widget.controller.cancellaFiltro();
                                widget.onStateChanged();
                              }
                            },
                          )
                        : null,
                  ),
                  onChanged: (v) {
                    if (_campo == CampoFiltroProdotto.ricercaRapida) {
                      widget.controller.setFiltroRicerca(v);
                      widget.onStateChanged();
                    }
                    setState(() {});
                  },
                  onSubmitted: (_) => _applyFilter(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<CampoFiltroProdotto>(
                  initialValue: _campo,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Campo filtro',
                    isDense: true,
                  ),
                  onChanged: (v) {
                    if (v != null) _onCampoChanged(v);
                  },
                  items: CampoFiltroProdotto.values
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(_campoLabel(c)),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<OperatoreFiltroProdotto>(
                  initialValue: _operatore,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Operatore',
                    isDense: true,
                  ),
                  onChanged: (v) {
                    if (v != null) setState(() => _operatore = v);
                  },
                  items: _operators()
                      .where(_operatoreDisponibile)
                      .map(
                        (o) => DropdownMenuItem(
                          value: o,
                          child: Tooltip(
                            waitDuration: const Duration(milliseconds: 850),
                            message: _operatoreTooltip(o),
                            child: Text(_operatoreLabel(o)),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _applyFilter,
                icon: const Icon(Icons.add),
                label: Text(
                  _campo == CampoFiltroProdotto.ricercaRapida
                      ? 'Applica ricerca'
                      : 'Aggiungi filtro',
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _showImport,
                icon: const Icon(Icons.upload_file),
                tooltip: 'Importa da CSV',
                style: IconButton.styleFrom(
                  backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                  foregroundColor: theme.primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _showExport,
                icon: const Icon(Icons.download),
                tooltip: 'Esporta in CSV',
                style: IconButton.styleFrom(
                  backgroundColor: customColors.successColor.withValues(
                    alpha: 0.1,
                  ),
                  foregroundColor: customColors.successColor,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: widget.onOpenColumns,
                icon: const Icon(Icons.view_column_outlined),
                tooltip: 'Scegli colonne',
                style: IconButton.styleFrom(
                  backgroundColor: theme.primaryColor.withValues(alpha: 0.08),
                  foregroundColor: theme.primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: widget.onRefresh == null
                    ? null
                    : () => widget.onRefresh!(),
                icon: const Icon(Icons.refresh),
                tooltip: 'Aggiorna cache e lista',
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary.withValues(
                    alpha: 0.1,
                  ),
                  foregroundColor: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 8),
          // Riga 2: chip filtri + badge selezione + cancella
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (widget.controller.nascondiProdottiEsauriti)
                      InputChip(
                        label: const Text('Esauriti nascosti'),
                        onDeleted: () {
                          widget.onHideOutOfStockChanged(false);
                          setState(() {});
                        },
                      ),
                    for (
                      int i = 0;
                      i < widget.controller.filtriProdottoAttivi.length;
                      i++
                    )
                      InputChip(
                        label: Text(
                          widget.controller.filtriProdottoAttivi[i].chipLabel,
                        ),
                        onDeleted: () {
                          widget.controller.removeFiltroProdottoAt(i);
                          widget.onStateChanged();
                        },
                      ),
                  ],
                ),
              ),
              _SelectedCountBadge(count: widget.selectedCount),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: widget.controller.nascondiProdottiEsauriti
                      ? theme.colorScheme.errorContainer.withValues(alpha: 0.45)
                      : theme.inputDecorationTheme.fillColor,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: widget.controller.nascondiProdottiEsauriti
                        ? theme.colorScheme.error.withValues(alpha: 0.5)
                        : theme.dividerColor.withValues(alpha: 0.55),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: widget.controller.nascondiProdottiEsauriti,
                      onChanged: (value) {
                        widget.onHideOutOfStockChanged(value ?? false);
                        setState(() {});
                      },
                      visualDensity: VisualDensity.compact,
                    ),
                    const Text('Non mostrare esauriti'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: widget.controller.hasFiltroAttivo ? _clearAll : null,
                icon: const Icon(Icons.clear_all),
                label: const Text('Cancella tutti'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Riga 3: ordinamento
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: theme.inputDecorationTheme.fillColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    theme.inputDecorationTheme.enabledBorder!.borderSide.color,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<OrdinamentoProdotti>(
                value: widget.controller.ordinamentoCorrente,
                isExpanded: true,
                icon: Icon(Icons.sort, color: theme.primaryColor),
                onChanged: (v) {
                  if (v != null) {
                    widget.controller.setOrdinamento(v);
                    widget.onStateChanged();
                  }
                },
                items: OrdinamentoProdotti.values
                    .map(
                      (o) => DropdownMenuItem(
                        value: o,
                        child: Text(_ordinamentoLabel(o)),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// _SelectedCountBadge
// ===========================================================================

class _SelectedCountBadge extends StatelessWidget {
  final int count;
  const _SelectedCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSelection = count > 0;
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: hasSelection
            ? theme.primaryColor.withValues(alpha: 0.10)
            : theme.disabledColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: hasSelection
              ? theme.primaryColor.withValues(alpha: 0.25)
              : theme.dividerColor.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        'Selezionati: $count',
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: hasSelection ? theme.primaryColor : null,
        ),
      ),
    );
  }
}
