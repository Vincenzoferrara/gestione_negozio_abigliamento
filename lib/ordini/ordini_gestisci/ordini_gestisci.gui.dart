import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../login/jwt_api/adapter/platform_manager.dart';
import '../../notification/notification_service.dart';
import '../../prodotti/class_prodotti.dart';
import '../../prodotti/prodotti_gestisci/prodotti_gestisci_view.gui.dart';
import '../../reuse_class/barcode/barcode_scanner.dart';
import '../../reuse_class/image_url_resolver.dart';
import '../../theme/theme.dart';
import 'ordini_gestisci.code.dart';
import '../ordini_crea/ordini_crea.gui.dart';
import '../class_ordini.dart';

/// Pagina principale per la gestione degli ordini
class OrdiniGestisciPage extends StatefulWidget {
  const OrdiniGestisciPage({super.key});

  @override
  OrdiniGestisciPageState createState() => OrdiniGestisciPageState();
}

class OrdiniGestisciPageState extends State<OrdiniGestisciPage> {
  final OrdiniGestioneController _controller = OrdiniGestioneController();

  @override
  void initState() {
    super.initState();
    _caricaOrdini();
  }

  Future<void> _caricaOrdini() async {
    await _controller.caricaOrdini();
    if (mounted) {
      setState(() {});
    }
  }

  void _updateState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostraDialogCreaOrdine(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuovo Ordine'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Future<void> _mostraDialogCreaOrdine(BuildContext context) async {
    final ordine = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrdiniCreaPage(controller: _controller),
      ),
    );

    // Ricarica la lista se un ordine è stato creato
    if (ordine != null && mounted) {
      await _caricaOrdini();
    }
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _FiltriWidget(
          controller: _controller,
          onStateChanged: _updateState,
          onRefresh: _caricaOrdini,
        ),
        Expanded(child: _buildListaOrdini(isSmallScreen: true)),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _FiltriWidget(
                controller: _controller,
                onStateChanged: _updateState,
                onRefresh: _caricaOrdini,
              ),
              Expanded(child: _buildListaOrdini(isSmallScreen: false)),
            ],
          ),
        ),
        VerticalDivider(width: 1, color: Theme.of(context).dividerColor),
        Expanded(
          flex: 2,
          child: _controller.hasOrdineSelezionato
              ? _OrdineDettagli(ordine: _controller.ordineSelezionato!)
              : _buildEmptyState(),
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
            Icons.receipt_long_outlined,
            size: 64,
            color: theme.iconTheme.color?.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Seleziona un ordine',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaOrdini({required bool isSmallScreen}) {
    if (_controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_controller.errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _caricaOrdini,
              icon: const Icon(Icons.refresh),
              label: const Text('Riprova'),
            ),
          ],
        ),
      );
    }

    if (_controller.ordini.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Nessun ordine trovato',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _controller.ordini.length,
      itemBuilder: (context, index) => _OrdineListItem(
        ordine: _controller.ordini[index],
        isSelected: _controller.isOrdineSelezionato(_controller.ordini[index]),
        onTap: () {
          final ordine = _controller.ordini[index];
          if (isSmallScreen) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => _OrdineDettagliPage(ordine: ordine),
              ),
            );
            return;
          }

          _controller.selezionaOrdine(ordine);
          _updateState();
        },
      ),
    );
  }
}

class _OrdineDettagliPage extends StatelessWidget {
  final OrdiniGlobal ordine;

  const _OrdineDettagliPage({required this.ordine});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ordine #${ordine.number}')),
      body: _OrdineDettagli(ordine: ordine),
    );
  }
}

/// Widget per i filtri e la ricerca
class _FiltriWidget extends StatefulWidget {
  final OrdiniGestioneController controller;
  final VoidCallback onStateChanged;
  final VoidCallback onRefresh;

  const _FiltriWidget({
    required this.controller,
    required this.onStateChanged,
    required this.onRefresh,
  });

  @override
  _FiltriWidgetState createState() => _FiltriWidgetState();
}

