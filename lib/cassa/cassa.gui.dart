import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'class_scontrino.dart';
import 'cassa.code.dart';
import '../prodotti/class_prodotti.dart';
import '../notification/notification_service.dart';
import '../theme/theme.dart';
import '../reuse_class/gui/barcode_scanner.dart';
import '../login/jwt_api/adapter/platform_manager.dart';

class CassaPage extends StatefulWidget {
  const CassaPage({super.key});

  @override
  CassaPageState createState() => CassaPageState();
}

class CassaPageState extends State<CassaPage>
    with AutomaticKeepAliveClientMixin {
  final CassaController _controller = CassaController();
  final TextEditingController _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _caricaProdotti();
  }

  Future<void> _caricaProdotti() async {
    try {
      await _controller.caricaProdotti();
      if (mounted) {
        setState(() {});

        // Mostra warning se nessun prodotto trovato
        if (_controller.elementi.isEmpty) {
          NotificationService.instance.messageBar(
            'warning',
            'cassa',
            'Nessun prodotto trovato! Verifica i prodotti su WooCommerce.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        NotificationService.instance.messageBar(
          'errore',
          'cassa',
          'Errore caricamento prodotti: $e',
        );
      }
    }
  }

  void _updateState() {
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Necessario per AutomaticKeepAliveClientMixin
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
    );
  }

  /// Layout per desktop (split view)
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // LATO SINISTRO - Ricerca Prodotti (60%)
        Expanded(
          flex: 6,
          child: _LatoSinistroWidget(
            controller: _controller,
            searchController: _searchController,
            onStateChanged: _updateState,
          ),
        ),

        // Divider verticale
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: Theme.of(context).dividerColor,
        ),

        // LATO DESTRO - Scontrino (40%)
        Expanded(
          flex: 4,
          child: _LatoDestroWidget(
            controller: _controller,
            onStateChanged: _updateState,
          ),
        ),
      ],
    );
  }

  /// Layout per mobile (stacked view)
  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Ricerca prodotti
        Expanded(
          flex: 2,
          child: _LatoSinistroWidget(
            controller: _controller,
            searchController: _searchController,
            onStateChanged: _updateState,
          ),
        ),

        Divider(height: 1, color: Theme.of(context).dividerColor),

        // Scontrino (collapsible)
        Expanded(
          flex: 1,
          child: _LatoDestroWidget(
            controller: _controller,
            onStateChanged: _updateState,
          ),
        ),
      ],
    );
  }
}

/// Widget lato sinistro - Ricerca e selezione prodotti
class _LatoSinistroWidget extends StatelessWidget {
  final CassaController controller;
  final TextEditingController searchController;
  final VoidCallback onStateChanged;

  const _LatoSinistroWidget({
    required this.controller,
    required this.searchController,
    required this.onStateChanged,
  });

  Future<TipoRigaCassa?> _scegliTipoCambio(BuildContext context) {
    return showModalBottomSheet<TipoRigaCassa>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_shopping_cart),
              title: const Text('Cliente prende questo prodotto'),
              subtitle: const Text('Voce di vendita / uscita merce'),
              onTap: () =>
                  Navigator.of(sheetContext).pop(TipoRigaCassa.vendita),
            ),
            ListTile(
              leading: const Icon(Icons.assignment_return),
              title: const Text('Cliente restituisce questo prodotto'),
              subtitle: const Text('Voce di reso / rientro merce'),
              onTap: () => Navigator.of(sheetContext).pop(TipoRigaCassa.reso),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _aggiungiElementoContestuale(
    BuildContext context,
    ElementoCassa elemento,
  ) async {
    TipoRigaCassa tipoMovimento;
    if (controller.isOperazioneCambio) {
      final scelta = await _scegliTipoCambio(context);
      if (scelta == null) return;
      tipoMovimento = scelta;
    } else {
      tipoMovimento = controller.isOperazioneReso
          ? TipoRigaCassa.reso
          : TipoRigaCassa.vendita;
    }

    final errore = controller.aggiungiElementoConControlloStock(
      elemento,
      tipoMovimento: tipoMovimento,
    );
    if (errore == null) {
      onStateChanged();
      NotificationService.instance.messageBar(
        'successo',
        'cassa',
        tipoMovimento == TipoRigaCassa.reso
            ? '${elemento.nome} aggiunto come reso'
            : '${elemento.nome} aggiunto al carrello',
      );
    } else {
      NotificationService.instance.messageBar('errore', 'cassa', errore);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<AppColorExtension>();

    return Column(
      children: [
        // Header con ricerca
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: customColors != null
                  ? [
                      customColors.headerGradientStart,
                      customColors.headerGradientEnd,
                    ]
                  : [AppTheme.primaryColor, AppTheme.primaryColorDark],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ricerca Prodotti',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Campo di ricerca
              TextField(
                controller: searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Cerca per nome, SKU, barcode...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (controller.hasFiltroAttivo)
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white),
                          onPressed: () {
                            searchController.clear();
                            controller.cancellaFiltro();
                            onStateChanged();
                          },
                        ),
                      IconButton(
                        icon: const Icon(
                          Icons.qr_code_scanner,
                          color: Colors.white,
                        ),
                        onPressed: () async {
                          // Apri lo scanner
                          final String? scannedCode = await showBarcodeScanner(
                            context,
                          );

                          if (scannedCode != null && scannedCode.isNotEmpty) {
                            // Cerca l'elemento per SKU o barcode
                            final elemento = controller.ricercaPerSku(
                              scannedCode,
                            );

                            if (elemento != null) {
                              if (context.mounted) {
                                await _aggiungiElementoContestuale(
                                  context,
                                  elemento,
                                );
                              }
                            } else {
                              // Elemento non trovato
                              if (context.mounted) {
                                NotificationService.instance.messageBar(
                                  'errore',
                                  'cassa',
                                  'Prodotto non trovato: $scannedCode',
                                );
                              }
                            }
                          }
                        },
                      ),
                    ],
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  controller.setFiltroRicerca(value);
                  onStateChanged();
                },
              ),
            ],
          ),
        ),

        // Lista elementi (prodotti e varianti)
        Expanded(
          child: _ListaElementiWidget(
            controller: controller,
            onStateChanged: onStateChanged,
          ),
        ),
      ],
    );
  }
}

