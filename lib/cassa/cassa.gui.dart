import 'package:flutter/material.dart';
import 'class_scontrino.dart';
import 'cassa.code.dart';
import '../theme/theme.dart';
import '../QRcode/barcode_scanner.dart';
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
          final customColors = Theme.of(context).extension<AppColorExtension>();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Nessun prodotto trovato! Verifica i prodotti su WooCommerce.',
              ),
              backgroundColor: customColors?.warningColor ?? Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final customColors = Theme.of(context).extension<AppColorExtension>();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore caricamento prodotti: $e'),
            backgroundColor: customColors?.errorColorStatus ?? Colors.red,
            duration: const Duration(seconds: 5),
          ),
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
                              // Elemento trovato, aggiungilo direttamente al carrello
                              if (controller.aggiungiElemento(elemento)) {
                                onStateChanged();

                                if (context.mounted) {
                                  final customColors = Theme.of(
                                    context,
                                  ).extension<AppColorExtension>();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${elemento.nome} aggiunto al carrello',
                                      ),
                                      backgroundColor:
                                          customColors?.successColor ??
                                          Colors.green,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              }
                            } else {
                              // Elemento non trovato
                              if (context.mounted) {
                                final customColors = Theme.of(
                                  context,
                                ).extension<AppColorExtension>();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Prodotto non trovato: $scannedCode',
                                    ),
                                    backgroundColor:
                                        customColors?.errorColorStatus ??
                                        Colors.red,
                                    duration: const Duration(seconds: 2),
                                  ),
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

  @override
  Widget build(BuildContext context) {
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

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: controller.elementi.length,
      itemBuilder: (context, index) {
        final elemento = controller.elementi[index];
        return _CardElemento(
          elemento: elemento,
          onTap: () {
            // Aggiunge direttamente l'elemento al carrello
            if (controller.aggiungiElemento(elemento)) {
              onStateChanged();

              // Mostra messaggio di conferma
              final customColors = Theme.of(
                context,
              ).extension<AppColorExtension>();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${elemento.nome} aggiunto al carrello'),
                  backgroundColor: customColors?.successColor ?? Colors.green,
                  duration: const Duration(seconds: 1),
                ),
              );
            }
          },
        );
      },
    );
  }
}

/// Card per visualizzare un singolo elemento (prodotto o variante) nella lista
class _CardElemento extends StatelessWidget {
  final ElementoCassa elemento;
  final VoidCallback onTap;

