import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math; // Necessario per la rotazione del banner
import 'prodotti_gestisci.code.dart';
import '../class_prodotti.dart';
import '../prodotti_crea/prodotti_crea.gui.dart';
import '../../theme/theme.dart';
import '../../importer/csv_import_dialog.dart';
import '../../importer/csv_export_dialog.dart';
import '../../notification/notification_service.dart';
import '../../login/jwt_api/adapter/platform_manager.dart';
import '../../settings/app_settings.dart';
import '../../reuse_class/gui/searchable_checkbox_dialog.dart';

// Funzione helper per convertire stringhe HEX in Color
Color hexToColor(String code) {
  final hexString = code.startsWith('#') ? code.substring(1) : code;
  final buffer = StringBuffer();
  if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
  buffer.write(hexString.replaceFirst('#', ''));

  try {
    return Color(int.parse(buffer.toString(), radix: 16));
  } catch (e) {
    return Colors.grey;
  }
}

enum _SelectedProductAction { modifica, elimina, crea }

class ProdottiGestisciPage extends StatefulWidget {
  const ProdottiGestisciPage({super.key});

  @override
  ProdottiGestisciPageState createState() => ProdottiGestisciPageState();
}

class ProdottiGestisciPageState extends State<ProdottiGestisciPage> {
  final ProdottiGestioneController _controller = ProdottiGestioneController();
  final AppSettings _appSettings = AppSettings();
  bool _multiSelectMode = false;

  void _syncMultiModeFromSelection() {
    final next = _controller.selectedProductsCount > 1;
    if (_multiSelectMode != next) {
      _multiSelectMode = next;
    }
  }

  void _toggleMultiSelectMode() {
    setState(() {
      _multiSelectMode = !_multiSelectMode;
      if (!_multiSelectMode) {
        _controller.clearBulkSelection();
      } else {
        final selectedId = _controller.prodottoSelezionato?.id;
        if (selectedId != null && selectedId > 0) {
          _controller.toggleProductBulkSelection(_controller.prodottoSelezionato!);
        }
      }
      _syncMultiModeFromSelection();
    });
  }

  Future<void> _applyCategoriesToSelectedProducts() async {
    try {
      final List<CategoriaProdotto> categorie = await PlatformManager.categorie
          .getCategories(perPage: 100);

      if (!mounted) return;

      final result =
          await showDialog<({List<CategoriaProdotto> selected, bool replace})>(
            context: context,
            builder: (ctx) => _BulkCategoryDialog(categorie: categorie),
          );

      if (result == null || result.selected.isEmpty) return;

      final updateResult = await _controller
          .bulkUpdateSelectedProductCategories(
            categorie: result.selected,
            replaceExisting: result.replace,
          );

      if (!mounted) return;
      NotificationService.instance.messageBar(
        updateResult.failedCount == 0 ? 'successo' : 'errore',
        'prodotti_gestisci',
        updateResult.message,
      );

      await _caricaProdotti();
      setState(() {
        _controller.clearBulkSelection();
        _multiSelectMode = false;
      });
    } catch (e) {
      if (!mounted) return;
      NotificationService.instance.messageBar(
        'errore',
        'prodotti_gestisci',
        'Errore caricamento categorie: $e',
      );
    }
  }

  Future<void> _handleProductAction(
    BuildContext context,
    _SelectedProductAction action,
    ProdottoGlobal prodotto,
  ) async {
    switch (action) {
      case _SelectedProductAction.crea:
        final created = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(builder: (_) => const ProdottiCreaPage()),
        );
        if (created == true) {
          await _caricaProdotti();
        }
        break;
      case _SelectedProductAction.modifica:
        final updated = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => ProdottiCreaPage(prodottoDaModificare: prodotto),
          ),
        );
        if (updated == true) {
          await _caricaProdotti();
        }
        break;
      case _SelectedProductAction.elimina:
        final bool? confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Elimina prodotto'),
            content: Text('Confermi eliminazione di "${prodotto.nome}"?'),
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

        if (confirmed != true) return;
        final prodottoId = prodotto.id ?? 0;
        if (prodottoId <= 0) {
          if (!context.mounted) return;
          NotificationService.instance.messageBar(
            'errore',
            'prodotti_gestisci',
            'ID prodotto non valido.',
          );
          return;
        }

        final removed = await _controller.eliminaProdotto(prodottoId);
        if (context.mounted) {
          NotificationService.instance.messageBar(
            removed ? 'successo' : 'errore',
            'prodotti_gestisci',
            removed
                ? 'Prodotto eliminato con successo.'
                : 'Eliminazione prodotto non riuscita.',
          );
        }
        if (removed) {
          await _caricaProdotti();
        }
        break;
    }
  }

  Future<void> _showProductContextMenu(
    BuildContext context,
    TapDownDetails details,
    ProdottoGlobal prodotto,
  ) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final selected = await showMenu<_SelectedProductAction>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(details.globalPosition, details.globalPosition),
        Offset.zero & overlay.size,
      ),
      items: const [
        PopupMenuItem(
          value: _SelectedProductAction.modifica,
          child: Row(
            children: [
              Icon(Icons.edit_outlined),
              SizedBox(width: 8),
              Text('Modifica'),
            ],
          ),
        ),
        PopupMenuItem(
          value: _SelectedProductAction.elimina,
          child: Row(
            children: [
              Icon(Icons.delete_outline),
              SizedBox(width: 8),
              Text('Elimina'),
            ],
          ),
        ),
        PopupMenuItem(
          value: _SelectedProductAction.crea,
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

    if (selected != null && context.mounted) {
      await _handleProductAction(context, selected, prodotto);
      _updateState();
    }
  }

  @override
  void initState() {
    super.initState();
    _caricaProdotti();
    _initSettings();
  }

  Future<void> _initSettings() async {
    await _appSettings.init();
    if (mounted) setState(() {});
  }

  Future<void> _caricaProdotti() async {
    await _controller.caricaProdotti();
    if (mounted) {
      setState(() {});
    }
  }

  void _updateState() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        final focused = FocusManager.instance.primaryFocus?.context?.widget;
        if (focused is EditableText) return KeyEventResult.ignored;

        if (_matchesShortcut(event, _appSettings.shortcutSelectAll)) {
          _controller.selectAllFilteredProducts();
          setState(() => _multiSelectMode = _controller.selectedProductsCount > 1);
          return KeyEventResult.handled;
        }
        if (_matchesShortcut(event, _appSettings.shortcutEscape) && _multiSelectMode) {
          setState(() {
            _controller.clearBulkSelection();
            _multiSelectMode = false;
          });
          return KeyEventResult.handled;
        }
        if (_matchesShortcut(event, _appSettings.shortcutDelete) &&
            _controller.selectedProductsCount > 0) {
          _handleBulkDeleteShortcut();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isSmallScreen = constraints.maxWidth < 800;
          if (isSmallScreen) {
            return _buildMobileLayout();
          } else {
            return _buildDesktopLayout();
          }
        },
      ),
      floatingActionButton: LayoutBuilder(
        builder: (context, constraints) {
          final bool isSmallScreen = constraints.maxWidth < 800;
          if (isSmallScreen) {
            return _buildFAB();
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    ));
  }

  Future<void> _handleBulkDeleteShortcut() async {
    final result = await _controller.deleteSelectedProducts(
      force: _appSettings.forceDelete,
    );
    if (!mounted) return;
    NotificationService.instance.messageBar(
      result.failedCount == 0 ? 'successo' : 'warning',
      'prodotti_gestisci',
      result.message,
    );
    await _caricaProdotti();
    setState(() {
      _multiSelectMode = false;
    });
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Expanded(
          flex: 2,
          child: _ProductListWidget(
            controller: _controller,
            onStateChanged: _updateState,
            multiSelectMode: _multiSelectMode,
            onToggleMultiSelectMode: _toggleMultiSelectMode,
            onMultiSelectChanged: (enabled) {
              setState(() {
                _multiSelectMode = enabled;
              });
            },
            onApplyCategoriesToSelection: _applyCategoriesToSelectedProducts,
            onSecondaryTapDown: (details, prodotto) async {
              await _showProductContextMenu(context, details, prodotto);
            },
          ),
        ),
        if (_controller.hasProdottoSelezionato) ...[
          Divider(height: 1, color: Theme.of(context).dividerColor),
          Expanded(
            flex: 1,
            child: _ProductDetailsWidget(
              controller: _controller,
              onStateChanged: _updateState,
              onReload: _caricaProdotti,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _ProductListWidget(
            controller: _controller,
            onStateChanged: _updateState,
            multiSelectMode: _multiSelectMode,
            onToggleMultiSelectMode: _toggleMultiSelectMode,
            onMultiSelectChanged: (enabled) {
              setState(() {
                _multiSelectMode = enabled;
              });
            },
            onApplyCategoriesToSelection: _applyCategoriesToSelectedProducts,
            onSecondaryTapDown: (details, prodotto) async {
              await _showProductContextMenu(context, details, prodotto);
            },
          ),
        ),
        VerticalDivider(width: 1, color: Theme.of(context).dividerColor),
        Expanded(
          flex: 2,
          child: Stack(
            children: [
              _controller.hasProdottoSelezionato
                  ? _ProductDetailsWidget(
                      controller: _controller,
                      onStateChanged: _updateState,
                      onReload: _caricaProdotti,
                    )
                  : _buildEmptyState(),
              Positioned(bottom: 20, right: 20, child: _buildCreateButton()),
            ],
          ),
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

  Widget _buildFAB() {
    final customColors = Theme.of(context).extension<AppColorExtension>()!;
    return FloatingActionButton(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ProdottiCreaPage()),
        );
      },
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

  Widget _buildCreateButton() {
    final customColors = Theme.of(context).extension<AppColorExtension>()!;
    return FloatingActionButton(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ProdottiCreaPage()),
        );
      },
      tooltip: 'Crea Nuovo Prodotto',
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
          shape: BoxShape.circle,
        ),
        child: const Center(child: Icon(Icons.add, size: 28)),
      ),
    );
  }
}