/// Widget che mostra la lista degli elementi (prodotti e varianti) filtrati
class _ListaElementiWidget extends StatelessWidget {
  final CassaController controller;
  final VoidCallback onStateChanged;

  const _ListaElementiWidget({
    required this.controller,
    required this.onStateChanged,
  });

  Future<void> _aggiungiElementoContestuale(
    ElementoCassa elemento,
    TipoRigaCassa tipoMovimento,
  ) async {
    final errore = controller.aggiungiElementoConControlloStock(
      elemento,
      tipoMovimento: tipoMovimento,
    );
    if (errore == null) {
      onStateChanged();
      NotificationService.instance.messageBar(
        'successo',
        'cassa',
        tipoMovimento == TipoRigaCassa.reso
            ? '${elemento.nome} aggiunto come reso'
            : '${elemento.nome} aggiunto al carrello',
      );
    } else {
      NotificationService.instance.messageBar('errore', 'cassa', errore);
    }
  }

  List<_GruppoElementiCassa> _buildGruppi() {
    final gruppi = <String, _GruppoElementiCassa>{};
    for (final elemento in controller.elementi) {
      final key =
          '${elemento.prodotto.id ?? elemento.prodotto.nome ?? elemento.nome}';
      gruppi.putIfAbsent(
        key,
        () => _GruppoElementiCassa(prodotto: elemento.prodotto),
      );
      gruppi[key]!.elementi.add(elemento);
    }
    return gruppi.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.hasFiltroAttivo) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.manage_search, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Cerca un prodotto per iniziare',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'La lista appare solo dopo una ricerca per nome o SKU.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    if (controller.elementi.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Nessun prodotto trovato',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    final gruppi = _buildGruppi();

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: gruppi.length,
      itemBuilder: (context, index) {
        final gruppo = gruppi[index];
        return _CardGruppoElemento(
          gruppo: gruppo,
          onAcquista: (elemento) =>
              _aggiungiElementoContestuale(elemento, TipoRigaCassa.vendita),
          onReso: (elemento) =>
              _aggiungiElementoContestuale(elemento, TipoRigaCassa.reso),
        );
      },
    );
  }
}

class _GruppoElementiCassa {
  final ProdottoGlobal prodotto;
  final List<ElementoCassa> elementi = [];

  _GruppoElementiCassa({required this.prodotto});
}

class _CardGruppoElemento extends StatelessWidget {
  final _GruppoElementiCassa gruppo;
  final Future<void> Function(ElementoCassa elemento) onAcquista;
  final Future<void> Function(ElementoCassa elemento) onReso;