  const _CardElemento({required this.elemento, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<AppColorExtension>();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: (elemento.immagineUrl?.isNotEmpty ?? false)
              ? Image.network(
                  elemento.immagineUrl!,
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
        title: Text(
          elemento.nome,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SKU: ${elemento.sku}'),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  '€${elemento.prezzoEffettivo.toStringAsFixed(2)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: customColors?.successColor ?? Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Stock: ${elemento.quantitaStock}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: elemento.isDisponibile
                        ? Colors.grey.shade600
                        : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(
          Icons.add_shopping_cart,
          color: elemento.isDisponibile ? theme.primaryColor : Colors.grey,
        ),
        enabled: elemento.isDisponibile,
        onTap: elemento.isDisponibile ? onTap : null,
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Scontrino sospeso'),
                          backgroundColor:
                              customColors?.successColor ?? Colors.green,
                        ),
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
                label: 'Subtotale:',
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
                label: 'TOTALE:',
                valore: '€${scontrino.totale.toStringAsFixed(2)}',
                isGrande: true,
                colore: customColors?.successColor ?? Colors.green,
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
                    final customColors = Theme.of(
                      context,
                    ).extension<AppColorExtension>();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Carta fedeltà trovata! ${carta['points']} punti disponibili',
                        ),
                        backgroundColor:
                            customColors?.successColor ?? Colors.green,
                      ),
                    );
                  }
                }
              } else {
                final customColors = Theme.of(
                  context,
                ).extension<AppColorExtension>();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Il nome è obbligatorio'),
                    backgroundColor:
                        customColors?.errorColorStatus ?? Colors.red,
                  ),
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

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final customColors = Theme.of(context).extension<AppColorExtension>();

          return AlertDialog(
            title: const Text('Conferma Pagamento'),
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
                        const Text(
                          'TOTALE DA PAGARE',
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '€${totale.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: customColors?.successColor ?? Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    'Metodo di pagamento:',
                    style: TextStyle(fontWeight: FontWeight.bold),
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
                    groupValue:
                        metodoPagamento, // ignore: deprecated_member_use
                    onChanged: (value) {
                      // ignore: deprecated_member_use
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
                    groupValue:
                        metodoPagamento, // ignore: deprecated_member_use
                    onChanged: (value) {
                      // ignore: deprecated_member_use
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
                    groupValue:
                        metodoPagamento, // ignore: deprecated_member_use
                    onChanged: (value) {
                      // ignore: deprecated_member_use
                      setState(() {
                        metodoPagamento = value!;
                      });
                    },
                  ),

                  // Calcolo resto per contanti
                  if (metodoPagamento == 'contanti') ...[
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
                    (metodoPagamento == 'contanti' &&
                        importoRicevuto > 0 &&
                        importoRicevuto < totale)
                    ? null
                    : () async {
                        // Imposta il metodo di pagamento e l'importo ricevuto
                        controller.scontrinoCorrente.metodoPagamento =
                            metodoPagamento;
                        if (metodoPagamento == 'contanti') {
                          controller.setImportoRicevuto(
                            importoRicevuto > 0 ? importoRicevuto : totale,
                          );
                        }

                        final success = await controller.completaVendita();
                        if (context.mounted) {
                          Navigator.pop(context);
                          if (success) {
                            // Mostra resto se necessario
                            String message = 'Vendita completata con successo!';
                            if (metodoPagamento == 'contanti' && resto > 0) {
                              message =
                                  'Vendita completata! Resto: €${resto.toStringAsFixed(2)}';
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(message),
                                backgroundColor:
                                    customColors?.successColor ?? Colors.green,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                            onStateChanged();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Errore durante il completamento della vendita',
                                ),
                                backgroundColor:
                                    customColors?.errorColorStatus ??
                                    Colors.red,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: customColors?.successColor ?? Colors.green,
                ),
                child: const Text('Conferma'),
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
                    final customColors = Theme.of(
                      context,
                    ).extension<AppColorExtension>();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Carta trovata! Cliente: ${carta['first_name']} ${carta['last_name']} - ${carta['points']} punti',
                        ),
                        backgroundColor:
                            customColors?.successColor ?? Colors.green,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                } else if (context.mounted) {
                  final customColors = Theme.of(
                    context,
                  ).extension<AppColorExtension>();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Carta non trovata: $numeroCarta'),
                      backgroundColor:
                          customColors?.errorColorStatus ?? Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  final customColors = Theme.of(
                    context,
                  ).extension<AppColorExtension>();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Errore: $e'),
                      backgroundColor:
                          customColors?.errorColorStatus ?? Colors.red,
                    ),
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
                final customColors = Theme.of(
                  context,
                ).extension<AppColorExtension>();
                if (success) {
                  onStateChanged();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Coupon "$codice" applicato!'),
                      backgroundColor:
                          customColors?.successColor ?? Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Coupon "$codice" non valido'),
                      backgroundColor:
                          customColors?.errorColorStatus ?? Colors.red,
                    ),
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
class _RigaScontrinoWidget extends StatelessWidget {
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
                  // Immagine
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

                  // Dettagli prodotto
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
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            // Controlli quantità
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Text(
                                      '${riga.quantita}',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      controller.incrementaQuantitaRiga(index);
                                      onStateChanged();
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

                  // Prezzo totale e bottone elimina
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Builder(
                        builder: (context) {
                          final customColors = theme
                              .extension<AppColorExtension>();
                          return Text(
                            '€${riga.subtotale.toStringAsFixed(2)}',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: customColors?.successColor ?? Colors.green,
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
              // Indicatore sconto se presente
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
