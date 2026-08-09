import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../notification/notification_service.dart';
import '../../reuse_class/gui/searchable_checkbox_dialog.dart';
import '../../settings/app_settings.dart';
import '../../theme/theme.dart';
import '../class_prodotti.dart';
import '../../reuse_class/class_formtter.dart';
import '../prodotti_crea/prodotti_crea.gui.dart';
import 'prodotti_gestisci.code.dart';

const double _kDetailGap = 16;
const double _kDetailCardRadius = 18;
const double _kDetailPanePadding = 16;
const double _kDetailCardPadding = 20;

List<String> _collectDistinctImageUrls(Iterable<String?> urls) {
  final seen = <String>{};
  final ordered = <String>[];
  for (final rawUrl in urls) {
    final url = (rawUrl ?? '').trim();
    if (url.isEmpty || seen.contains(url)) continue;
    seen.add(url);
    ordered.add(url);
  }
  return ordered;
}

String _stripHtmlTags(String value) {
  final withoutTags = value.replaceAll(RegExp(r'<[^>]*>'), ' ');
  return withoutTags.replaceAll(RegExp(r'\s+'), ' ').trim();
}

Future<void> _openImageViewer(
  BuildContext context,
  String? imageUrl, {
  required String title,
}) async {
  final safeUrl = (imageUrl ?? '').trim();
  if (safeUrl.isEmpty) return;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
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
                      onPressed: () => Navigator.of(dialogContext).pop(),
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
                  child: Container(
                    color: Colors.black,
                    alignment: Alignment.center,
                    child: Image.network(
                      safeUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        color: theme.cardColor,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          size: 64,
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

class ProdottoDettagliView extends StatefulWidget {
  final ProdottoGlobal prodotto;
  final VarianteProductGlobal? varianteSelezionata;
  final ValueChanged<VarianteProductGlobal?>? onVarianteSelezionata;
  final bool showCloseButton;
  final VoidCallback? onProductDeleted;
  final VoidCallback? onVariantDeleted;
  final bool requiresDeleteConfirmation;
  final ProdottiGestioneController? controller;
  final bool variantsLoading;
  final Future<void> Function()? onReload;

  const ProdottoDettagliView({
    super.key,
    required this.prodotto,
    this.varianteSelezionata,
    this.onVarianteSelezionata,
    this.showCloseButton = false,
    this.onProductDeleted,
    this.onVariantDeleted,
    this.requiresDeleteConfirmation = true,
    this.controller,
    this.variantsLoading = false,
    this.onReload,
  });

  @override
  State<ProdottoDettagliView> createState() => _ProdottoDettagliViewState();
}

class _ProdottoDettagliViewState extends State<ProdottoDettagliView> {
  late VarianteProductGlobal? _varianteSelezionata;
  String? _selectedGalleryImageUrl;
  Map<String, String> _filtriVariantiAttivi = <String, String>{};
  List<VarianteProductGlobal> _variantiFiltrate = <VarianteProductGlobal>[];
  bool _filtraSoloInStock = false;
  bool _isEditMode = false;
  bool _isSaving = false;
  bool _bulkDelete = false;
  List<String> _selectedCategoryNames = <String>[];
  List<String> _selectedTagNames = <String>[];
  String? _selectedStatus;
  List<String> _baseCategoryNames = <String>[];
  List<String> _baseTagNames = <String>[];
  String? _baseStatus;
  final Map<int, TextEditingController> _variantPriceCtrls =
      <int, TextEditingController>{};
  final Map<int, TextEditingController> _variantQtyCtrls =
      <int, TextEditingController>{};
  final Map<int, double> _variantBasePrice = <int, double>{};
  final Map<int, int> _variantBaseQty = <int, int>{};
  final _shortcutFocusNode = FocusNode(debugLabel: 'ProdottoDettagliShortcuts');

  ProdottiGestioneController? get _controller => widget.controller;
  bool get _isMultiEdit =>
      (_controller?.selectedProductsCount ?? 0) > 1 && _isEditMode;

  @override
  void initState() {
    super.initState();
    _varianteSelezionata = widget.varianteSelezionata;
    _syncFromController();
    _syncEditStateFromProduct();
    _applicaFiltriVarianti();
  }

  @override
  void didUpdateWidget(covariant ProdottoDettagliView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.prodotto, widget.prodotto) ||
        oldWidget.prodotto.id != widget.prodotto.id ||
        oldWidget.varianteSelezionata?.id != widget.varianteSelezionata?.id) {
      _varianteSelezionata = widget.varianteSelezionata;
      _syncFromController();
      _syncEditStateFromProduct();
      _applicaFiltriVarianti();
    }
  }

  @override
  void dispose() {
    for (final controller in _variantPriceCtrls.values) {
      controller.dispose();
    }
    for (final controller in _variantQtyCtrls.values) {
      controller.dispose();
    }
    _shortcutFocusNode.dispose();
    super.dispose();
  }

  void _syncFromController() {
    final controller = _controller;
    if (controller == null) return;
    _filtriVariantiAttivi = Map<String, String>.from(
      controller.filtriVariantiAttivi,
    );
    _filtraSoloInStock = controller.filtraSoloInStock;
    _selectedGalleryImageUrl = null;
  }

  void _syncEditStateFromProduct() {
    final isMulti = (_controller?.selectedProductsCount ?? 0) > 1;
    final prodotto = widget.prodotto;

    _baseCategoryNames = QuickEditSelectionUtils.categoryNamesFromProduct(
      prodotto,
    );
    _baseTagNames = QuickEditSelectionUtils.tagNamesFromProduct(prodotto);
    _baseStatus = prodotto.status;

    _selectedCategoryNames = isMulti
        ? <String>[]
        : List<String>.from(_baseCategoryNames);
    _selectedTagNames = isMulti ? <String>[] : List<String>.from(_baseTagNames);
    _selectedStatus = isMulti ? null : _baseStatus;
    _bulkDelete = false;

    for (final controller in _variantPriceCtrls.values) {
      controller.dispose();
    }
    for (final controller in _variantQtyCtrls.values) {
      controller.dispose();
    }
    _variantPriceCtrls.clear();
    _variantQtyCtrls.clear();
    _variantBasePrice.clear();
    _variantBaseQty.clear();

    for (final variante
        in prodotto.varianti ?? const <VarianteProductGlobal>[]) {
      _variantPriceCtrls[variante.id] = TextEditingController(
        text: variante.prezzo.toStringAsFixed(2),
      );
      _variantQtyCtrls[variante.id] = TextEditingController(
        text: variante.quantita.toString(),
      );
      _variantBasePrice[variante.id] = variante.prezzo;
      _variantBaseQty[variante.id] = variante.quantita;
    }
  }

  bool get _hasPendingChanges {
    final isMulti = (_controller?.selectedProductsCount ?? 0) > 1;
    if (_bulkDelete) return true;
    if (_selectedStatus != (_baseStatus ?? '')) return true;
    if (!QuickEditSelectionUtils.hasSameNames(
      _selectedCategoryNames,
      _baseCategoryNames,
    )) {
      return true;
    }
    if (!QuickEditSelectionUtils.hasSameNames(
      _selectedTagNames,
      _baseTagNames,
    )) {
      return true;
    }
    if (isMulti) return false;

    for (final entry in _variantBasePrice.entries) {
      final current = double.tryParse(
        (_variantPriceCtrls[entry.key]?.text ?? '').replaceAll(',', '.'),
      );
      if (current != null && current != entry.value) return true;
    }
    for (final entry in _variantBaseQty.entries) {
      final current = int.tryParse(
        (_variantQtyCtrls[entry.key]?.text ?? '').trim(),
      );
      if (current != null && current != entry.value) return true;
    }
    return false;
  }

  Future<void> _openCategoryPicker() async {
    final controller = _controller;
    if (controller == null) return;
    final loaded = await controller.resolveCategoryNames(
      categoryNames: _selectedCategoryNames,
    );
    final existing = <String>{
      ..._baseCategoryNames,
      ...loaded.map((c) => c.nome),
    }.toList()..sort();
    final selected = await SearchableCheckboxDialog.show(
      context,
      title: 'Categorie prodotto',
      inputLabel: 'Filtra o nuova categoria',
      input_list: existing,
      preselected_list: _selectedCategoryNames,
    );
    if (selected == null || !mounted) return;
    setState(() {
      _selectedCategoryNames = QuickEditSelectionUtils.normalizeNames(selected);
    });
  }

  Future<void> _openTagPicker() async {
    final controller = _controller;
    if (controller == null) return;
    final loaded = await controller.resolveTagNames(
      tagNames: _selectedTagNames,
    );
    final existing = <String>{
      ..._baseTagNames,
      ...loaded.map((t) => t.nome),
    }.toList()..sort();
    final selected = await SearchableCheckboxDialog.show(
      context,
      title: 'Tag prodotto',
      inputLabel: 'Filtra o nuovo tag',
      input_list: existing,
      preselected_list: _selectedTagNames,
    );
    if (selected == null || !mounted) return;
    setState(() {
      _selectedTagNames = QuickEditSelectionUtils.normalizeNames(selected);
    });
  }

  Future<void> _confirmCancelEdit() async {
    if (!_hasPendingChanges) {
      setState(() => _isEditMode = false);
      _syncEditStateFromProduct();
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Annullare le modifiche?'),
        content: const Text(
          'Le modifiche non salvate andranno perse. Vuoi continuare?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Annulla modifiche'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _isEditMode = false;
      _syncEditStateFromProduct();
    });
  }

  Future<void> _saveAll() async {
    final controller = _controller;
    final prodotto = widget.prodotto;
    if (controller == null || prodotto.id == null || prodotto.id! <= 0) return;

    final isMulti = controller.selectedProductsCount > 1;
    if (isMulti && !controller.hasSelectedProducts) {
      NotificationService.instance.messageBar(
        'warning',
        'prodotti_gestisci',
        'Nessun prodotto selezionato per la modifica multipla.',
      );
      return;
    }

    if (!isMulti) {
      controller.clearBulkSelection();
      controller.toggleProductBulkSelection(prodotto);
    }

    if (!_hasPendingChanges) {
      NotificationService.instance.messageBar(
        'warning',
        'prodotti_gestisci',
        'Nessuna modifica da salvare.',
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final categoriesChanged = !QuickEditSelectionUtils.hasSameNames(
        _selectedCategoryNames,
        _baseCategoryNames,
      );
      final tagsChanged = !QuickEditSelectionUtils.hasSameNames(
        _selectedTagNames,
        _baseTagNames,
      );
      final normalizedStatus = (_selectedStatus ?? '').trim().toLowerCase();
      final baseStatus = (_baseStatus ?? '').trim().toLowerCase();
      final statusChanged =
          normalizedStatus.isNotEmpty && normalizedStatus != baseStatus;

      var categoryResult = const BulkCategoryUpdateResult(
        successCount: 0,
        failedCount: 0,
        message: 'Nessuna modifica categorie.',
      );
      if (categoriesChanged) {
        final categories = await controller.resolveCategoryNames(
          categoryNames: _selectedCategoryNames,
        );
        categoryResult = await controller.bulkUpdateSelectedProductCategories(
          categorie: categories,
          replaceExisting: false,
        );
      }

      var tagResult = const BulkCategoryUpdateResult(
        successCount: 0,
        failedCount: 0,
        message: 'Nessuna modifica tag.',
      );
      if (tagsChanged) {
        final tags = await controller.resolveTagNames(
          tagNames: _selectedTagNames,
        );
        tagResult = await controller.bulkUpdateSelectedProductTags(
          tags: tags,
          replaceExisting: false,
        );
      }

      var statusResult = const BulkCategoryUpdateResult(
        successCount: 0,
        failedCount: 0,
        message: 'Nessuna modifica stato.',
      );
      if (statusChanged) {
        statusResult = await controller.bulkUpdateSelectedProductsStatus(
          status: normalizedStatus,
        );
      }

      var deleteResult = const BulkCategoryUpdateResult(
        successCount: 0,
        failedCount: 0,
        message: 'Nessuna eliminazione.',
      );
      if (isMulti && _bulkDelete) {
        final settings = AppSettings();
        await settings.init();
        deleteResult = await controller.deleteSelectedProducts(
          force: settings.forceDelete,
        );
      }

      var variantResult = const QuickVariantSaveResult(
        updated: 0,
        failed: 0,
        message: 'Nessuna modifica varianti.',
      );
      if (!isMulti) {
        final edits = <int, QuickVariantEdit>{};
        for (final variante
            in prodotto.varianti ?? const <VarianteProductGlobal>[]) {
          final newPrice = double.tryParse(
            (_variantPriceCtrls[variante.id]?.text ?? '').replaceAll(',', '.'),
          );
          final newQty = int.tryParse(
            (_variantQtyCtrls[variante.id]?.text ?? '').trim(),
          );
          if (newPrice != null && newQty != null) {
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
        }
        if (edits.isNotEmpty) {
          variantResult = await controller.saveVariantQuickEdits(
            productId: prodotto.id!,
            edits: edits,
          );
        }
      }

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

      controller.clearBulkSelection();
      await widget.onReload?.call();
      widget.onProductDeleted?.call();
      if (!mounted) return;
      setState(() {
        _isEditMode = false;
        _syncEditStateFromProduct();
      });
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

  KeyEventResult _handleShortcutKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (_isEditMode && !_isSaving) Future<void>(_confirmCancelEdit);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _selezionaVariante(VarianteProductGlobal? variante) {
    setState(() {
      _varianteSelezionata = variante;
      _selectedGalleryImageUrl = null;
    });
    _controller?.selezionaVariante(variante);
    widget.onVarianteSelezionata?.call(variante);
  }

  String _getCurrentImageUrl() {
    if (_varianteSelezionata?.immagineUrl != null &&
        _varianteSelezionata!.immagineUrl!.trim().isNotEmpty) {
      return _varianteSelezionata!.immagineUrl!;
    }
    return widget.prodotto.immagineUrl ?? '';
  }

  Map<String, List<AttributoVariante>> _getOpzioniFiltroDisponibili() {
    if (_controller != null) {
      return _controller!.getOpzioniFiltroDisponibili();
    }

    final opzioniUniche = <String, Map<String, AttributoVariante>>{};
    for (final variante
        in widget.prodotto.varianti ?? const <VarianteProductGlobal>[]) {
      for (final attributo in variante.attributi) {
        opzioniUniche[attributo.nome] ??= <String, AttributoVariante>{};
        opzioniUniche[attributo.nome]![attributo.opzione] = attributo;
      }
    }

    final risultato = <String, List<AttributoVariante>>{};
    opzioniUniche.forEach((nomeAttributo, mappaOpzioni) {
      risultato[nomeAttributo] = mappaOpzioni.values.toList();
    });
    return risultato;
  }

  void _setFiltroVariante(String nomeAttributo, String opzione) {
    _controller?.setFiltroVariante(nomeAttributo, opzione);
    setState(() {
      if (_filtriVariantiAttivi[nomeAttributo] == opzione) {
        _filtriVariantiAttivi.remove(nomeAttributo);
      } else {
        _filtriVariantiAttivi[nomeAttributo] = opzione;
      }
      _applicaFiltriVarianti();
    });
  }

  void _cancellaFiltriVarianti() {
    _controller?.cancellaFiltriVarianti();
    setState(() {
      _filtriVariantiAttivi.clear();
      _applicaFiltriVarianti();
    });
  }

  void _applicaFiltriVarianti() {
    final varianti =
        widget.prodotto.varianti ?? const <VarianteProductGlobal>[];
    var filtered = varianti.where((variante) {
      for (final entry in _filtriVariantiAttivi.entries) {
        final haAttributoCorretto = variante.attributi.any(
          (attributo) =>
              attributo.nome == entry.key && attributo.opzione == entry.value,
        );
        if (!haAttributoCorretto) return false;
      }
      return true;
    }).toList();

    if (_filtraSoloInStock) {
      filtered = filtered.where((v) => v.quantita > 0).toList();
    }

    _variantiFiltrate = filtered;
    if (_varianteSelezionata != null &&
        !_variantiFiltrate.any((v) => v.id == _varianteSelezionata!.id)) {
      _varianteSelezionata = null;
    }
  }

  Future<void> _handleAction(_DettaglioAction action) async {
    switch (action) {
      case _DettaglioAction.crea:
        final created = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(builder: (_) => const ProdottiCreaPage()),
        );
        if (created == true) {
          await widget.onReload?.call();
        }
        break;
      case _DettaglioAction.modifica:
        final updated = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) =>
                ProdottiCreaPage(prodottoDaModificare: widget.prodotto),
          ),
        );
        if (updated == true) {
          await widget.onReload?.call();
        }
        break;
      case _DettaglioAction.elimina:
        final controller = _controller;
        if (controller == null) return;
        final confirmed = !widget.requiresDeleteConfirmation
            ? true
            : await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Elimina prodotto'),
                      content: Text(
                        'Confermi eliminazione di "${widget.prodotto.nome}"?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          child: const Text('Annulla'),
                        ),
                        FilledButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          child: const Text('Elimina'),
                        ),
                      ],
                    ),
                  ) ??
                  false;

        if (!confirmed) return;
        final productId = widget.prodotto.id ?? 0;
        if (productId <= 0) return;
        final removed = await controller.eliminaProdotto(productId);
        if (!mounted) return;
        NotificationService.instance.messageBar(
          removed ? 'successo' : 'errore',
          'prodotti_gestisci',
          removed
              ? 'Prodotto eliminato con successo.'
              : 'Eliminazione prodotto non riuscita.',
        );
        if (removed) {
          widget.onProductDeleted?.call();
          await widget.onReload?.call();
          if (widget.showCloseButton && mounted) {
            Navigator.of(context).maybePop();
          }
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<AppColorExtension>()!;
    final description = _stripHtmlTags(widget.prodotto.descrizioneBreve ?? '');
    final prezzoInfo = ProdottoUtils.getPricingInfo(widget.prodotto);
    final currentImage = _getCurrentImageUrl();
    final galleryImages = _collectDistinctImageUrls([
      currentImage,
      ...widget.prodotto.tutteLeImmagini,
    ]);
    final displayedImage = galleryImages.contains(_selectedGalleryImageUrl)
        ? _selectedGalleryImageUrl!
        : currentImage;

    final body = Focus(
      focusNode: _shortcutFocusNode,
      autofocus: true,
      onKeyEvent: _handleShortcutKey,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              customColors.gradientStart.withValues(alpha: 0.28),
              theme.colorScheme.surface.withValues(alpha: 0.96),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(_kDetailPanePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DettaglioHeader(
                prodotto: widget.prodotto,
                showCloseButton: widget.showCloseButton,
                onAction: _handleAction,
              ),
              const SizedBox(height: _kDetailGap),
              _DettaglioHero(
                prodotto: widget.prodotto,
                currentImage: displayedImage,
                galleryImages: galleryImages,
                onSelectImage: (imageUrl) {
                  setState(() {
                    _selectedGalleryImageUrl = imageUrl;
                  });
                },
              ),
              const SizedBox(height: _kDetailGap),
              _PaneCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.prodotto.nome ?? '',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _StatusPill(
                          label: ProdottoUtils.getStatusLabel(
                            widget.prodotto.status,
                          ),
                          color: theme.primaryColor,
                        ),
                        _StatusPill(
                          label: ClassFormtter.getDisponibilitaText(
                            widget.prodotto.inStock,
                          ),
                          color: widget.prodotto.inStock
                              ? customColors.stockAvailable
                              : customColors.stockUnavailable,
                        ),
                        _StatusPill(
                          label: prezzoInfo.prezzoLabel,
                          color: customColors.successColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: _kDetailGap),
                _PaneCard(
                  tinted: true,
                  child: Text(description, style: theme.textTheme.bodyMedium),
                ),
              ],
              const SizedBox(height: _kDetailGap),
              _ReadonlyInfoCard(
                prodotto: widget.prodotto,
                prezzoInfo: prezzoInfo,
              ),
              const SizedBox(height: _kDetailGap),
              _QuickEditCard(
                isEditMode: _isEditMode,
                isSaving: _isSaving,
                isMultiEdit: _isMultiEdit,
                bulkDelete: _bulkDelete,
                selectedCategoryNames: _selectedCategoryNames,
                selectedTagNames: _selectedTagNames,
                selectedStatus: _selectedStatus,
                onToggleEdit: () {
                  if (_isSaving) return;
                  setState(() {
                    _isEditMode = true;
                  });
                },
                onCancelEdit: _confirmCancelEdit,
                onSaveAll: _saveAll,
                onBulkDeleteChanged: (value) =>
                    setState(() => _bulkDelete = value),
                onOpenCategoryPicker: _openCategoryPicker,
                onOpenTagPicker: _openTagPicker,
                onStatusChanged: (value) =>
                    setState(() => _selectedStatus = value),
              ),
              const SizedBox(height: _kDetailGap),
              _VariantFiltersCard(
                opzioniFiltro: _getOpzioniFiltroDisponibili(),
                filtriAttivi: _filtriVariantiAttivi,
                filtraSoloInStock: _filtraSoloInStock,
                onFilterSelected: _setFiltroVariante,
                onClearFilters: _cancellaFiltriVarianti,
                onToggleStockOnly: (value) {
                  setState(() {
                    _filtraSoloInStock = value;
                    _controller?.setFiltraSoloInStock(value);
                    _applicaFiltriVarianti();
                  });
                },
              ),
              const SizedBox(height: _kDetailGap),
              if (widget.variantsLoading)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Caricamento varianti...',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              _VariantsListCard(
                varianti: _variantiFiltrate,
                selectedVarianteId: _varianteSelezionata?.id,
                onSelect: _selezionaVariante,
                isEditMode: _isEditMode && !_isMultiEdit,
                variantPriceCtrls: _variantPriceCtrls,
                variantQtyCtrls: _variantQtyCtrls,
              ),
              const SizedBox(height: _kDetailGap),
              _VariantMediaMapCard(
                varianti:
                    widget.prodotto.varianti ?? const <VarianteProductGlobal>[],
                selectedVarianteId: _varianteSelezionata?.id,
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.showCloseButton) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(widget.prodotto.nome ?? 'Dettaglio prodotto'),
        ),
        body: body,
      );
    }

    return body;
  }
}