  const _CardGruppoElemento({
    required this.gruppo,
    required this.onAcquista,
    required this.onReso,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prodotto = gruppo.prodotto;
    final isVariabile =
        gruppo.elementi.length > 1 ||
        gruppo.elementi.any((elemento) => elemento.variante != null);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: (prodotto.immagineUrl?.isNotEmpty ?? false)
                      ? Image.network(
                          prodotto.immagineUrl!,
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
                          child: const Icon(Icons.shopping_bag),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prodotto.nome ?? 'Prodotto',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isVariabile
                            ? '${gruppo.elementi.length} varianti trovate'
                            : 'Prodotto semplice',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...gruppo.elementi.map(
              (elemento) => _ElementoVarianteRow(
                elemento: elemento,
                onAcquista: () => onAcquista(elemento),
                onReso: () => onReso(elemento),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ElementoVarianteRow extends StatelessWidget {
  final ElementoCassa elemento;
  final Future<void> Function() onAcquista;
  final Future<void> Function() onReso;

  const _ElementoVarianteRow({
    required this.elemento,
    required this.onAcquista,
    required this.onReso,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<AppColorExtension>();
    final label = elemento.variante != null
        ? elemento.variante!.nomeVisualizzabile
        : elemento.nome;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Text('SKU: ${elemento.sku}'),
              Text(
                '€${elemento.prezzoEffettivo.toStringAsFixed(2)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: customColors?.successColor ?? Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Stock: ${elemento.quantitaStock}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: elemento.isDisponibile
                      ? Colors.grey.shade700
                      : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReso,
                  icon: const Icon(Icons.assignment_return),
                  label: const Text('Reso'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: elemento.isDisponibile ? onAcquista : null,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Acquista'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Widget lato destro - Scontrino
class _LatoDestroWidget extends StatelessWidget {
  final CassaController controller;
  final VoidCallback onStateChanged;

  const _LatoDestroWidget({
    required this.controller,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<AppColorExtension>();
    final scontrino = controller.scontrinoCorrente;

    return Column(
      children: [
        // Header scontrino
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: customColors != null
                  ? [
                      customColors.headerGradientStart,
                      customColors.headerGradientEnd,
                    ]
                  : [AppTheme.primaryColor, AppTheme.primaryColorDark],
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.receipt_long, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SCONTRINO',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '#${scontrino.id.substring(scontrino.id.length - 6)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              // Badge numero articoli
              if (!scontrino.isVuoto)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${scontrino.numeroArticoli}',
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<TipoOperazioneCassa>(
                  segments: const [
                    ButtonSegment<TipoOperazioneCassa>(
                      value: TipoOperazioneCassa.vendita,
                      icon: Icon(Icons.point_of_sale),
                      label: Text('Vendita'),
                    ),
                    ButtonSegment<TipoOperazioneCassa>(
                      value: TipoOperazioneCassa.reso,
                      icon: Icon(Icons.assignment_return),
                      label: Text('Reso'),
                    ),
                    ButtonSegment<TipoOperazioneCassa>(
                      value: TipoOperazioneCassa.cambio,
                      icon: Icon(Icons.swap_horiz),
                      label: Text('Cambio'),
                    ),
                  ],
                  selected: {controller.tipoOperazioneCorrente},
                  onSelectionChanged: (selection) {
                    controller.setTipoOperazione(selection.first);
                    onStateChanged();
                  },
                ),
              ),
              const SizedBox(height: 12),
              _MetricheCassaCard(controller: controller),
            ],
          ),
        ),

        // Lista righe scontrino
        Expanded(
          child: scontrino.isVuoto
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Carrello vuoto',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Aggiungi prodotti per iniziare',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: scontrino.righe.length,
                  itemBuilder: (context, index) {
                    final riga = scontrino.righe[index];
                    return _RigaScontrinoWidget(
                      riga: riga,
                      index: index,
                      controller: controller,
                      onStateChanged: onStateChanged,
                    );
                  },
                ),
        ),

        // Sezione cliente (TODO: solo UI)
        if (!scontrino.isVuoto) ...[
          Divider(height: 1, color: theme.dividerColor),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.person_outline, color: theme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    controller.hasCliente
                        ? controller.clienteNome!
                        : 'Cliente non associato',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    await _dialogSelezionaCliente(
                      context,
                      controller,
                      onStateChanged,
                    );
                  },
                  icon: Icon(controller.hasCliente ? Icons.edit : Icons.add),
                  label: Text(controller.hasCliente ? 'Modifica' : 'Aggiungi'),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: theme.dividerColor),

          // Sezione Carta Fedeltà
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.card_membership,
                  color: theme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Carta Fedeltà',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    await _dialogCartaFedelta(
                      context,
                      controller,
                      onStateChanged,
                    );
                  },
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scansiona'),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: theme.dividerColor),

          // Sezione Coupon
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.local_offer, color: theme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    scontrino.couponCode != null
                        ? 'Coupon: ${scontrino.couponCode}'
                        : 'Nessun coupon',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                if (scontrino.couponCode != null)
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: customColors?.errorColorStatus ?? Colors.red,
                      size: 20,
                    ),
                    onPressed: () {
                      controller.rimuoviCoupon();
                      onStateChanged();
                    },
                  )
                else
                  TextButton.icon(
                    onPressed: () => _dialogApplicaCoupon(
                      context,
                      controller,
                      onStateChanged,
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Applica'),
                  ),
              ],
            ),
          ),

          Divider(height: 1, color: theme.dividerColor),

          // Sezione Sospendi/Riprendi
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.pause_circle_outline,
                  color: theme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    controller.hasScontriniSospesi
                        ? '${controller.numeroScontriniSospesi} sospesi'
                        : 'Nessuno sospeso',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                if (controller.hasScontriniSospesi)
                  TextButton.icon(
                    onPressed: () => _dialogScontriniSospesi(
                      context,
                      controller,
                      onStateChanged,
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Riprendi'),
                  ),
                if (!scontrino.isVuoto)
                  TextButton.icon(
                    onPressed: () {
                      controller.sospendiScontrino();
                      onStateChanged();
                      NotificationService.instance.messageBar(
                        'successo',
                        'cassa',
                        'Scontrino sospeso',
                      );
                    },
                    icon: const Icon(Icons.pause),
                    label: const Text('Sospendi'),
                  ),
              ],
            ),
          ),

          Divider(height: 1, color: theme.dividerColor),
        ],

        // Totali e azioni
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Subtotale
              _RigaTotale(
                label: 'Vendite:',
                valore: '€${scontrino.totaleVendite.toStringAsFixed(2)}',
              ),

              if (scontrino.totaleResi > 0)
                _RigaTotale(
                  label: 'Resi:',
                  valore: '-€${scontrino.totaleResi.toStringAsFixed(2)}',
                  colore: customColors?.errorColorStatus ?? Colors.red,
                ),