class _FiltriWidgetState extends State<_FiltriWidget> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getStatusText(OrdineStatus? status) {
    if (status == null) return 'Tutti gli stati';
    return status.testoItaliano;
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
                    hintText: 'Cerca per ID o cliente...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              widget.controller.setSearchQuery('');
                              widget.onStateChanged();
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    widget.controller.setSearchQuery(value);
                    widget.onStateChanged();
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: widget.onRefresh,
                icon: const Icon(Icons.refresh),
                tooltip: 'Aggiorna',
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).primaryColor.withValues(alpha: 0.1),
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
              child: DropdownButton<OrdineStatus?>(
                value: widget.controller.filtroStatus,
                isExpanded: true,
                icon: Icon(
                  Icons.filter_list,
                  color: Theme.of(context).primaryColor,
                ),
                onChanged: (OrdineStatus? newValue) {
                  widget.controller.setFiltroStatus(newValue);
                  widget.onRefresh();
                },
                items: [
                  DropdownMenuItem<OrdineStatus?>(
                    value: null,
                    child: Text(_getStatusText(null)),
                  ),
                  ...OrdineStatus.values.map((status) {
                    return DropdownMenuItem<OrdineStatus?>(
                      value: status,
                      child: Text(_getStatusText(status)),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget per ogni elemento della lista ordini
class _OrdineListItem extends StatelessWidget {
  final OrdiniGlobal ordine;
  final bool isSelected;
  final VoidCallback onTap;

  const _OrdineListItem({
    required this.ordine,
    required this.isSelected,
    required this.onTap,
  });

  Color _getStatusColor(BuildContext context, OrdineStatus? status) {
    if (status == null) return Colors.grey;

    final customColors = Theme.of(context).extension<AppColorExtension>()!;

    switch (status) {
      case OrdineStatus.completed:
        return customColors.successColor;
      case OrdineStatus.processing:
        return Colors.blue;
      case OrdineStatus.pending:
        return customColors.warningColor;
      case OrdineStatus.cancelled:
      case OrdineStatus.failed:
        return customColors.errorColorStatus;
      case OrdineStatus.refunded:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(OrdineStatus? status) {
    if (status == null) return 'Sconosciuto';
    return status.testoItaliano;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<AppColorExtension>()!;

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final dataOrdine = ordine.dateCreated != null
        ? dateFormat.format(ordine.dateCreated!)
        : 'N/D';

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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ordine #${ordine.number}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? theme.primaryColor : null,
                          ),
                        ),
                        Text(
                          '${ordine.billing?.firstName ?? ''} ${ordine.billing?.lastName ?? ''}'
                              .trim(),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${ordine.total?.toStringAsFixed(2) ?? '0.00'} ${ordine.currency ?? 'EUR'}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: customColors.successColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(dataOrdine, style: theme.textTheme.bodySmall),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        context,
                        ordine.status,
                      ).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(
                          context,
                          ordine.status,
                        ).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      _getStatusLabel(ordine.status),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _getStatusColor(context, ordine.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget per visualizzare i dettagli di un ordine
class _OrdineDettagli extends StatefulWidget {
  final OrdiniGlobal ordine;

  const _OrdineDettagli({required this.ordine});

  @override
  State<_OrdineDettagli> createState() => _OrdineDettagliState();
}

class _OrdineDettagliState extends State<_OrdineDettagli> {
  final Map<int, ProdottoGlobal> _prodottiOrdine = {};
  final Set<int> _productIdsRichiesti = {};

  @override
  void initState() {
    super.initState();
    _caricaProdottiOrdine();
  }

  @override
  void didUpdateWidget(covariant _OrdineDettagli oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ordine.id != widget.ordine.id ||
        oldWidget.ordine.lineItems != widget.ordine.lineItems) {
      _caricaProdottiOrdine();
    }
  }

  Future<void> _caricaProdottiOrdine() async {
    final List<int> productIds =
        widget.ordine.lineItems
            ?.map((item) => item.productId)
            .whereType<int>()
            .where(_productIdsRichiesti.add)
            .toList() ??
        [];
    if (productIds.isEmpty) return;

    final prodottiCaricati = await Future.wait(
      productIds.map((productId) async {
        try {
          return MapEntry<int, ProdottoGlobal>(
            productId,
            await PlatformManager.prodotti.getProductById(productId),
          );
        } catch (_) {
          return null;
        }
      }),
    );
    if (!mounted) return;

    setState(() {
      _prodottiOrdine.addEntries(
        prodottiCaricati.whereType<MapEntry<int, ProdottoGlobal>>(),
      );
    });
  }

  String? _immagineProdotto(ProdottoOrdine item) {
    final productId = item.productId;
    if (productId == null) return null;

    final prodotto = _prodottiOrdine[productId];
    if (prodotto == null) return null;

    final variationId = item.variationId;
    if (variationId != null) {
      for (final variante in prodotto.varianti ?? <VarianteProductGlobal>[]) {
        if (variante.id == variationId) {
          return resolveImageUrl(variante.immagineUrl ?? prodotto.immagineUrl);
        }
      }
    }

    return resolveImageUrl(prodotto.immagineUrl);
  }

  String _nomeProdotto(ProdottoOrdine item) {
    final nome = (item.name ?? '').trim();
    return nome.isNotEmpty ? nome : 'Prodotto senza nome';
  }

  String _formatImporto(double? value) {
    return NumberFormat('#,##0.00').format(value ?? 0);
  }

  ProdottoGlobal? _prodottoDaItem(ProdottoOrdine item) {
    final productId = item.productId;
    if (productId == null) return null;
    return _prodottiOrdine[productId];
  }

  void _mostraErroreProdotto(String message) {
    NotificationService.instance.messageBar('errore', 'ordini', message);
  }

  Future<void> _apriFotoProdotto(
    BuildContext context,
    ProdottoOrdine item,
  ) async {
    final safeUrl = (_immagineProdotto(item) ?? '').trim();
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
                          _nomeProdotto(item),
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

  Future<void> _apriProdottoInNegozio(ProdottoOrdine item) async {
    final prodotto = _prodottoDaItem(item);
    if (prodotto == null) {
      _mostraErroreProdotto(
        'Prodotto non ancora caricato: ${_nomeProdotto(item)}',
      );
      return;
    }

    final permalink = (prodotto.permalink ?? '').trim();
    if (permalink.isEmpty) {
      _mostraErroreProdotto(
        'Link negozio non disponibile per ${_nomeProdotto(item)}',
      );
      return;
    }

    try {
      final launched = await launchUrl(
        Uri.parse(permalink),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        _mostraErroreProdotto('Impossibile aprire il prodotto in negozio');
      }
    } catch (_) {
      _mostraErroreProdotto('Impossibile aprire il prodotto in negozio');
    }
  }

  void _apriDettaglioProdotto(BuildContext context, ProdottoOrdine item) {
    final prodotto = _prodottoDaItem(item);
    if (prodotto == null) {
      _mostraErroreProdotto(
        'Prodotto non ancora caricato: ${_nomeProdotto(item)}',
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ProdottoDettagliView(prodotto: prodotto, showCloseButton: true),
      ),
    );
  }

  Widget _buildAnteprimaProdotto(BuildContext context, ProdottoOrdine item) {
    final imageUrl = _immagineProdotto(item);
    final hasImage = imageUrl?.isNotEmpty ?? false;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasImage ? () => _apriFotoProdotto(context, item) : null,
        borderRadius: BorderRadius.circular(8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: hasImage
              ? Image.network(
                  imageUrl!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 56,
                      height: 56,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.image_not_supported),
                    );
                  },
                )
              : Container(
                  width: 56,
                  height: 56,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.image_not_supported),
                ),
        ),
      ),
    );
  }

  Widget _buildProdottoRow(BuildContext context, ProdottoOrdine item) {
    final theme = Theme.of(context);
    final customColors = theme.extension<AppColorExtension>()!;
    final currency = widget.ordine.currency ?? 'EUR';
    final sku = (item.sku ?? '').trim();
    final quantita = item.quantity ?? 0;
    final prezzoUnitario = _formatImporto(item.price);
    final totaleRiga = _formatImporto(item.total);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnteprimaProdotto(context, item),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _nomeProdotto(item),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.qr_code_scanner, size: 20),
                      color: theme.primaryColor,
                      tooltip: 'Verifica codice a barre',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _verificaBarcodeProdotto(context, item),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Azioni prodotto',
                      icon: const Icon(Icons.more_vert, size: 20),
                      padding: EdgeInsets.zero,
                      onSelected: (value) {
                        switch (value) {
                          case 'negozio':
                            _apriProdottoInNegozio(item);
                            break;
                          case 'dettaglio':
                            _apriDettaglioProdotto(context, item);
                            break;
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'negozio',
                          child: Row(
                            children: [
                              Icon(Icons.open_in_browser, size: 20),
                              SizedBox(width: 8),
                              Text('Vedi in negozio'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'dettaglio',
                          child: Row(
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 20),
                              SizedBox(width: 8),
                              Text('Vedi prodotto'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Quantità: $quantita',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (sku.isNotEmpty)
                      Text(
                        'SKU: $sku',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withValues(
                            alpha: 0.72,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Unità: $prezzoUnitario $currency',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      'Totale: $totaleRiga $currency',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: customColors.successColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ordine #${widget.ordine.number}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Creato: ${widget.ordine.dateCreated != null ? dateFormat.format(widget.ordine.dateCreated!) : "N/D"}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: theme.primaryColor),
                onSelected: (value) => _handleMenuAction(value, context),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'cambiaStato',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Cambia stato'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'aggiungiNota',
                    child: Row(
                      children: [
                        Icon(Icons.note_add, size: 20),
                        SizedBox(width: 8),
                        Text('Aggiungi nota'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'elimina',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Elimina', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 32),
          _buildSezione(context, 'Cliente', Icons.person, [
            _buildInfoRow(
              'Nome',
              '${widget.ordine.billing?.firstName ?? ''} ${widget.ordine.billing?.lastName ?? ''}'
                  .trim(),
            ),
            _buildInfoRow('Email', widget.ordine.billing?.email ?? 'N/D'),
            _buildInfoRow('Telefono', widget.ordine.billing?.phone ?? 'N/D'),
          ]),
          const SizedBox(height: 16),
          _buildSezione(context, 'Indirizzo', Icons.location_on, [
            _buildInfoRow(
              'Indirizzo',
              widget.ordine.billing?.address1 ?? 'N/D',
            ),
            _buildInfoRow('Città', widget.ordine.billing?.city ?? 'N/D'),
            _buildInfoRow('CAP', widget.ordine.billing?.postcode ?? 'N/D'),
          ]),
          const SizedBox(height: 16),
          _buildSezione(
            context,
            'Prodotti',
            Icons.shopping_bag,
            widget.ordine.lineItems
                    ?.map((item) => _buildProdottoRow(context, item))
                    .toList() ??
                [],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildTotaleRow(
                    'Subtotale',
                    (widget.ordine.total ??
                            0 -
                                (widget.ordine.shippingTotal ?? 0) -
                                (widget.ordine.totalTax ?? 0))
                        .toString(),
                    widget.ordine.currency,
                  ),
                  _buildTotaleRow(
                    'Spedizione',
                    widget.ordine.shippingTotal?.toString() ?? '0',
                    widget.ordine.currency,
                  ),
                  _buildTotaleRow(
                    'Tasse',
                    widget.ordine.totalTax?.toString() ?? '0',
                    widget.ordine.currency,
                  ),
                  const Divider(),
                  _buildTotaleRow(
                    'Totale',
                    widget.ordine.total?.toString() ?? '0',
                    widget.ordine.currency,
                    isBold: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action, BuildContext context) {
    switch (action) {
      case 'cambiaStato':
        _mostraDialogCambiaStato(context);
        break;
      case 'aggiungiNota':
        _mostraDialogAggiungiNota(context);
        break;
      case 'elimina':
        _mostraDialogElimina(context);
        break;
    }
  }

  /// Apre lo scanner, scansiona il codice a barre e lo confronta con lo SKU
  /// del prodotto selezionato nell'ordine.
  Future<void> _verificaBarcodeProdotto(
    BuildContext context,
    ProdottoOrdine item,
  ) async {
    final String? scannedCode = await showBarcodeScanner(context);

    if (scannedCode == null || scannedCode.isEmpty || !mounted) {
      return;
    }

    final String? skuProdotto = item.sku;
    if (skuProdotto == null || skuProdotto.isEmpty) {
      NotificationService.instance.messageBar(
        'errore',
        'ordini',
        'Prodotto senza codice a barre: ${item.name}',
      );
      return;
    }

    // Normalizza entrambi i codici: maiuscolo, solo alfanumerici, senza spazi
    String normalizza(String code) =>
        code.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

    final bool corrisponde = normalizza(scannedCode) == normalizza(skuProdotto);

    NotificationService.instance.messageBar(
      corrisponde ? 'successo' : 'errore',
      'ordini',
      corrisponde
          ? 'Prodotto corretto: ${item.name}'
          : 'Prodotto differente: atteso ${item.sku}, scansionato $scannedCode',
    );
  }

  Future<void> _mostraDialogCambiaStato(BuildContext context) async {
    final controller = context
        .findAncestorStateOfType<OrdiniGestisciPageState>()!
        ._controller;
    final nuovoStato = await showDialog<OrdineStatus>(
      context: context,
      builder: (context) => _CambiaStatoDialog(
        statoCorrente: widget.ordine.status,
        controller: controller,
      ),
    );

    if (nuovoStato != null && mounted) {
      final success = await controller.aggiornaStatoOrdine(
        widget.ordine.id!,
        nuovoStato,
      );
      if (success && mounted) {
        NotificationService.instance.messageBar(
          'successo',
          'ordini_gestisci',
          'Stato ordine aggiornato con successo',
        );
        // Aggiorna la UI del parent
        context.findAncestorStateOfType<OrdiniGestisciPageState>()?.setState(
          () {},
        );
      }
    }
  }

  Future<void> _mostraDialogAggiungiNota(BuildContext context) async {
    final controller = context
        .findAncestorStateOfType<OrdiniGestisciPageState>()!
        ._controller;
    final nota = await showDialog<String>(
      context: context,
      builder: (context) => const _AggiungiNotaDialog(),
    );

    if (nota != null && nota.isNotEmpty && mounted) {
      final success = await controller.aggiungiNota(widget.ordine.id!, nota);
      if (success && mounted) {
        NotificationService.instance.messageBar(
          'successo',
          'ordini_gestisci',
          'Nota aggiunta con successo',
        );
      }
    }
  }

  Future<void> _mostraDialogElimina(BuildContext context) async {
    final controller = context
        .findAncestorStateOfType<OrdiniGestisciPageState>()!
        ._controller;
    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma eliminazione'),
        content: Text(
          'Sei sicuro di voler eliminare l\'ordine #${widget.ordine.number}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (conferma == true && mounted) {
      final success = await controller.eliminaOrdine(
        widget.ordine.id!,
        force: true,
      );
      if (success && mounted) {
        NotificationService.instance.messageBar(
          'successo',
          'ordini_gestisci',
          'Ordine eliminato con successo',
        );
        // Aggiorna la UI del parent e deseleziona
        final parentState = context
            .findAncestorStateOfType<OrdiniGestisciPageState>();
        controller.deselezionaOrdine();
        parentState?.setState(() {});
      }
    }
  }

  Widget _buildSezione(
    BuildContext context,
    String titolo,
    IconData icona,
    List<Widget> contenuto,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icona, size: 20, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  titolo,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...contenuto,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildTotaleRow(
    String label,
    String value,
    String? currency, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
          Text(
            '$value ${currency ?? '€'}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog per cambiare lo stato di un ordine
class _CambiaStatoDialog extends StatefulWidget {
  final OrdineStatus? statoCorrente;
  final OrdiniGestioneController controller;

  const _CambiaStatoDialog({
    required this.statoCorrente,
    required this.controller,
  });

  @override
  State<_CambiaStatoDialog> createState() => _CambiaStatoDialogState();
}

class _CambiaStatoDialogState extends State<_CambiaStatoDialog> {
  late OrdineStatus? _statoSelezionato;

  @override
  void initState() {
    super.initState();
    _statoSelezionato = widget.statoCorrente;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cambia stato ordine'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Seleziona il nuovo stato dell\'ordine:'),
          const SizedBox(height: 16),
          DropdownButtonFormField<OrdineStatus>(
            initialValue: _statoSelezionato,
            decoration: const InputDecoration(
              labelText: 'Stato',
              border: OutlineInputBorder(),
            ),
            items: widget.controller.getStatiDisponibili().map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(widget.controller.getTestoStato(status)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _statoSelezionato = value;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: _statoSelezionato != null
              ? () => Navigator.pop(context, _statoSelezionato)
              : null,
          child: const Text('Conferma'),
        ),
      ],
    );
  }
}

/// Dialog per aggiungere una nota a un ordine
class _AggiungiNotaDialog extends StatefulWidget {
  const _AggiungiNotaDialog();

  @override
  State<_AggiungiNotaDialog> createState() => _AggiungiNotaDialogState();
}

class _AggiungiNotaDialogState extends State<_AggiungiNotaDialog> {
  final _controller = TextEditingController();
  bool _notaCliente = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Aggiungi nota'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Nota',
              hintText: 'Inserisci una nota per questo ordine...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('Nota visibile al cliente'),
            value: _notaCliente,
            onChanged: (value) {
              setState(() {
                _notaCliente = value ?? false;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Aggiungi'),
        ),
      ],
    );
  }
}