enum _DettaglioAction { modifica, elimina, crea }

class _PaneCard extends StatelessWidget {
  final Widget child;
  final bool tinted;
  final EdgeInsetsGeometry padding;

  const _PaneCard({
    required this.child,
    this.tinted = false,
    this.padding = const EdgeInsets.all(_kDetailCardPadding),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<AppColorExtension>()!;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: tinted
            ? customColors.variantSelectedBackground.withValues(alpha: 0.55)
            : theme.cardColor.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(_kDetailCardRadius),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.42)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DettaglioHeader extends StatelessWidget {
  final ProdottoGlobal prodotto;
  final bool showCloseButton;
  final Future<void> Function(_DettaglioAction action) onAction;

  const _DettaglioHeader({
    required this.prodotto,
    required this.showCloseButton,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<AppColorExtension>()!;
    return _PaneCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.inventory_2_outlined, color: theme.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  showCloseButton ? 'Scheda prodotto' : 'Pannello dettaglio',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  prodotto.sku?.trim().isNotEmpty == true
                      ? 'SKU ${prodotto.sku}'
                      : 'Catalogo prodotti',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: customColors.subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<_DettaglioAction>(
            tooltip: 'Azioni prodotto',
            onSelected: onAction,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _DettaglioAction.modifica,
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined),
                    SizedBox(width: 8),
                    Text('Modifica'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _DettaglioAction.elimina,
                child: Row(
                  children: [
                    Icon(Icons.delete_outline),
                    SizedBox(width: 8),
                    Text('Elimina'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _DettaglioAction.crea,
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
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.primaryColor.withValues(alpha: 0.18),
                ),
              ),
              child: Icon(Icons.more_horiz, color: theme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _DettaglioHero extends StatelessWidget {
  final ProdottoGlobal prodotto;
  final String currentImage;
  final List<String> galleryImages;
  final ValueChanged<String> onSelectImage;

  const _DettaglioHero({
    required this.prodotto,
    required this.currentImage,
    required this.galleryImages,
    required this.onSelectImage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<AppColorExtension>()!;
    return _PaneCard(
      tinted: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.primaryColor.withValues(alpha: 0.08),
              customColors.gradientEnd.withValues(alpha: 0.18),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: theme.primaryColor.withValues(alpha: 0.16),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ColoredBox(
                          color: theme.colorScheme.surface,
                          child: currentImage.trim().isEmpty
                              ? const _ImagePlaceholder(height: 220)
                              : Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Image.network(
                                    currentImage,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) =>
                                        const _ImagePlaceholder(height: 220),
                                  ),
                                ),
                        ),
                      ),
                      if (currentImage.trim().isNotEmpty)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: FilledButton.icon(
                            onPressed: () => _openImageViewer(
                              context,
                              currentImage,
                              title: prodotto.nome ?? 'Immagine prodotto',
                            ),
                            icon: const Icon(Icons.zoom_out_map, size: 18),
                            label: const Text('Apri'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (galleryImages.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  'Foto prodotto',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.primaryColor,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 74,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: galleryImages.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final imageUrl = galleryImages[index];
                      return _ImageThumbnail(
                        imageUrl: imageUrl,
                        isActive: imageUrl == currentImage,
                        onTap: () => onSelectImage(imageUrl),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tocca una miniatura per cambiare immagine. Usa Apri per lo zoom.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadonlyInfoCard extends StatelessWidget {
  final ProdottoGlobal prodotto;
  final ProdottoPricingInfo prezzoInfo;

  const _ReadonlyInfoCard({required this.prodotto, required this.prezzoInfo});

  @override
  Widget build(BuildContext context) {
    return _PaneCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.info_outline,
            title: 'Informazioni Prodotto',
          ),
          const SizedBox(height: _kDetailGap),
          _InfoRow(label: 'ID', value: '${prodotto.id ?? '-'}'),
          _InfoRow(label: 'SKU', value: prodotto.sku ?? '-'),
          _InfoRow(
            label: 'Categoria',
            value: prodotto.categoria?.map((c) => c.nome).join(', ') ?? '-',
          ),
          _InfoRow(
            label: 'Tag',
            value: prodotto.tag?.map((t) => t.nome).join(', ') ?? '-',
          ),
          _InfoRow(
            label: 'Stato',
            value: ProdottoUtils.getStatusLabel(prodotto.status),
          ),
          _InfoRow(
            label: 'Disponibilità',
            value: ClassFormtter.getDisponibilitaText(prodotto.inStock),
          ),
          _InfoRow(label: 'Prezzo', value: prezzoInfo.prezzoLabel),
          _InfoRow(label: 'Sconto', value: prezzoInfo.scontoLabel),
          _InfoRow(label: 'Marca', value: prodotto.marca ?? '-'),
        ],
      ),
    );
  }
}

class _VariantFiltersCard extends StatelessWidget {
  final Map<String, List<AttributoVariante>> opzioniFiltro;
  final Map<String, String> filtriAttivi;
  final bool filtraSoloInStock;
  final void Function(String nomeAttributo, String opzione) onFilterSelected;
  final VoidCallback onClearFilters;
  final ValueChanged<bool> onToggleStockOnly;

  const _VariantFiltersCard({
    required this.opzioniFiltro,
    required this.filtriAttivi,
    required this.filtraSoloInStock,
    required this.onFilterSelected,
    required this.onClearFilters,
    required this.onToggleStockOnly,
  });

  @override
  Widget build(BuildContext context) {
    if (opzioniFiltro.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return _PaneCard(
      tinted: true,
      padding: const EdgeInsets.all(_kDetailPanePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: _SectionTitle(
                  icon: Icons.filter_alt_outlined,
                  title: 'Filtra varianti',
                ),
              ),
              const Spacer(),
              if (filtriAttivi.isNotEmpty)
                TextButton(
                  onPressed: onClearFilters,
                  child: const Text('Pulisci'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ...opzioniFiltro.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: entry.value.map((opzione) {
                      final selected =
                          filtriAttivi[entry.key] == opzione.opzione;
                      return FilterChip(
                        label: Text(opzione.opzione),
                        selected: selected,
                        onSelected: (_) =>
                            onFilterSelected(entry.key, opzione.opzione),
                        selectedColor: theme.primaryColor,
                        labelStyle: TextStyle(
                          color: selected ? theme.colorScheme.onPrimary : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }),
          CheckboxListTile(
            value: filtraSoloInStock,
            onChanged: (value) => onToggleStockOnly(value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('Mostra solo disponibili'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ],
      ),
    );
  }
}

class _QuickEditCard extends StatelessWidget {
  final bool isEditMode;
  final bool isSaving;
  final bool isMultiEdit;
  final bool bulkDelete;
  final List<String> selectedCategoryNames;
  final List<String> selectedTagNames;
  final String? selectedStatus;
  final VoidCallback onToggleEdit;
  final Future<void> Function() onCancelEdit;
  final Future<void> Function() onSaveAll;
  final ValueChanged<bool> onBulkDeleteChanged;
  final Future<void> Function() onOpenCategoryPicker;
  final Future<void> Function() onOpenTagPicker;
  final ValueChanged<String?> onStatusChanged;

  const _QuickEditCard({
    required this.isEditMode,
    required this.isSaving,
    required this.isMultiEdit,
    required this.bulkDelete,
    required this.selectedCategoryNames,
    required this.selectedTagNames,
    required this.selectedStatus,
    required this.onToggleEdit,
    required this.onCancelEdit,
    required this.onSaveAll,
    required this.onBulkDeleteChanged,
    required this.onOpenCategoryPicker,
    required this.onOpenTagPicker,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _PaneCard(
      tinted: true,
      padding: const EdgeInsets.all(_kDetailPanePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _SectionTitle(
                  icon: Icons.edit_note_outlined,
                  title: isMultiEdit ? 'Modifica multipla' : 'Modifica rapida',
                ),
              ),
              FilledButton.icon(
                onPressed: (isSaving || isEditMode) ? null : onToggleEdit,
                icon: Icon(isEditMode ? Icons.lock_open : Icons.edit),
                label: Text(isEditMode ? 'Modifica attiva' : 'Modifica rapida'),
              ),
              const SizedBox(width: 8),
              if (isEditMode)
                OutlinedButton(
                  onPressed: isSaving ? null : onCancelEdit,
                  child: const Text('Annulla'),
                ),
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
            const SizedBox(height: 16),
            if (isMultiEdit)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Modalita multi-select: sono editabili categorie, tag, stato ed eliminazione.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: isSaving ? null : onOpenCategoryPicker,
                  icon: const Icon(Icons.category_outlined),
                  label: Text(
                    selectedCategoryNames.isEmpty
                        ? 'Categorie'
                        : 'Categorie (${selectedCategoryNames.length})',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: isSaving ? null : onOpenTagPicker,
                  icon: const Icon(Icons.tag),
                  label: Text(
                    selectedTagNames.isEmpty
                        ? 'Tag'
                        : 'Tag (${selectedTagNames.length})',
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    initialValue: (selectedStatus ?? '').trim().isEmpty
                        ? null
                        : selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Stato',
                      isDense: true,
                      prefixIcon: Icon(Icons.public),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'publish',
                        child: Text('Pubblico'),
                      ),
                      DropdownMenuItem(
                        value: 'private',
                        child: Text('Privato'),
                      ),
                      DropdownMenuItem(value: 'draft', child: Text('Bozza')),
                      DropdownMenuItem(
                        value: 'pending',
                        child: Text('In revisione'),
                      ),
                    ],
                    onChanged: isSaving ? null : onStatusChanged,
                  ),
                ),
              ],
            ),
            if (isMultiEdit) ...[
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                value: bulkDelete,
                onChanged: isSaving ? null : onBulkDeleteChanged,
                contentPadding: EdgeInsets.zero,
                title: const Text('Elimina prodotti selezionati'),
                subtitle: const Text(
                  'Usa soft/hard delete in base alle impostazioni.',
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _VariantsListCard extends StatelessWidget {
  final List<VarianteProductGlobal> varianti;
  final int? selectedVarianteId;
  final ValueChanged<VarianteProductGlobal> onSelect;
  final bool isEditMode;
  final Map<int, TextEditingController> variantPriceCtrls;
  final Map<int, TextEditingController> variantQtyCtrls;

  const _VariantsListCard({
    required this.varianti,
    required this.selectedVarianteId,
    required this.onSelect,
    required this.isEditMode,
    required this.variantPriceCtrls,
    required this.variantQtyCtrls,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<AppColorExtension>()!;
    return _PaneCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.palette,
            title: 'Varianti Disponibili',
            trailing: _StatusPill(
              label: '${varianti.length}',
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(height: _kDetailGap),
          if (varianti.isEmpty)
            Text('Nessuna variante trovata.', style: theme.textTheme.bodyMedium)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: varianti.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final variante = varianti[index];
                final isSelected = variante.id == selectedVarianteId;
                final isOutOfStock = variante.quantita < 1;
                return InkWell(
                  onTap: () => onSelect(variante),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: isSelected
                          ? customColors.variantSelectedBackground
                          : theme.colorScheme.surface.withValues(alpha: 0.72),
                      border: Border.all(
                        color: isSelected
                            ? theme.primaryColor.withValues(alpha: 0.7)
                            : theme.dividerColor.withValues(alpha: 0.42),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        if ((variante.immagineUrl ?? '').trim().isNotEmpty) ...[
                          _ImageThumbnail(
                            imageUrl: variante.immagineUrl!,
                            isActive: isSelected,
                            onTap: () => _openImageViewer(
                              context,
                              variante.immagineUrl,
                              title: variante.nomeVisualizzabile,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                variante.nomeVisualizzabile,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: isSelected ? theme.primaryColor : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'SKU: ${variante.sku}',
                                style: theme.textTheme.bodySmall,
                              ),
                              if (variante.attributi.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  variante.attributi
                                      .map(
                                        (item) =>
                                            '${item.nome}: ${item.opzione}',
                                      )
                                      .join(' • '),
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                              if (isEditMode) ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller:
                                            variantPriceCtrls[variante.id],
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
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
                                        controller:
                                            variantQtyCtrls[variante.id],
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Quantita',
                                          prefixIcon: Icon(
                                            Icons.inventory_2_outlined,
                                          ),
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              ClassFormtter.formatPrezzo(variante.prezzo),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _StatusPill(
                              label: isOutOfStock ? 'Esaurito' : 'Disponibile',
                              color: isOutOfStock
                                  ? customColors.stockUnavailable
                                  : customColors.stockAvailable,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Qty ${variante.quantita}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _VariantMediaMapCard extends StatelessWidget {
  final List<VarianteProductGlobal> varianti;
  final int? selectedVarianteId;

  const _VariantMediaMapCard({
    required this.varianti,
    required this.selectedVarianteId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<AppColorExtension>()!;
    return _PaneCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.photo_library_outlined,
            title: 'Foto per Variante',
          ),
          const SizedBox(height: 10),
          Text(
            varianti.isEmpty
                ? 'Questo prodotto non ha varianti.'
                : 'Qui vedi subito quali immagini appartengono a ogni variante.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: customColors.subtitleColor,
            ),
          ),
          if (varianti.isNotEmpty) ...[
            const SizedBox(height: _kDetailGap),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: varianti.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final variante = varianti[index];
                final images = _collectDistinctImageUrls(
                  variante.tutteLeImmagini,
                );
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selectedVarianteId == variante.id
                        ? customColors.variantSelectedBackground
                        : theme.colorScheme.surface.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selectedVarianteId == variante.id
                          ? theme.primaryColor.withValues(alpha: 0.55)
                          : theme.dividerColor.withValues(alpha: 0.42),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        variante.nomeVisualizzabile,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: selectedVarianteId == variante.id
                              ? theme.primaryColor
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        variante.attributi.isEmpty
                            ? 'SKU: ${variante.sku}'
                            : '${variante.attributi.map((item) => '${item.nome}: ${item.opzione}').join(' • ')}\nSKU: ${variante.sku}',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 10),
                      if (images.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: theme.inputDecorationTheme.fillColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.dividerColor.withValues(alpha: 0.36),
                            ),
                          ),
                          child: Text(
                            'Questa variante non ha foto dedicate: usa le foto del prodotto.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: images
                              .map(
                                (image) => _ImageThumbnail(
                                  imageUrl: image,
                                  isActive: selectedVarianteId == variante.id,
                                  onTap: () => _openImageViewer(
                                    context,
                                    image,
                                    title: variante.nomeVisualizzabile,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;

  const _SectionTitle({required this.icon, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: theme.primaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
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
            width: 110,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
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

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _ImageThumbnail extends StatelessWidget {
  final String imageUrl;
  final bool isActive;
  final VoidCallback onTap;

  const _ImageThumbnail({
    required this.imageUrl,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 74,
        height: 74,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? theme.primaryColor
                : theme.dividerColor.withValues(alpha: 0.45),
            width: isActive ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const _ImagePlaceholder(height: 74),
          ),
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final double height;

  const _ImagePlaceholder({required this.height});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: height,
      color: theme.primaryColor.withValues(alpha: 0.05),
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: theme.primaryColor.withValues(alpha: 0.55),
        size: 36,
      ),
    );
  }
}