              _RigaTotale(
                label: 'Subtotale netto:',
                valore: '€${scontrino.subtotale.toStringAsFixed(2)}',
              ),

              // Sconto fisso (se presente)
              if (scontrino.sconto > 0)
                _RigaTotale(
                  label: 'Sconto:',
                  valore: '-€${scontrino.sconto.toStringAsFixed(2)}',
                  colore: customColors?.errorColorStatus ?? Colors.red,
                ),

              // Sconto percentuale (se presente)
              if (scontrino.scontoPercentuale > 0)
                _RigaTotale(
                  label:
                      'Sconto ${scontrino.scontoPercentuale.toStringAsFixed(0)}%:',
                  valore:
                      '-€${(scontrino.subtotale * scontrino.scontoPercentuale / 100).toStringAsFixed(2)}',
                  colore: customColors?.errorColorStatus ?? Colors.red,
                ),

              // Coupon (se presente)
              if (scontrino.couponSconto > 0)
                _RigaTotale(
                  label: 'Coupon (${scontrino.couponCode}):',
                  valore: '-€${scontrino.couponSconto.toStringAsFixed(2)}',
                  colore: customColors?.errorColorStatus ?? Colors.red,
                ),

              // IVA (scorporata)
              if (scontrino.iva > 0)
                _RigaTotale(
                  label: 'IVA (${scontrino.aliquotaIva.toStringAsFixed(0)}%):',
                  valore: '€${scontrino.iva.toStringAsFixed(2)}',
                ),

              const Divider(height: 24, thickness: 2),

              // TOTALE
              _RigaTotale(
                label: scontrino.totale < 0 ? 'RIMBORSO:' : 'TOTALE:',
                valore: '€${scontrino.totale.toStringAsFixed(2)}',
                isGrande: true,
                colore: scontrino.totale < 0
                    ? (customColors?.errorColorStatus ?? Colors.red)
                    : (customColors?.successColor ?? Colors.green),
              ),

              const SizedBox(height: 16),

              // Bottoni azione
              Row(
                children: [
                  // Bottone Svuota
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: scontrino.isVuoto
                          ? null
                          : () {
                              _confermaVuotaCarrello(
                                context,
                                controller,
                                onStateChanged,
                              );
                            },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Svuota'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            customColors?.errorColorStatus ?? Colors.red,
                        side: BorderSide(
                          color: customColors?.errorColorStatus ?? Colors.red,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Bottone Paga
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: scontrino.isVuoto
                          ? null
                          : () {
                              _confermaPagamento(
                                context,
                                controller,
                                onStateChanged,
                              );
                            },
                      icon: const Icon(Icons.payment, size: 24),
                      label: const Text(
                        'PAGA',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            customColors?.successColor ?? Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confermaVuotaCarrello(
    BuildContext context,
    CassaController controller,
    VoidCallback onStateChanged,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Svuota Carrello'),
        content: const Text('Sei sicuro di voler svuotare il carrello?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.svuotaCarrello();
              Navigator.pop(context);
              onStateChanged();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  Theme.of(
                    context,
                  ).extension<AppColorExtension>()?.errorColorStatus ??
                  Colors.red,
            ),
            child: const Text('Svuota'),
          ),
        ],
      ),
    );
  }