class _ProductListWidget extends StatelessWidget {
  final ProdottiGestioneController controller;
  final VoidCallback onStateChanged;
  final bool multiSelectMode;
  final VoidCallback onToggleMultiSelectMode;
  final Future<void> Function() onApplyCategoriesToSelection;
  final Future<void> Function(TapDownDetails details, ProdottoGlobal prodotto)
  onSecondaryTapDown;
  final void Function(bool enabled)? onMultiSelectChanged;

  const _ProductListWidget({
    required this.controller,
    required this.onStateChanged,
    required this.multiSelectMode,
    required this.onToggleMultiSelectMode,
    required this.onApplyCategoriesToSelection,
    required this.onSecondaryTapDown,
    this.onMultiSelectChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FiltriWidget(
          controller: controller,
          onStateChanged: onStateChanged,
          multiSelectMode: multiSelectMode,
          onToggleMultiSelectMode: onToggleMultiSelectMode,
        ),
        if (multiSelectMode)
          _BulkSelectionBar(
            controller: controller,
            onStateChanged: onStateChanged,
            onApplyCategoriesToSelection: onApplyCategoriesToSelection,
          ),
        Expanded(child: _buildList(context)),
      ],
    );
  }

  Widget _buildList(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: controller.prodotti.length,
        itemBuilder: (context, index) => _ProductListItem(
          prodotto: controller.prodotti[index],
          isSelected: controller.isProdottoSelezionato(
            controller.prodotti[index],
          ),
          showBulkSelector: multiSelectMode,
          isBulkSelected: controller.isProductSelectedForBulk(
            controller.prodotti[index],
          ),
          onBulkSelectionChanged: (value) {
            controller.toggleProductBulkSelection(controller.prodotti[index]);
            onStateChanged();
          },
          onTap: () async {
            final ctrlPressed = HardwareKeyboard.instance.isControlPressed;
            if (multiSelectMode || ctrlPressed) {
              controller.toggleProductBulkSelection(controller.prodotti[index]);
              onMultiSelectChanged?.call(controller.selectedProductsCount > 1);
            } else {
              await controller.selezionaProdotto(controller.prodotti[index]);
            }
            onStateChanged();
          },
          onLongPress: () {
            controller.toggleProductBulkSelection(controller.prodotti[index]);
            onMultiSelectChanged?.call(controller.selectedProductsCount > 1);
            onStateChanged();
          },
          onSecondaryTapDown: (details) async {
            if (multiSelectMode) {
              return;
            }
            await controller.selezionaProdotto(controller.prodotti[index]);
            onStateChanged();
            await onSecondaryTapDown(details, controller.prodotti[index]);
          },
        ),
      ),
    );
  }
}

class _FiltriWidget extends StatefulWidget {
  final ProdottiGestioneController controller;
  final VoidCallback onStateChanged;
  final bool multiSelectMode;
  final VoidCallback onToggleMultiSelectMode;

  const _FiltriWidget({
    required this.controller,
    required this.onStateChanged,
    required this.multiSelectMode,
    required this.onToggleMultiSelectMode,
  });

  @override
  _FiltriWidgetState createState() => _FiltriWidgetState();
}