  Future<void> _dialogSelezionaCliente(
    BuildContext context,
    CassaController controller,
    VoidCallback onStateChanged,
  ) async {
    final nomeController = TextEditingController(
      text: controller.clienteNome ?? '',
    );
    final emailController = TextEditingController(
      text: controller.clienteEmail ?? '',
    );
    final telefonoController = TextEditingController(
      text: controller.clienteTelefono ?? '',
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dati Cliente'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  hintText: 'Inserisci il nome del cliente',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email (opzionale)',
                  hintText: 'cliente@example.com',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: telefonoController,
                decoration: const InputDecoration(
                  labelText: 'Telefono (opzionale)',
                  hintText: '+39 123 456 7890',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          if (controller.hasCliente)
            TextButton.icon(
              onPressed: () {
                controller.cancellaCliente();
                Navigator.pop(context);
                onStateChanged();
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Rimuovi'),
              style: TextButton.styleFrom(
                foregroundColor:
                    Theme.of(
                      context,
                    ).extension<AppColorExtension>()?.errorColorStatus ??
                    Colors.red,
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nome = nomeController.text.trim();
              if (nome.isNotEmpty) {
                final carta = await controller.setCliente(
                  nome: nome,
                  email: emailController.text.trim().isNotEmpty
                      ? emailController.text.trim()
                      : null,
                  telefono: telefonoController.text.trim().isNotEmpty
                      ? telefonoController.text.trim()
                      : null,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  onStateChanged();

                  // Mostra messaggio se carta fedeltà trovata
                  if (carta != null) {
                    NotificationService.instance.messageBar(
                      'successo',
                      'cassa',
                      'Carta fedeltà trovata! ${carta['points']} punti disponibili',
                    );
                  }
                }
              } else {
                NotificationService.instance.messageBar(
                  'errore',
                  'cassa',
                  'Il nome è obbligatorio',
                );
              }
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );

    nomeController.dispose();
    emailController.dispose();
    telefonoController.dispose();
  }

  void _confermaPagamento(
    BuildContext context,
    CassaController controller,
    VoidCallback onStateChanged,
  ) {
    String metodoPagamento = controller.scontrinoCorrente.metodoPagamento;
    final importoController = TextEditingController();
    double importoRicevuto = 0;
    double resto = 0;
    final totale = controller.scontrinoCorrente.totale;
    final absTotale = totale.abs();
    final tipoOperazione = controller.tipoOperazioneEffettivaCorrente;
    final isRimborso = totale < 0;
    final isCambio = tipoOperazione == TipoOperazioneCassa.cambio;
    final isCambioPari = isCambio && absTotale < 0.009;
    final dialogTitle = isCambioPari
        ? 'Conferma Cambio'
        : isRimborso
        ? 'Conferma Rimborso'
        : 'Conferma Pagamento';
    final actionLabel = isCambioPari
        ? 'Conferma cambio'
        : isRimborso
        ? 'Conferma rimborso'
        : 'Conferma';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final customColors = Theme.of(context).extension<AppColorExtension>();

          return AlertDialog(
            title: Text(dialogTitle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Totale
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (customColors?.successColor ?? Colors.green)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          isCambioPari
                              ? 'CAMBIO A PARI VALORE'
                              : isRimborso
                              ? 'IMPORTO DA RIMBORSARE'
                              : 'TOTALE DA PAGARE',
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '€${absTotale.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: isRimborso
                                ? (customColors?.errorColorStatus ?? Colors.red)
                                : (customColors?.successColor ?? Colors.green),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (!isCambioPari) ...[
                    const SizedBox(height: 20),
                    Text(
                      isRimborso
                          ? 'Metodo di rimborso:'
                          : 'Metodo di pagamento:',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    RadioListTile<String>(
                      title: Row(
                        children: [
                          Icon(
                            Icons.attach_money,
                            color: customColors?.successColor ?? Colors.green,
                          ),
                          const SizedBox(width: 8),
                          const Text('Contanti'),
                        ],
                      ),
                      value: 'contanti',
                      groupValue: metodoPagamento,
                      onChanged: (value) {
                        setState(() {
                          metodoPagamento = value!;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: const Row(
                        children: [
                          Icon(Icons.credit_card, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Carta di Credito'),
                        ],
                      ),
                      value: 'carta',
                      groupValue: metodoPagamento,
                      onChanged: (value) {
                        setState(() {
                          metodoPagamento = value!;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: const Row(
                        children: [
                          Icon(Icons.account_balance, color: Colors.purple),
                          SizedBox(width: 8),
                          Text('Bancomat'),
                        ],
                      ),
                      value: 'bancomat',
                      groupValue: metodoPagamento,
                      onChanged: (value) {
                        setState(() {
                          metodoPagamento = value!;
                        });
                      },
                    ),
                  ],

                  // Calcolo resto per contanti
                  if (!isRimborso &&
                      !isCambioPari &&
                      metodoPagamento == 'contanti') ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    TextField(
                      controller: importoController,
                      decoration: const InputDecoration(
                        labelText: 'Importo Ricevuto',
                        hintText: 'Es: 50.00',
                        prefixIcon: Icon(Icons.euro),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (value) {
                        setState(() {
                          importoRicevuto = double.tryParse(value) ?? 0;
                          resto = importoRicevuto > totale
                              ? importoRicevuto - totale
                              : 0;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    // Pulsanti rapidi per importi comuni
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // Pulsante importo esatto
                        ActionChip(
                          label: Text('€${totale.toStringAsFixed(2)}'),
                          avatar: const Icon(Icons.check, size: 16),
                          backgroundColor: Colors.green.withValues(alpha: 0.2),
                          onPressed: () {
                            setState(() {
                              importoRicevuto = totale;
                              importoController.text = totale.toStringAsFixed(
                                2,
                              );
                              resto = 0;
                            });
                          },
                        ),
                        // Tagli comuni
                        for (final taglio in [5.0, 10.0, 20.0, 50.0, 100.0])
                          if (taglio >= totale)
                            ActionChip(
                              label: Text('€${taglio.toStringAsFixed(0)}'),
                              onPressed: () {
                                setState(() {
                                  importoRicevuto = taglio;
                                  importoController.text = taglio
                                      .toStringAsFixed(2);
                                  resto = taglio - totale;
                                });
                              },
                            ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (importoRicevuto > 0)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: resto > 0
                              ? Colors.blue.withValues(alpha: 0.1)
                              : (customColors?.errorColorStatus ?? Colors.red)
                                    .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              resto > 0
                                  ? 'RESTO DA DARE'
                                  : 'IMPORTO INSUFFICIENTE',
                              style: TextStyle(
                                fontSize: 11,
                                color: resto > 0
                                    ? Colors.blue
                                    : (customColors?.errorColorStatus ??
                                          Colors.red),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              resto > 0
                                  ? '€${resto.toStringAsFixed(2)}'
                                  : 'Mancano €${(totale - importoRicevuto).toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: resto > 0
                                    ? Colors.blue
                                    : (customColors?.errorColorStatus ??
                                          Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annulla'),
              ),
              ElevatedButton(
                onPressed:
                    (!isRimborso &&
                        !isCambioPari &&
                        metodoPagamento == 'contanti' &&
                        importoRicevuto > 0 &&
                        importoRicevuto < totale)
                    ? null
                    : () async {
                        // Imposta il metodo di pagamento e l'importo ricevuto
                        controller.setMetodoPagamento(metodoPagamento);
                        if (!isRimborso &&
                            !isCambioPari &&
                            metodoPagamento == 'contanti') {
                          controller.setImportoRicevuto(
                            importoRicevuto > 0 ? importoRicevuto : totale,
                          );
                        }

                        final success = await controller.completaOperazione();
                        if (context.mounted) {
                          Navigator.pop(context);
                          if (success) {
                            String message = isCambioPari
                                ? 'Cambio registrato con successo!'
                                : isCambio
                                ? isRimborso
                                      ? 'Cambio registrato. Credito cliente: €${absTotale.toStringAsFixed(2)}'
                                      : 'Cambio registrato. Conguaglio da incassare: €${absTotale.toStringAsFixed(2)}'
                                : isRimborso
                                ? 'Reso registrato. Rimborso: €${absTotale.toStringAsFixed(2)}'
                                : 'Vendita completata con successo!';
                            if (!isRimborso &&
                                !isCambioPari &&
                                metodoPagamento == 'contanti' &&
                                resto > 0) {
                              message =
                                  'Vendita completata! Resto: €${resto.toStringAsFixed(2)}';
                            }
                            NotificationService.instance.messageBar(
                              'successo',
                              'cassa',
                              message,
                            );
                            onStateChanged();
                          } else {
                            NotificationService.instance.messageBar(
                              'errore',
                              'cassa',
                              'Errore durante il completamento della vendita',
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRimborso
                      ? (customColors?.errorColorStatus ?? Colors.red)
                      : (customColors?.successColor ?? Colors.green),
                ),
                child: Text(actionLabel),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Dialog per carta fedeltà
  Future<void> _dialogCartaFedelta(
    BuildContext context,
    CassaController controller,
    VoidCallback onStateChanged,
  ) async {
    final numeroCartaController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Carta Fedeltà'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: numeroCartaController,
              decoration: InputDecoration(
                labelText: 'Numero Carta',
                hintText: 'Inserisci o scansiona',
                prefixIcon: const Icon(Icons.card_membership),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: () async {
                    final scanned = await showBarcodeScanner(context);
                    if (scanned != null) {
                      numeroCartaController.text = scanned;
                    }
                  },
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              final numeroCarta = numeroCartaController.text.trim();
              if (numeroCarta.isEmpty) return;

              Navigator.pop(context);

              // Cerca la carta fedeltà
              try {
                final carta = await PlatformManager.cartaFedelta
                    .findCustomerByCardNumber(numeroCarta);

                if (carta != null && context.mounted) {
                  // Carta trovata - associa il cliente (già abbiamo i dati della carta, non serve await)
                  await controller.setCliente(
                    nome: '${carta['first_name']} ${carta['last_name']}',
                    email: carta['email'],
                  );
                  onStateChanged();

                  if (context.mounted) {
                    NotificationService.instance.messageBar(
                      'successo',
                      'cassa',
                      'Carta trovata! Cliente: ${carta['first_name']} ${carta['last_name']} - ${carta['points']} punti',
                    );
                  }
                } else if (context.mounted) {
                  NotificationService.instance.messageBar(
                    'errore',
                    'cassa',
                    'Carta non trovata: $numeroCarta',
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  NotificationService.instance.messageBar(
                    'errore',
                    'cassa',
                    'Errore: $e',
                  );
                }
              }
            },
            child: const Text('Cerca'),
          ),
        ],
      ),
    );

    numeroCartaController.dispose();
  }

  /// Dialog per applicare un coupon
  Future<void> _dialogApplicaCoupon(
    BuildContext context,
    CassaController controller,
    VoidCallback onStateChanged,
  ) async {
    final couponController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Applica Coupon'),
        content: TextField(
          controller: couponController,
          decoration: const InputDecoration(
            labelText: 'Codice Coupon',
            hintText: 'Inserisci il codice',
            prefixIcon: Icon(Icons.local_offer),
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              final codice = couponController.text.trim();
              if (codice.isEmpty) return;

              Navigator.pop(context);

              final success = await controller.applicaCoupon(codice);
              if (context.mounted) {
                if (success) {
                  onStateChanged();
                  NotificationService.instance.messageBar(
                    'successo',
                    'cassa',
                    'Coupon "$codice" applicato!',
                  );
                } else {
                  NotificationService.instance.messageBar(
                    'errore',
                    'cassa',
                    'Coupon "$codice" non valido',
                  );
                }
              }
            },
            child: const Text('Applica'),
          ),
        ],
      ),
    );

    couponController.dispose();
  }

  /// Dialog per mostrare e riprendere scontrini sospesi
  void _dialogScontriniSospesi(
    BuildContext context,
    CassaController controller,
    VoidCallback onStateChanged,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scontrini Sospesi'),
        content: SizedBox(
          width: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: controller.scontriniSospesi.length,
            itemBuilder: (context, index) {
              final scontrino = controller.scontriniSospesi[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.receipt),
                  title: Text('€${scontrino.totale.toStringAsFixed(2)}'),
                  subtitle: Text('${scontrino.numeroArticoli} articoli'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.play_arrow, color: Colors.green),
                        onPressed: () {
                          controller.riprendiScontrino(index);
                          Navigator.pop(context);
                          onStateChanged();
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete,
                          color:
                              Theme.of(context)
                                  .extension<AppColorExtension>()
                                  ?.errorColorStatus ??
                              Colors.red,
                        ),
                        onPressed: () {
                          controller.eliminaScontrinoSospeso(index);
                          Navigator.pop(context);
                          if (controller.hasScontriniSospesi) {
                            _dialogScontriniSospesi(
                              context,
                              controller,
                              onStateChanged,
                            );
                          }
                          onStateChanged();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }
}

/// Widget per una singola riga dello scontrino
class _RigaScontrinoWidget extends StatefulWidget {
  final RigaScontrino riga;
  final int index;
  final CassaController controller;
  final VoidCallback onStateChanged;

  const _RigaScontrinoWidget({
    required this.riga,
    required this.index,
    required this.controller,
    required this.onStateChanged,
  });

  @override
  State<_RigaScontrinoWidget> createState() => _RigaScontrinoWidgetState();
}

class _RigaScontrinoWidgetState extends State<_RigaScontrinoWidget> {
  late final TextEditingController _quantitaController;
  late final FocusNode _quantitaFocusNode;
  late int _lastValidQuantita;
  bool _isInternalUpdate = false;

  RigaScontrino get riga => widget.riga;
  int get index => widget.index;
  CassaController get controller => widget.controller;
  VoidCallback get onStateChanged => widget.onStateChanged;

  @override
  void initState() {
    super.initState();
    _lastValidQuantita = riga.quantita;
    _quantitaController = TextEditingController(text: '$_lastValidQuantita');
    _quantitaFocusNode = FocusNode();
    _quantitaFocusNode.addListener(() {
      if (!_quantitaFocusNode.hasFocus) {
        _ripristinaSeVuoto();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _RigaScontrinoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_quantitaFocusNode.hasFocus && riga.quantita != _lastValidQuantita) {
      _lastValidQuantita = riga.quantita;
      _setControllerText('$_lastValidQuantita');
    }
  }

  @override
  void dispose() {
    _quantitaController.dispose();
    _quantitaFocusNode.dispose();
    super.dispose();
  }

  void _setControllerText(String value) {
    _isInternalUpdate = true;
    _quantitaController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    _isInternalUpdate = false;
  }

  void _ripristinaValorePrecedente({String? messaggioErrore}) {
    _setControllerText('$_lastValidQuantita');
    if (messaggioErrore != null && mounted) {
      NotificationService.instance.messageBar(
        'errore',
        'cassa',
        messaggioErrore,
      );
    }
  }

  void _ripristinaSeVuoto() {
    if (_quantitaController.text.trim().isEmpty) {
      _ripristinaValorePrecedente();
    }
  }

  void _applicaQuantitaManuale(String rawValue) {
    if (_isInternalUpdate) return;
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final nuovaQuantita = int.tryParse(trimmed);
    if (nuovaQuantita == null) {
      _ripristinaValorePrecedente(
        messaggioErrore: 'Inserisci solo numeri interi.',
      );
      return;
    }
    if (nuovaQuantita <= 0) {
      _ripristinaValorePrecedente(
        messaggioErrore: 'La quantità deve essere maggiore di zero.',
      );
      return;
    }

    final errore = controller.aggiornaQuantitaRiga(index, nuovaQuantita);
    if (errore == null) {
      _lastValidQuantita = nuovaQuantita;
      onStateChanged();
    } else {
      _ripristinaValorePrecedente(messaggioErrore: errore);
      onStateChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<AppColorExtension>();

    return GestureDetector(
      onLongPress: () => _showScontoRigaDialog(context),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child:
                        riga.immagineUrl != null && riga.immagineUrl!.isNotEmpty
                        ? Image.network(
                            riga.immagineUrl!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 48,
                                height: 48,
                                color: Colors.grey.shade300,
                                child: const Icon(
                                  Icons.image_not_supported,
                                  size: 24,
                                ),
                              );
                            },
                          )
                        : Container(
                            width: 48,
                            height: 48,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.shopping_bag, size: 24),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          riga.nomeCompleto,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (riga.isReso) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (customColors?.errorColorStatus ?? Colors.red)
                                      .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'RESO',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color:
                                    customColors?.errorColorStatus ??
                                    Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      controller.decrementaQuantitaRiga(index);
                                      onStateChanged();
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.remove,
                                        size: 16,
                                        color: theme.primaryColor,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 52,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: TextFormField(
                                      controller: _quantitaController,
                                      focusNode: _quantitaFocusNode,
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 8,
                                        ),
                                        border: InputBorder.none,
                                      ),
                                      onChanged: _applicaQuantitaManuale,
                                      onFieldSubmitted: _applicaQuantitaManuale,
                                      onTapOutside: (_) {
                                        _ripristinaSeVuoto();
                                        _quantitaFocusNode.unfocus();
                                      },
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      final errore = controller
                                          .incrementaQuantitaRiga(index);
                                      if (errore == null) {
                                        onStateChanged();
                                      } else {
                                        NotificationService.instance.messageBar(
                                          'errore',
                                          'cassa',
                                          errore,
                                        );
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.add,
                                        size: 16,
                                        color: theme.primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '× €${riga.prezzoUnitario.toStringAsFixed(2)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Builder(
                        builder: (context) {
                          final customColors = theme
                              .extension<AppColorExtension>();
                          return Text(
                            '${riga.isReso ? '-' : ''}€${riga.subtotale.toStringAsFixed(2)}',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: riga.isReso
                                  ? (customColors?.errorColorStatus ??
                                        Colors.red)
                                  : (customColors?.successColor ??
                                        Colors.green),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      Builder(
                        builder: (context) {
                          final customColors = theme
                              .extension<AppColorExtension>();
                          return InkWell(
                            onTap: () {
                              controller.rimuoviRiga(index);
                              onStateChanged();
                            },
                            child: Icon(
                              Icons.delete_outline,
                              size: 20,
                              color:
                                  customColors?.errorColorStatus ?? Colors.red,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              if (riga.totaleSconto > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.discount,
                        size: 14,
                        color: customColors?.errorColorStatus ?? Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Sconto: -€${riga.totaleSconto.toStringAsFixed(2)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: customColors?.errorColorStatus ?? Colors.red,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showScontoRigaDialog(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<AppColorExtension>();
    final percentualeController = TextEditingController(
      text: riga.scontoPercentuale > 0 ? riga.scontoPercentuale.toString() : '',
    );
    final fissoController = TextEditingController(
      text: riga.scontoRiga > 0 ? riga.scontoRiga.toString() : '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sconto sulla Riga'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              riga.nomeCompleto,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: percentualeController,
              decoration: const InputDecoration(
                labelText: 'Sconto %',
                hintText: 'Es: 10',
                prefixIcon: Icon(Icons.percent),
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: fissoController,
              decoration: const InputDecoration(
                labelText: 'Sconto Fisso €',
                hintText: 'Es: 5.00',
                prefixIcon: Icon(Icons.euro),
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],
        ),
        actions: [
          if (riga.totaleSconto > 0)
            TextButton.icon(
              onPressed: () {
                controller.rimuoviScontiRiga(index);
                Navigator.pop(context);
                onStateChanged();
              },
              icon: const Icon(Icons.clear),
              label: const Text('Rimuovi Sconti'),
              style: TextButton.styleFrom(
                foregroundColor: customColors?.errorColorStatus ?? Colors.red,
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              final percentuale =
                  double.tryParse(percentualeController.text) ?? 0;
              final fisso = double.tryParse(fissoController.text) ?? 0;

              if (percentuale > 0) {
                controller.applicaScontoRigaPercentuale(index, percentuale);
              }
              if (fisso > 0) {
                controller.applicaScontoRigaFisso(index, fisso);
              }

              Navigator.pop(context);
              onStateChanged();
            },
            child: const Text('Applica'),
          ),
        ],
      ),
    );
  }
}

class _MetricheCassaCard extends StatelessWidget {
  final CassaController controller;

  const _MetricheCassaCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final metriche = controller.metricheSnapshot;
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _MetricChip(
            label: 'Vendite',
            value: metriche.numeroVendite.toString(),
            icon: Icons.point_of_sale,
          ),
          _MetricChip(
            label: 'Resi',
            value: metriche.numeroResi.toString(),
            icon: Icons.assignment_return,
          ),
          _MetricChip(
            label: 'Cambi',
            value: metriche.numeroCambi.toString(),
            icon: Icons.swap_horiz,
          ),
          _MetricChip(
            label: 'Valore vendite',
            value: '€${metriche.valoreVendite.toStringAsFixed(2)}',
            icon: Icons.trending_up,
          ),
          _MetricChip(
            label: 'Valore resi',
            value: '€${metriche.valoreResi.toStringAsFixed(2)}',
            icon: Icons.undo,
          ),
          _MetricChip(
            label: 'Saldo netto',
            value: '€${metriche.saldoNetto.toStringAsFixed(2)}',
            icon: Icons.analytics_outlined,
          ),
          _MetricChip(
            label: 'Conguagli incassati',
            value: '€${metriche.conguagliPositivi.toStringAsFixed(2)}',
            icon: Icons.arrow_circle_up,
          ),
          _MetricChip(
            label: 'Conguagli rimborsati',
            value: '€${metriche.conguagliNegativi.toStringAsFixed(2)}',
            icon: Icons.arrow_circle_down,
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 130),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.primaryColor),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: theme.textTheme.labelSmall),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget helper per le righe dei totali
class _RigaTotale extends StatelessWidget {
  final String label;
  final String valore;
  final bool isGrande;
  final Color? colore;

  const _RigaTotale({
    required this.label,
    required this.valore,
    this.isGrande = false,
    this.colore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isGrande
                ? theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  )
                : theme.textTheme.bodyLarge,
          ),
          Text(
            valore,
            style: isGrande
                ? theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colore ?? theme.textTheme.bodyLarge?.color,
                  )
                : theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colore ?? theme.textTheme.bodyLarge?.color,
                  ),
          ),
        ],
      ),
    );
  }
}