class _FiltriWidgetState extends State<_FiltriWidget> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.controller.filtroRicerca;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showImportDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CsvImportDialog(),
    );

    // Se l'import è andato a buon fine, ricarica i prodotti
    if (result == true) {
      widget.controller.caricaProdotti();
      widget.onStateChanged();
    }
  }

  Future<void> _showExportDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CsvExportDialog(),
    );

    // L'export non richiede ricaricamento prodotti
    if (result == true) {
      // Mostra messaggio di successo (opzionale)
      if (context.mounted) {
        NotificationService.instance.messageBar(
          'successo',
          'prodotti_gestisci',
          'Export CSV completato con successo',
        );
      }
    }
  }

  String _getOrdinamentoText(OrdinamentoProdotti ordinamento) {
    switch (ordinamento) {
      case OrdinamentoProdotti.nomeCrescente:
        return 'Nome (A-Z)';
      case OrdinamentoProdotti.nomeDecrescente:
        return 'Nome (Z-A)';
      case OrdinamentoProdotti.prezzoCrescente:
        return 'Prezzo (Crescente)';
      case OrdinamentoProdotti.prezzoDecrescente:
        return 'Prezzo (Decrescente)';
      case OrdinamentoProdotti.nessuno:
        return 'Ordina per...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cerca per nome, SKU, categoria...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: widget.controller.hasFiltroAttivo
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              widget.controller.cancellaFiltro();
                              widget.onStateChanged();
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    widget.controller.setFiltroRicerca(value);
                    widget.onStateChanged();
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _showImportDialog(context),
                icon: const Icon(Icons.upload_file),
                tooltip: 'Importa da CSV',
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).primaryColor.withValues(alpha: 0.1),
                  foregroundColor: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Builder(
                builder: (context) {
                  final customColors = Theme.of(
                    context,
                  ).extension<AppColorExtension>()!;
                  return IconButton(
                    onPressed: () => _showExportDialog(context),
                    icon: const Icon(Icons.download),
                    tooltip: 'Esporta in CSV',
                    style: IconButton.styleFrom(
                      backgroundColor: customColors.successColor.withValues(
                        alpha: 0.1,
                      ),
                      foregroundColor: customColors.successColor,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () async {
                  await widget.controller.caricaProdotti(forceTest: true);
                  widget.onStateChanged();
                  if (context.mounted) {
                    NotificationService.instance.messageBar(
                      'warning',
                      'prodotti_gestisci',
                      'Caricati prodotti di test',
                    );
                  }
                },
                icon: const Icon(Icons.bug_report),
                tooltip: 'Carica Prodotti di Test',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.orange.withValues(alpha: 0.1),
                  foregroundColor: Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: widget.onToggleMultiSelectMode,
                icon: Icon(
                  widget.multiSelectMode
                      ? Icons.checklist_rtl
                      : Icons.checklist,
                ),
                tooltip: widget.multiSelectMode
                    ? 'Disattiva selezione multipla'
                    : 'Attiva selezione multipla',
                style: IconButton.styleFrom(
                  backgroundColor: widget.multiSelectMode
                      ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
                      : Theme.of(context).primaryColor.withValues(alpha: 0.08),
                  foregroundColor: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            decoration: BoxDecoration(
              color: Theme.of(context).inputDecorationTheme.fillColor,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: Theme.of(
                  context,
                ).inputDecorationTheme.enabledBorder!.borderSide.color,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<OrdinamentoProdotti>(
                value: widget.controller.ordinamentoCorrente,
                isExpanded: true,
                icon: Icon(Icons.sort, color: Theme.of(context).primaryColor),
                onChanged: (OrdinamentoProdotti? newValue) {
                  if (newValue != null) {
                    widget.controller.setOrdinamento(newValue);
                    widget.onStateChanged();
                  }
                },
                items: OrdinamentoProdotti.values.map((ordinamento) {
                  return DropdownMenuItem<OrdinamentoProdotti>(
                    value: ordinamento,
                    child: Text(_getOrdinamentoText(ordinamento)),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulkSelectionBar extends StatelessWidget {
  final ProdottiGestioneController controller;
  final VoidCallback onStateChanged;
  final Future<void> Function() onApplyCategoriesToSelection;

  const _BulkSelectionBar({
    required this.controller,
    required this.onStateChanged,
    required this.onApplyCategoriesToSelection,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          Text('Selezionati: ${controller.selectedProductsCount}'),
          TextButton.icon(
            onPressed: () {
              controller.selectAllFilteredProducts();
              onStateChanged();
            },
            icon: const Icon(Icons.select_all),
            label: const Text('Seleziona tutti filtrati'),
          ),
          TextButton(
            onPressed: () {
              controller.clearBulkSelection();
              onStateChanged();
            },
            child: const Text('Pulisci selezione'),
          ),
          FilledButton.icon(
            onPressed: controller.hasSelectedProducts
                ? onApplyCategoriesToSelection
                : null,
            icon: const Icon(Icons.category_outlined),
            label: const Text('Assegna categorie'),
          ),
        ],
      ),
    );
  }
}

class _ProductListItem extends StatelessWidget {
  final ProdottoGlobal prodotto;
  final bool isSelected;
  final bool showBulkSelector;
  final bool isBulkSelected;
  final ValueChanged<bool?>? onBulkSelectionChanged;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Future<void> Function(TapDownDetails details)? onSecondaryTapDown;

  const _ProductListItem({
    required this.prodotto,
    required this.isSelected,
    this.showBulkSelector = false,
    this.isBulkSelected = false,
    this.onBulkSelectionChanged,
    required this.onTap,
    this.onLongPress,
    this.onSecondaryTapDown,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<AppColorExtension>()!;
    final displayInfo = ProdottoDisplayInfo.fromProdotto(prodotto);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: isSelected ? 8 : 2,
      shadowColor: isSelected
          ? theme.primaryColor.withValues(alpha: 0.3)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: theme.primaryColor, width: 2)
            : BorderSide.none,
      ),
      color: isSelected ? customColors.selectedCardBackground : theme.cardColor,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        onSecondaryTapDown: onSecondaryTapDown,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return constraints.maxWidth > 600
                  ? _buildWideLayout(context, displayInfo)
                  : _buildCompactLayout(context, displayInfo);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context, ProdottoDisplayInfo info) {
    return Row(
      children: [
        if (showBulkSelector)
          Checkbox(value: isBulkSelected, onChanged: onBulkSelectionChanged),
        Expanded(flex: 3, child: _buildNameSection(context, info)),
        Expanded(flex: 2, child: _buildPriceWidget(context)),
        Expanded(flex: 2, child: _buildCategorySection(context, info)),
        _buildVariantsChip(context),
      ],
    );
  }

  Widget _buildCompactLayout(BuildContext context, ProdottoDisplayInfo info) {
    final customColors = Theme.of(context).extension<AppColorExtension>()!;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (showBulkSelector)
              Checkbox(
                value: isBulkSelected,
                onChanged: onBulkSelectionChanged,
              ),
            Expanded(child: _buildNameSection(context, info)),
            _buildPriceWidget(context),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              'ID: ${info.id}',
              style: textTheme.bodySmall?.copyWith(
                color: textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 16),
            Text(info.categoria, style: textTheme.bodySmall),
            const Spacer(),
            Icon(
              prodotto.inStock ? Icons.check_circle : Icons.cancel,
              size: 14,
              color: prodotto.inStock
                  ? customColors.stockAvailable
                  : customColors.stockUnavailable,
            ),
            const SizedBox(width: 4),
            Text(
              ProdottoUtils.getVariantiCountShort(
                prodotto.varianti?.length ?? 0,
              ),
              style: textTheme.bodySmall?.copyWith(
                color: textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNameSection(BuildContext context, ProdottoDisplayInfo info) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          info.nome,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isSelected
                ? theme.primaryColor
                : theme.textTheme.titleMedium?.color,
          ),
        ),
        Text(
          'ID: ${info.id} • SKU: ${info.sku}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection(BuildContext context, ProdottoDisplayInfo info) {
    final theme = Theme.of(context);
    final customColors = theme.extension<AppColorExtension>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(info.categoria, style: theme.textTheme.bodyMedium),
        Row(
          children: [
            Icon(
              prodotto.inStock ? Icons.check_circle : Icons.cancel,
              size: 16,
              color: prodotto.inStock
                  ? customColors.stockAvailable
                  : customColors.stockUnavailable,
            ),
            const SizedBox(width: 4),
            Text(
              info.disponibilita,
              style: theme.textTheme.bodySmall?.copyWith(
                color: prodotto.inStock
                    ? customColors.stockAvailable
                    : customColors.stockUnavailable,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceWidget(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<AppColorExtension>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (prodotto.prezzoScontato != null) ...[
          Text(
            PrezzoFormatter.formatPrezzo(prodotto.prezzoNormale ?? 0),
            style: theme.textTheme.bodySmall?.copyWith(
              decoration: TextDecoration.lineThrough,
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
            ),
          ),
          Text(
            PrezzoFormatter.formatPrezzo(prodotto.prezzoScontato!),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: customColors.stockUnavailable,
              fontWeight: FontWeight.bold,
            ),
          ),
        ] else
          Text(
            PrezzoFormatter.formatPrezzo(prodotto.prezzoNormale ?? 0),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  Widget _buildVariantsChip(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withValues(alpha: 0.1),
            theme.primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.palette, size: 14, color: theme.primaryColor),
          const SizedBox(width: 4),
          Text(
            '${prodotto.varianti?.length ?? 0}',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductDetailsWidget extends StatefulWidget {
  final ProdottiGestioneController controller;
  final VoidCallback onStateChanged;
  final Future<void> Function() onReload;

  const _ProductDetailsWidget({
    required this.controller,
    required this.onStateChanged,
    required this.onReload,
  });

  @override
  State<_ProductDetailsWidget> createState() => _ProductDetailsWidgetState();
}

class _ProductDetailsWidgetState extends State<_ProductDetailsWidget> {
  final AppSettings _settings = AppSettings();
  bool _isEditMode = false;
  bool _replaceCategories = false;
  bool _replaceTags = false;
  bool _isSaving = false;
  List<String> _selectedCategoryNames = <String>[];
  List<String> _selectedTagNames = <String>[];
  String? _bulkStatus;
  bool _bulkDelete = false;
  final Map<int, TextEditingController> _variantPriceCtrls = {};
  final Map<int, TextEditingController> _variantQtyCtrls = {};
  final Map<int, double> _variantBasePrice = {};
  final Map<int, int> _variantBaseQty = {};
  final List<_PendingProductModification> _pendingMods = <_PendingProductModification>[];
  int? _lastProductId;

  ProdottiGestioneController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _initSettings();
  }

  Future<void> _initSettings() async {
    await _settings.init();
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant _ProductDetailsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncDraftFromSelectionIfNeeded();
  }

  @override
  void dispose() {
    for (final c in _variantPriceCtrls.values) {
      c.dispose();
    }
    for (final c in _variantQtyCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncDraftFromSelectionIfNeeded() {
    final prodotto = _controller.prodottoSelezionato;
    final id = prodotto?.id;
    if (prodotto == null || id == null || id == _lastProductId) return;
    _lastProductId = id;
    _syncDraftFromSelection();
  }

  void _syncDraftFromSelection() {
    final prodotto = _controller.prodottoSelezionato;
    if (prodotto == null) return;
    _selectedCategoryNames =
        (prodotto.categoria ?? const <CategoriaProdotto>[])
            .map((c) => c.nome)
            .toSet()
            .toList()
          ..sort();
    _selectedTagNames =
        (prodotto.tag ?? const <TagProdotto>[]).map((t) => t.nome).toSet().toList()
          ..sort();
    _bulkStatus = null;
    _bulkDelete = false;

    for (final c in _variantPriceCtrls.values) {
      c.dispose();
    }
    for (final c in _variantQtyCtrls.values) {
      c.dispose();
    }
    _variantPriceCtrls.clear();
    _variantQtyCtrls.clear();
    _variantBasePrice.clear();
    _variantBaseQty.clear();
    _pendingMods.clear();

    for (final variante in (prodotto.varianti ?? const <VarianteProductGlobal>[])) {
      _variantPriceCtrls[variante.id] =
          TextEditingController(text: variante.prezzo.toStringAsFixed(2));
      _variantQtyCtrls[variante.id] =
          TextEditingController(text: variante.quantita.toString());
      _variantBasePrice[variante.id] = variante.prezzo;
      _variantBaseQty[variante.id] = variante.quantita;

      _variantPriceCtrls[variante.id]!.addListener(() {
        final current =
            double.tryParse(_variantPriceCtrls[variante.id]!.text.replaceAll(',', '.'));
        final base = _variantBasePrice[variante.id] ?? variante.prezzo;
        if (current == null || current == base) {
          _removePendingByKey('v:${variante.id}:price');
          return;
        }
        _upsertPending(
          _PendingProductModification(
            key: 'v:${variante.id}:price',
            productId: _controller.prodottoSelezionato?.id ?? 0,
            productName: _controller.prodottoSelezionato?.nome ?? '',
            coverUrl: _controller.prodottoSelezionato?.immagineUrl,
            message: 'Prezzo variante ${variante.nomeVisualizzabile}: ~~€${base.toStringAsFixed(2)}~~ -> €${current.toStringAsFixed(2)}',
            changedAt: DateTime.now(),
          ),
        );
      });

      _variantQtyCtrls[variante.id]!.addListener(() {
        final current = int.tryParse(_variantQtyCtrls[variante.id]!.text.trim());
        final base = _variantBaseQty[variante.id] ?? variante.quantita;
        if (current == null || current == base) {
          _removePendingByKey('v:${variante.id}:qty');
          return;
        }
        _upsertPending(
          _PendingProductModification(
            key: 'v:${variante.id}:qty',
            productId: _controller.prodottoSelezionato?.id ?? 0,
            productName: _controller.prodottoSelezionato?.nome ?? '',
            coverUrl: _controller.prodottoSelezionato?.immagineUrl,
            message: 'Quantita variante ${variante.nomeVisualizzabile}: ~~$base~~ -> $current',
            changedAt: DateTime.now(),
          ),
        );
      });
    }
  }

  void _upsertPending(_PendingProductModification mod) {
    final idx = _pendingMods.indexWhere((m) => m.key == mod.key);
    setState(() {
      if (idx >= 0) {
        _pendingMods[idx] = mod;
      } else {
        _pendingMods.add(mod);
      }
    });
  }

  void _removePendingByKey(String key) {
    final idx = _pendingMods.indexWhere((m) => m.key == key);
    if (idx < 0) return;
    setState(() {
      _pendingMods.removeAt(idx);
    });
  }

  Future<void> _openCategoryPicker() async {
    final all = await PlatformManager.categorie.getCategories(perPage: 100);
    if (!mounted) return;
    final categoryNames = <String>[];
    for (final categoria in all) {
      final name = categoria.nome.toString().trim();
      if (name.isNotEmpty) {
        categoryNames.add(name);
      }
    }
    final selected = await SearchableCheckboxDialog.show(
      context,
      title: 'Categorie prodotto',
      inputLabel: 'Filtra o nuova categoria',
      input_list: categoryNames,
      preselected_list: _selectedCategoryNames,
    );
    if (selected == null || !mounted) return;
    setState(() {
      final previous = _selectedCategoryNames;
      _selectedCategoryNames = List<String>.from(selected)..sort();
      if (_selectedCategoryNames.join('|').toLowerCase() ==
          previous.join('|').toLowerCase()) {
        _removePendingByKey('product:categories');
      } else {
        final removed = previous
            .where(
              (c) => !_selectedCategoryNames
                  .map((v) => v.toLowerCase())
                  .contains(c.toLowerCase()),
            )
            .map((c) => '~~$c~~');
        final added = _selectedCategoryNames.where(
          (c) => !previous.map((v) => v.toLowerCase()).contains(c.toLowerCase()),
        );
        _upsertPending(
          _PendingProductModification(
            key: 'product:categories',
            productId: _controller.prodottoSelezionato?.id ?? 0,
            productName: _controller.prodottoSelezionato?.nome ?? '',
            coverUrl: _controller.prodottoSelezionato?.immagineUrl,
            message: 'Categorie: ${[...removed, ...added].join(', ')}',
            changedAt: DateTime.now(),
          ),
        );
      }
    });
  }

  Future<void> _openTagPicker() async {
    final all = await PlatformManager.tag.getTags(perPage: 100);
    if (!mounted) return;
    final tagNames = <String>[];
    for (final tag in all) {
      final name = tag.nome.toString().trim();
      if (name.isNotEmpty) {
        tagNames.add(name);
      }
    }
    final selected = await SearchableCheckboxDialog.show(
      context,
      title: 'Tag prodotto',
      inputLabel: 'Filtra o nuovo tag',
      input_list: tagNames,
      preselected_list: _selectedTagNames,
    );
    if (selected == null || !mounted) return;
    setState(() {
      _selectedTagNames = List<String>.from(selected)..sort();
      _upsertPending(
        _PendingProductModification(
          key: 'product:tags',
          productId: _controller.prodottoSelezionato?.id ?? 0,
          productName: _controller.prodottoSelezionato?.nome ?? '',
          coverUrl: _controller.prodottoSelezionato?.immagineUrl,
          message: 'Tag: ${_selectedTagNames.join(', ')}',
          changedAt: DateTime.now(),
        ),
      );
    });
  }

  Future<bool> _showPendingSummaryBeforeSave() async {
    if (_pendingMods.isEmpty) return true;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final ordered = [..._pendingMods]
          ..sort((a, b) => a.changedAt.compareTo(b.changedAt));
        return StatefulBuilder(
          builder: (context, setLocal) => AlertDialog(
            title: const Text('Riepilogo modifiche (cronologico)'),
            content: SizedBox(
              width: 760,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: ordered.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final m = ordered[index];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: m.coverUrl == null || m.coverUrl!.isEmpty
                                  ? Container(
                                      width: 40,
                                      height: 40,
                                      color: Colors.grey.shade300,
                                      child: const Icon(Icons.image_outlined, size: 16),
                                    )
                                  : Image.network(m.coverUrl!, width: 40, height: 40, fit: BoxFit.cover),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${m.productName} (ID ${m.productId}) • ${m.changedAt.hour.toString().padLeft(2, '0')}:${m.changedAt.minute.toString().padLeft(2, '0')} • ${m.message}',
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _pendingMods.removeWhere((e) => e.key == m.key);
                                });
                                setLocal(() {
                                  ordered.removeAt(index);
                                });
                              },
                              child: const Text('Elimina questa modifica'),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _pendingMods.clear();
                    _syncDraftFromSelection();
                  });
                  Navigator.of(ctx).pop(false);
                },
                child: const Text('Annulla modifiche'),
              ),
              FilledButton(
                onPressed: ordered.isEmpty ? null : () => Navigator.of(ctx).pop(true),
                child: const Text('Salva modifiche'),
              ),
            ],
          ),
        );
      },
    );
    return proceed == true;
  }

  Future<void> _saveAll() async {
    final prodotto = _controller.prodottoSelezionato;
    if (prodotto == null || prodotto.id == null || prodotto.id! <= 0) return;
    final isMulti = _controller.selectedProductsCount > 1;
    final confirmed = await _showPendingSummaryBeforeSave();
    if (!confirmed) return;
    setState(() => _isSaving = true);
    try {
      BulkCategoryUpdateResult categoryResult;
      if (isMulti) {
        final categories = await _controller.resolveCategoryNames(
          categoryNames: _selectedCategoryNames,
        );
        categoryResult = await _controller.bulkUpdateSelectedProductCategories(
          categorie: categories,
          replaceExisting: _replaceCategories,
        );
      } else {
        categoryResult = await _controller.updateSelectedProductCategoriesByNames(
          categoryNames: _selectedCategoryNames,
          replaceExisting: _replaceCategories,
        );
      }

      BulkCategoryUpdateResult tagResult = const BulkCategoryUpdateResult(
        successCount: 0,
        failedCount: 0,
        message: 'Nessuna modifica tag.',
      );
      if (_selectedTagNames.isNotEmpty) {
        final tags = await _controller.resolveTagNames(tagNames: _selectedTagNames);
        tagResult = await _controller.bulkUpdateSelectedProductTags(
          tags: tags,
          replaceExisting: _replaceTags,
        );
      }

      BulkCategoryUpdateResult statusResult = const BulkCategoryUpdateResult(
        successCount: 0,
        failedCount: 0,
        message: 'Nessuna modifica stato.',
      );
      if (isMulti && _bulkStatus != null && _bulkStatus!.isNotEmpty) {
        statusResult = await _controller.bulkUpdateSelectedProductsStatus(
          status: _bulkStatus!,
        );
      }

      BulkCategoryUpdateResult deleteResult = const BulkCategoryUpdateResult(
        successCount: 0,
        failedCount: 0,
        message: 'Nessuna eliminazione.',
      );
      if (isMulti && _bulkDelete) {
        final settings = AppSettings();
        await settings.init();
        deleteResult = await _controller.deleteSelectedProducts(
          force: settings.forceDelete,
        );
      }

      final edits = <int, QuickVariantEdit>{};
      for (final variante in (prodotto.varianti ?? const <VarianteProductGlobal>[])) {
        final priceCtrl = _variantPriceCtrls[variante.id];
        final qtyCtrl = _variantQtyCtrls[variante.id];
        final parsedPrice = double.tryParse((priceCtrl?.text ?? '').replaceAll(',', '.'));
        final parsedQty = int.tryParse((qtyCtrl?.text ?? '').trim());
        final newPrice = parsedPrice ?? variante.prezzo;
        final newQty = parsedQty ?? variante.quantita;
        if (newPrice != variante.prezzo || newQty != variante.quantita) {
          edits[variante.id] = QuickVariantEdit(
            nome: variante.nome,
            attributi: variante.attributi,
            sku: variante.sku,
            prezzo: newPrice,
            prezzoScontato: variante.prezzoScontato,
            quantita: newQty,
            immagineUrl: variante.immagineUrl,
            immaginiAggiuntive: variante.immaginiAggiuntive,
            peso: variante.peso,
            dimensioni: variante.dimensioni,
            attiva: newQty > 0,
          );
        }
      }

      final variantResult = isMulti
          ? const QuickVariantSaveResult(
              updated: 0,
              failed: 0,
              message: 'Modifica varianti non disponibile in multi-select.',
            )
          : await _controller.saveVariantQuickEdits(
              productId: prodotto.id!,
              edits: edits,
            );

      if (!mounted) return;
      final hasErrors =
          categoryResult.failedCount > 0 ||
          tagResult.failedCount > 0 ||
          statusResult.failedCount > 0 ||
          deleteResult.failedCount > 0 ||
          variantResult.failed > 0;
      NotificationService.instance.messageBar(
        hasErrors ? 'warning' : 'successo',
        'prodotti_gestisci',
        '${categoryResult.message} ${tagResult.message} ${statusResult.message} ${deleteResult.message} ${variantResult.message}',
      );

      await widget.onReload();
      widget.onStateChanged();
      setState(() {
        _isEditMode = false;
        _pendingMods.clear();
      });
      _syncDraftFromSelection();
    } catch (e) {
      if (!mounted) return;
      NotificationService.instance.messageBar(
        'errore',
        'prodotti_gestisci',
        'Errore salvataggio rapido: $e',
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _syncDraftFromSelectionIfNeeded();
    final prodotto = _controller.prodottoSelezionato!;
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        final focused = FocusManager.instance.primaryFocus?.context?.widget;
        if (focused is EditableText) return KeyEventResult.ignored;

        if (_matchesShortcut(event, _settings.shortcutToggleEdit) && !_isSaving) {
          setState(() {
            _isEditMode = !_isEditMode;
            if (_isEditMode) {
              _syncDraftFromSelection();
            }
          });
          return KeyEventResult.handled;
        }

        if (_matchesShortcut(event, _settings.shortcutSave) && _isEditMode && !_isSaving) {
          _saveAll();
          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
      child: Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProductHeader(
              controller: _controller,
              onStateChanged: widget.onStateChanged,
              onReload: widget.onReload,
            ),
            const SizedBox(height: 20),
            _QuickEditPanel(
              isEditMode: _isEditMode,
              isSaving: _isSaving,
              isMultiSelect: _controller.selectedProductsCount > 1,
              bulkStatus: _bulkStatus,
              bulkDelete: _bulkDelete,
              onToggleEdit: () {
                setState(() {
                  _isEditMode = !_isEditMode;
                  if (_isEditMode) {
                    _syncDraftFromSelection();
                  }
                });
              },
              onStatusChanged: _isEditMode
                  ? (value) => setState(() => _bulkStatus = value)
                  : null,
              onBulkDeleteChanged: _isEditMode
                  ? (value) => setState(() => _bulkDelete = value)
                  : null,
              onSaveAll: _isEditMode && !_isSaving ? _saveAll : null,
              onCancelEdit: _isEditMode
                  ? () {
                      setState(() {
                        _isEditMode = false;
                        _syncDraftFromSelection();
                      });
                    }
                  : null,
            ),
            const SizedBox(height: 20),
            Opacity(
              opacity: _isEditMode && _controller.selectedProductsCount > 1 ? 0.45 : 1,
              child: _ProductInfoCard(
                prodotto: prodotto,
                isEditMode: _isEditMode,
                isSaving: _isSaving,
                selectedCategoryNames: _selectedCategoryNames,
                selectedTagNames: _selectedTagNames,
                onOpenCategoryPicker: _isEditMode ? _openCategoryPicker : null,
                onOpenTagPicker: _isEditMode ? _openTagPicker : null,
              ),
            ),
            const SizedBox(height: 20),
            IgnorePointer(
              ignoring: _isEditMode && _controller.selectedProductsCount > 1,
              child: Opacity(
                opacity: _isEditMode && _controller.selectedProductsCount > 1 ? 0.45 : 1,
                child: _ProductVariantsCard(
                  controller: _controller,
                  onStateChanged: widget.onStateChanged,
                  isEditMode: _isEditMode,
                  variantPriceCtrls: _variantPriceCtrls,
                  variantQtyCtrls: _variantQtyCtrls,
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }
}

class _ProductHeader extends StatelessWidget {
  final ProdottiGestioneController controller;
  final VoidCallback onStateChanged;
  final Future<void> Function() onReload;

  const _ProductHeader({
    required this.controller,
    required this.onStateChanged,
    required this.onReload,
  });

  Future<void> _handleAction(
    BuildContext context,
    _SelectedProductAction action,
    ProdottoGlobal prodotto,
  ) async {
    switch (action) {
      case _SelectedProductAction.crea:
        final created = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(builder: (_) => const ProdottiCreaPage()),
        );
        if (created == true) {
          await onReload();
          onStateChanged();
        }
        break;
      case _SelectedProductAction.modifica:
        final updated = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => ProdottiCreaPage(prodottoDaModificare: prodotto),
          ),
        );
        if (updated == true) {
          await onReload();
          onStateChanged();
        }
        break;
      case _SelectedProductAction.elimina:
        final bool? confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Elimina prodotto'),
            content: Text('Confermi eliminazione di "${prodotto.nome}"?'),
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

        if (confirmed != true) return;
        final prodottoId = prodotto.id ?? 0;
        if (prodottoId <= 0) {
          NotificationService.instance.messageBar(
            'errore',
            'prodotti_gestisci',
            'ID prodotto non valido.',
          );
          return;
        }

        final removed = await controller.eliminaProdotto(prodottoId);
        if (context.mounted) {
          NotificationService.instance.messageBar(
            removed ? 'successo' : 'errore',
            'prodotti_gestisci',
            removed
                ? 'Prodotto eliminato con successo.'
                : 'Eliminazione prodotto non riuscita.',
          );
        }
        if (removed) {
          await onReload();
          onStateChanged();
        }
        break;
    }
  }

  Widget _buildActionsMenu(BuildContext context, ProdottoGlobal prodotto) {
    return PopupMenuButton<_SelectedProductAction>(
      tooltip: 'Azioni prodotto',
      onSelected: (action) => _handleAction(context, action, prodotto),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _SelectedProductAction.modifica,
          child: Row(
            children: [
              Icon(Icons.edit_outlined),
              SizedBox(width: 8),
              Text('Modifica'),
            ],
          ),
        ),
        PopupMenuItem(
          value: _SelectedProductAction.elimina,
          child: Row(
            children: [
              Icon(Icons.delete_outline),
              SizedBox(width: 8),
              Text('Elimina'),
            ],
          ),
        ),
        PopupMenuItem(
          value: _SelectedProductAction.crea,
          child: Row(
            children: [
              Icon(Icons.add_circle_outline),
              SizedBox(width: 8),
              Text('Crea'),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.more_vert, color: Theme.of(context).primaryColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prodotto = controller.prodottoSelezionato!;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: theme.brightness == Brightness.dark
              ? [theme.cardColor, theme.primaryColor.withValues(alpha: 0.05)]
              : [theme.cardColor, theme.primaryColor.withValues(alpha: 0.02)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [_buildActionsMenu(context, prodotto)],
            ),
            const SizedBox(height: 8),
            _ProductImage(controller: controller),
            const SizedBox(height: 20),
            Text(
              prodotto.nome ?? '',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.15 : 0.1,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                prodotto.descrizioneBreve ?? '',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.primaryColor.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final ProdottiGestioneController controller;

  const _ProductImage({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = controller.getCurrentImageUrl();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(imageUrl),
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.primaryColor.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.primaryColor.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildImagePlaceholder(
              context,
              icon: Icons.image_not_supported,
            ),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildImagePlaceholder(
                context,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(
    BuildContext context, {
    IconData? icon,
    Widget? child,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.grey[800]!, Colors.grey[700]!]
              : [Colors.grey[100]!, Colors.grey[50]!],
        ),
      ),
      child: Center(
        child:
            child ??
            Icon(
              icon,
              size: 60,
              color: theme.primaryColor.withValues(alpha: 0.5),
            ),
      ),
    );
  }
}

class _ProductInfoCard extends StatelessWidget {
  final ProdottoGlobal prodotto;
  final bool isEditMode;
  final bool isSaving;
  final List<String> selectedCategoryNames;
  final List<String> selectedTagNames;
  final VoidCallback? onOpenCategoryPicker;
  final VoidCallback? onOpenTagPicker;

  const _ProductInfoCard({
    required this.prodotto,
    required this.isEditMode,
    required this.isSaving,
    required this.selectedCategoryNames,
    required this.selectedTagNames,
    required this.onOpenCategoryPicker,
    required this.onOpenTagPicker,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayInfo = ProdottoDisplayInfo.fromProdotto(prodotto);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(
                      alpha: theme.brightness == Brightness.dark ? 0.15 : 0.1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: theme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Informazioni Prodotto',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoRow(label: 'ID', value: displayInfo.id),
            _InfoRow(label: 'SKU', value: displayInfo.sku),
            _InfoPickerRow(
              label: 'Categoria',
              value: selectedCategoryNames.join(', '),
              hint: 'Nessuna categoria',
              icon: Icons.category_outlined,
              enabled: isEditMode && !isSaving,
              onTap: onOpenCategoryPicker,
            ),
            _InfoPickerRow(
              label: 'Tag',
              value: selectedTagNames.join(', '),
              hint: 'Nessun tag',
              icon: Icons.tag,
              enabled: isEditMode && !isSaving,
              onTap: onOpenTagPicker,
            ),
            _InfoRow(label: 'Disponibilità', value: displayInfo.disponibilita),
            _InfoRow(label: 'Prezzo', value: displayInfo.prezzo),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.8,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                ),
              ),
              child: SelectableText(value, style: theme.textTheme.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPickerRow extends StatelessWidget {
  final String label;
  final String value;
  final String hint;
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  const _InfoPickerRow({
    required this.label,
    required this.value,
    required this.hint,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
              ),
            ),
          ),
          Expanded(
            child: TextFormField(
              initialValue: value,
              readOnly: true,
              onTap: enabled ? onTap : null,
              decoration: InputDecoration(
                hintText: hint,
                isDense: true,
                prefixIcon: Icon(icon),
                suffixIcon: Icon(
                  Icons.arrow_drop_down,
                  color: enabled ? null : theme.disabledColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductVariantsCard extends StatelessWidget {
  final ProdottiGestioneController controller;
  final VoidCallback onStateChanged;
  final bool isEditMode;
  final Map<int, TextEditingController> variantPriceCtrls;
  final Map<int, TextEditingController> variantQtyCtrls;

  const _ProductVariantsCard({
    required this.controller,
    required this.onStateChanged,
    required this.isEditMode,
    required this.variantPriceCtrls,
    required this.variantQtyCtrls,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prodotto = controller.prodottoSelezionato!;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVariantsHeader(context, prodotto.varianti?.length ?? 0),
            const SizedBox(height: 16),
            _VariantFiltersWidget(
              controller: controller,
              onStateChanged: onStateChanged,
            ),
            if (controller.hasVarianteSelezionata) ...[
              const SizedBox(height: 12),
              _buildResetButton(context),
              const SizedBox(height: 12),
            ],
            _buildVariantsList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildVariantsHeader(BuildContext context, int variantsCount) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.15 : 0.1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.palette, color: theme.primaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          'Varianti Disponibili',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.primaryColor,
                theme.primaryColor.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            '$variantsCount',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResetButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          controller.selezionaVariante(null);
          onStateChanged();
        },
        icon: const Icon(Icons.clear, size: 16),
        label: const Text('Mostra immagine principale'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).primaryColor,
          side: BorderSide(color: Theme.of(context).primaryColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildVariantsList(BuildContext context) {
    final variantiDaMostrare = controller.variantiFiltrate;
    if (variantiDaMostrare.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Center(
          child: Text(
            'Nessuna variante trovata.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }
    final prodotto = controller.prodottoSelezionato!;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: variantiDaMostrare.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final variante = variantiDaMostrare[index];
        return GestureDetector(
          onLongPress: () async {
            final result = await showRettificaStockDialog(
              context: context,
              prodottoId: prodotto.id!,
              varianteId: variante.id,
              nome: variante.nomeVisualizzabile,
              quantitaAttuale: variante.quantita,
              controller: controller,
            );
            if (result == true) {
              onStateChanged();
            }
          },
          child: _VariantItem(
            variante: variante,
            isSelected: controller.isVarianteSelezionata(variante),
            onTap: () {
              controller.selezionaVariante(variante);
              onStateChanged();
            },
            quickEditFields: isEditMode
                ? _VariantQuickEditFields(
                    prezzoController: variantPriceCtrls[variante.id] ??
                        TextEditingController(
                          text: variante.prezzo.toStringAsFixed(2),
                        ),
                    quantitaController: variantQtyCtrls[variante.id] ??
                        TextEditingController(text: variante.quantita.toString()),
                  )
                : null,
          ),
        );
      },
    );
  }
}

class _VariantFiltersWidget extends StatelessWidget {
  final ProdottiGestioneController controller;
  final VoidCallback onStateChanged;

  const _VariantFiltersWidget({
    required this.controller,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final opzioniFiltro = controller.getOpzioniFiltroDisponibili();
    if (opzioniFiltro.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filtra per:',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (controller.hasFiltriVariantiAttivi)
                TextButton(
                  onPressed: () {
                    controller.cancellaFiltriVarianti();
                    onStateChanged();
                  },
                  child: const Text('Pulisci filtri'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ...opzioniFiltro.entries.map(
            (entry) => _buildFilterRow(context, entry.key, entry.value),
          ),
          const Divider(height: 16),
          CheckboxListTile(
            title: const Text("Mostra solo disponibili"),
            value: controller.filtraSoloInStock,
            onChanged: (bool? value) {
              if (value != null) {
                controller.setFiltraSoloInStock(value);
                onStateChanged();
              }
            },
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            contentPadding: EdgeInsets.zero,
            activeColor: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(
    BuildContext context,
    String nomeAttributo,
    List<AttributoVariante> opzioni,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$nomeAttributo:',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: opzioni.map((opzione) {
                final isSelected = controller.isFiltroVarianteSelezionato(
                  nomeAttributo,
                  opzione.opzione,
                );
                if (nomeAttributo.toLowerCase() == 'colore' &&
                    opzione.valore != null) {
                  return _ColorSwatchChip(
                    color: hexToColor(opzione.valore!),
                    isSelected: isSelected,
                    onTap: () {
                      controller.setFiltroVariante(
                        nomeAttributo,
                        opzione.opzione,
                      );
                      onStateChanged();
                    },
                  );
                }
                return _TextSwatchChip(
                  text: opzione.opzione,
                  isSelected: isSelected,
                  onTap: () {
                    controller.setFiltroVariante(
                      nomeAttributo,
                      opzione.opzione,
                    );
                    onStateChanged();
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorSwatchChip extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorSwatchChip({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Theme.of(context).primaryColor,
                    spreadRadius: 2,
                    blurRadius: 2,
                  ),
                ]
              : [],
        ),
        child: isSelected
            ? Icon(
                Icons.check,
                size: 18,
                color:
                    ThemeData.estimateBrightnessForColor(color) ==
                        Brightness.dark
                    ? Colors.white
                    : Colors.black,
              )
            : null,
      ),
    );
  }
}

class _QuickEditPanel extends StatelessWidget {
  final bool isEditMode;
  final bool isSaving;
  final bool isMultiSelect;
  final String? bulkStatus;
  final bool bulkDelete;
  final VoidCallback onToggleEdit;
  final ValueChanged<String?>? onStatusChanged;
  final ValueChanged<bool>? onBulkDeleteChanged;
  final VoidCallback? onSaveAll;
  final VoidCallback? onCancelEdit;

  const _QuickEditPanel({
    required this.isEditMode,
    required this.isSaving,
    required this.isMultiSelect,
    required this.bulkStatus,
    required this.bulkDelete,
    required this.onToggleEdit,
    required this.onStatusChanged,
    required this.onBulkDeleteChanged,
    required this.onSaveAll,
    required this.onCancelEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FilledButton.icon(
                onPressed: isSaving ? null : onToggleEdit,
                icon: Icon(isEditMode ? Icons.lock_open : Icons.edit),
                label: Text(isEditMode ? 'Modifica attiva' : 'Modifica rapida'),
              ),
              const SizedBox(width: 8),
              if (isEditMode)
                OutlinedButton(
                  onPressed: isSaving ? null : onCancelEdit,
                  child: const Text('Annulla'),
                ),
              const Spacer(),
              if (isEditMode)
                FilledButton.icon(
                  onPressed: isSaving ? null : onSaveAll,
                  icon: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Salva tutto'),
                ),
            ],
          ),
          if (isEditMode) ...[
            const SizedBox(height: 12),
            if (isMultiSelect)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Modalita multi-select: sono editabili solo categorie, tag, stato ed eliminazione.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (isMultiSelect) ...[
              DropdownButtonFormField<String>(
                value: bulkStatus,
                decoration: const InputDecoration(
                  labelText: 'Stato prodotti selezionati',
                  prefixIcon: Icon(Icons.public),
                ),
                items: const [
                  DropdownMenuItem(value: 'publish', child: Text('Pubblico')),
                  DropdownMenuItem(value: 'private', child: Text('Privato')),
                  DropdownMenuItem(value: 'draft', child: Text('Bozza')),
                ],
                onChanged: isSaving ? null : onStatusChanged,
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                value: bulkDelete,
                onChanged: isSaving ? null : onBulkDeleteChanged,
                contentPadding: EdgeInsets.zero,
                title: const Text('Elimina prodotti selezionati'),
                subtitle: const Text('Usa soft/hard delete in base alle impostazioni.'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _VariantQuickEditFields extends StatelessWidget {
  final TextEditingController prezzoController;
  final TextEditingController quantitaController;

  const _VariantQuickEditFields({
    required this.prezzoController,
    required this.quantitaController,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: prezzoController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Prezzo',
              prefixIcon: Icon(Icons.euro),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: quantitaController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Quantita',
              prefixIcon: Icon(Icons.inventory_2_outlined),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}

class _PendingProductModification {
  final String key;
  final int productId;
  final String productName;
  final String? coverUrl;
  final String message;
  final DateTime changedAt;

  const _PendingProductModification({
    required this.key,
    required this.productId,
    required this.productName,
    required this.coverUrl,
    required this.message,
    required this.changedAt,
  });
}

bool _matchesShortcut(KeyDownEvent event, String shortcut) {
  final normalized = shortcut.trim().toLowerCase();
  if (normalized.isEmpty) return false;
  final parts = normalized.split('+').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
  final wantsCtrl = parts.contains('ctrl') || parts.contains('control');
  final wantsShift = parts.contains('shift');
  final wantsAlt = parts.contains('alt');
  final keyToken = parts.where((p) => p != 'ctrl' && p != 'control' && p != 'shift' && p != 'alt').join('');

  final key = event.logicalKey;
  final isCtrl = HardwareKeyboard.instance.isControlPressed;
  final isShift = HardwareKeyboard.instance.isShiftPressed;
  final isAlt = HardwareKeyboard.instance.isAltPressed;

  if (wantsCtrl != isCtrl) return false;
  if (wantsShift != isShift) return false;
  if (wantsAlt != isAlt) return false;

  switch (keyToken) {
    case 'a':
      return key == LogicalKeyboardKey.keyA;
    case 's':
      return key == LogicalKeyboardKey.keyS;
    case 'e':
      return key == LogicalKeyboardKey.keyE;
    case 'delete':
    case 'del':
      return key == LogicalKeyboardKey.delete;
    case 'esc':
    case 'escape':
      return key == LogicalKeyboardKey.escape;
    default:
      return false;
  }
}

class _TextSwatchChip extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _TextSwatchChip({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor
              : theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? theme.primaryColor : theme.dividerColor,
          ),
        ),
        child: Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.textTheme.bodyMedium?.color,
          ),
        ),
      ),
    );
  }
}

class _VariantItem extends StatelessWidget {
  final VarianteProductGlobal variante;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? quickEditFields;

  const _VariantItem({
    required this.variante,
    required this.isSelected,
    required this.onTap,
    this.quickEditFields,
  });

  Widget _buildOutOfStockLabel(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<AppColorExtension>()!;
    return Positioned(
      top: 10,
      right: -30,
      child: Transform.rotate(
        angle: 45 * math.pi / 180,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 2),
          color: customColors.stockUnavailable,
          child: Text(
            'ESAURITO',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<AppColorExtension>()!;
    final bool isOutOfStock = variante.quantita < 1;

    Color? backgroundColor;
    Gradient? backgroundGradient;
    Color borderColor;
    double borderWidth = 1.0;

    if (isOutOfStock) {
      backgroundColor = customColors.stockUnavailable.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.25 : 0.1,
      );
      borderColor = customColors.stockUnavailable;
      borderWidth = 2.0;
    } else if (isSelected) {
      backgroundColor = customColors.variantSelectedBackground;
      borderColor = theme.primaryColor;
      borderWidth = 2.0;
    } else {
      borderColor = theme.dividerColor;
      backgroundGradient = LinearGradient(
        colors: theme.brightness == Brightness.dark
            ? [
                theme.cardColor.withValues(alpha: 0.5),
                theme.cardColor.withValues(alpha: 0.3),
              ]
            : [Colors.grey[100]!, Colors.grey[50] ?? Colors.grey[100]!],
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          InkWell(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: backgroundColor,
                gradient: backgroundGradient,
                border: Border.all(color: borderColor, width: borderWidth),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (variante.immagineUrl != null &&
                          variante.immagineUrl!.isNotEmpty) ...[
                        _buildVariantImage(context, isOutOfStock),
                        const SizedBox(width: 12),
                      ],
                      Expanded(child: _buildVariantInfo(context, isOutOfStock)),
                      _buildVariantPrice(context, isOutOfStock),
                      if (isSelected && !isOutOfStock) ...[
                        const SizedBox(width: 8),
                        _buildSelectedIndicator(context),
                      ],
                    ],
                  ),
                  if (quickEditFields != null) ...[
                    const SizedBox(height: 10),
                    quickEditFields!,
                  ],
                ],
              ),
            ),
          ),
          if (isOutOfStock) _buildOutOfStockLabel(context),
        ],
      ),
    );
  }

  Widget _buildVariantImage(BuildContext context, bool isOutOfStock) {
    final theme = Theme.of(context);
    final customColors = theme.extension<AppColorExtension>()!;
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOutOfStock
              ? customColors.stockUnavailable
              : (isSelected ? theme.primaryColor : theme.dividerColor),
          width: isSelected || isOutOfStock ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          variante.immagineUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: theme.brightness == Brightness.dark
                ? Colors.grey[800]
                : Colors.grey[100],
            child: Icon(
              Icons.image,
              size: 20,
              color: theme.iconTheme.color?.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVariantInfo(BuildContext context, bool isOutOfStock) {
    final theme = Theme.of(context);
    final customColors = theme.extension<AppColorExtension>()!;
    return Row(
      children: [
        _buildColorSwatch(context),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                variante.nomeVisualizzabile,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isOutOfStock
                      ? customColors.stockUnavailable.withValues(alpha: 0.8)
                      : (isSelected
                            ? theme.primaryColor
                            : theme.textTheme.bodyLarge?.color),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              const SizedBox(height: 4),
              Text(
                'SKU: ${variante.sku}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVariantPrice(BuildContext context, bool isOutOfStock) {
    final theme = Theme.of(context);
    final customColors = theme.extension<AppColorExtension>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected && !isOutOfStock
                ? theme.primaryColor
                : customColors.priceBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            PrezzoFormatter.formatPrezzo(variante.prezzo),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isSelected && !isOutOfStock
                  ? theme.colorScheme.onPrimary
                  : customColors.stockAvailable,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory,
              size: 14,
              color: isOutOfStock
                  ? customColors.stockUnavailable
                  : (isSelected
                        ? theme.primaryColor
                        : theme.iconTheme.color?.withValues(alpha: 0.7)),
            ),
            const SizedBox(width: 4),
            Text(
              '${variante.quantita}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isOutOfStock
                    ? customColors.stockUnavailable
                    : (isSelected
                          ? theme.primaryColor
                          : theme.textTheme.bodySmall?.color?.withValues(
                              alpha: 0.7,
                            )),
                fontWeight: isSelected || isOutOfStock
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildColorSwatch(BuildContext context) {
    final colorAttr = variante.attributoColore;
    if (colorAttr == null || colorAttr.valore == null)
      return const SizedBox.shrink();
    final color = hexToColor(colorAttr.valore!);
    return Container(
      width: 28,
      height: 28,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: isSelected && variante.quantita > 0
          ? Icon(
              Icons.check,
              size: 16,
              color:
                  ThemeData.estimateBrightnessForColor(color) == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            )
          : null,
    );
  }

  Widget _buildSelectedIndicator(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.check,
        size: 16,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}

/// Dialog per rettificare lo stock di un prodotto o variante
class RettificaStockDialog extends StatefulWidget {
  final int prodottoId;
  final int? varianteId;
  final String nome;
  final int quantitaAttuale;
  final ProdottiGestioneController controller;

  const RettificaStockDialog({
    super.key,
    required this.prodottoId,
    this.varianteId,
    required this.nome,
    required this.quantitaAttuale,
    required this.controller,
  });

  @override
  State<RettificaStockDialog> createState() => _RettificaStockDialogState();
}

class _RettificaStockDialogState extends State<RettificaStockDialog> {
  late TextEditingController _quantitaController;
  String _motivo = 'conteggio';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _quantitaController = TextEditingController(
      text: widget.quantitaAttuale.toString(),
    );
  }

  @override
  void dispose() {
    _quantitaController.dispose();
    super.dispose();
  }

  Future<void> _salva() async {
    final nuovaQuantita = int.tryParse(_quantitaController.text);
    if (nuovaQuantita == null || nuovaQuantita < 0) {
      NotificationService.instance.messageBar(
        'errore',
        'prodotti_gestisci',
        'Inserisci una quantità valida',
      );
      return;
    }

    setState(() => _isLoading = true);

    bool success;
    if (widget.varianteId != null) {
      success = await widget.controller.rettificaStockVariante(
        prodottoId: widget.prodottoId,
        varianteId: widget.varianteId!,
        nuovaQuantita: nuovaQuantita,
        motivo: _motivo,
      );
    } else {
      success = await widget.controller.rettificaStockProdotto(
        prodottoId: widget.prodottoId,
        nuovaQuantita: nuovaQuantita,
        motivo: _motivo,
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop(true);
        NotificationService.instance.messageBar(
          'successo',
          'prodotti_gestisci',
          'Stock aggiornato con successo',
        );
      } else {
        NotificationService.instance.messageBar(
          'errore',
          'prodotti_gestisci',
          'Errore durante l\'aggiornamento',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.inventory, color: theme.primaryColor),
          const SizedBox(width: 8),
          const Expanded(child: Text('Rettifica Stock')),
        ],
      ),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.nome,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Quantità attuale: ${widget.quantitaAttuale}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _quantitaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nuova quantità',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _motivo,
              decoration: const InputDecoration(
                labelText: 'Motivo',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'conteggio',
                  child: Text('Conteggio inventario'),
                ),
                DropdownMenuItem(value: 'danno', child: Text('Danno/Rottura')),
                DropdownMenuItem(
                  value: 'perdita',
                  child: Text('Perdita/Furto'),
                ),
                DropdownMenuItem(
                  value: 'restituzione',
                  child: Text('Restituzione fornitore'),
                ),
                DropdownMenuItem(
                  value: 'rettifica',
                  child: Text('Rettifica manuale'),
                ),
              ],
              onChanged: (value) =>
                  setState(() => _motivo = value ?? 'conteggio'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _salva,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Salva'),
        ),
      ],
    );
  }
}

/// Helper function per mostrare il dialog di rettifica stock
Future<bool?> showRettificaStockDialog({
  required BuildContext context,
  required int prodottoId,
  int? varianteId,
  required String nome,
  required int quantitaAttuale,
  required ProdottiGestioneController controller,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => RettificaStockDialog(
      prodottoId: prodottoId,
      varianteId: varianteId,
      nome: nome,
      quantitaAttuale: quantitaAttuale,
      controller: controller,
    ),
  );
}

class _BulkCategoryDialog extends StatefulWidget {
  final List<CategoriaProdotto> categorie;

  const _BulkCategoryDialog({required this.categorie});

  @override
  State<_BulkCategoryDialog> createState() => _BulkCategoryDialogState();
}

class _BulkCategoryDialogState extends State<_BulkCategoryDialog> {
  final Set<int> _selectedCategoryIds = <int>{};
  bool _replaceExisting = false;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.categorie.where((c) {
      if (_search.trim().isEmpty) return true;
      return c.nome.toLowerCase().contains(_search.toLowerCase());
    }).toList();

    return AlertDialog(
      title: const Text('Assegna categorie a prodotti selezionati'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Cerca categoria',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _search = value),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _replaceExisting,
              onChanged: (value) {
                setState(() => _replaceExisting = value ?? false);
              },
              contentPadding: EdgeInsets.zero,
              title: const Text('Sostituisci categorie esistenti'),
              subtitle: const Text(
                'Se disattivo, le categorie selezionate vengono aggiunte.',
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final categoria = filtered[index];
                    final selected = _selectedCategoryIds.contains(
                      categoria.id,
                    );
                    return CheckboxListTile(
                      value: selected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedCategoryIds.add(categoria.id);
                          } else {
                            _selectedCategoryIds.remove(categoria.id);
                          }
                        });
                      },
                      title: Text(categoria.nome),
                      subtitle: Text('ID: ${categoria.id}'),
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: _selectedCategoryIds.isEmpty
              ? null
              : () {
                  final selected = widget.categorie
                      .where((c) => _selectedCategoryIds.contains(c.id))
                      .toList();
                  Navigator.of(
                    context,
                  ).pop((selected: selected, replace: _replaceExisting));
                },
          child: const Text('Applica'),
        ),
      ],
    );
  }
}
