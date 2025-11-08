import 'package:flutter/material.dart';
import 'class_scontrino.dart';
import 'cassa.code.dart';
import '../theme/theme.dart';
import '../prodotti/class_prodotti.dart';
import '../QRcode/barcode_scanner.dart';
import '../login/jwt_api/adapter/platform_manager.dart';

class CassaPage extends StatefulWidget {
  const CassaPage({super.key});

  @override
  CassaPageState createState() => CassaPageState();
}

class CassaPageState extends State<CassaPage> {
  final CassaController _controller = CassaController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _caricaProdotti();
  }

  Future<void> _caricaProdotti() async {
    await _controller.caricaProdotti();
    if (mounted) {
      setState(() {});
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
                  ? [customColors.headerGradientStart, customColors.headerGradientEnd]
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
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
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
                        icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                        onPressed: () async {
                          // Apri lo scanner
                          final String? scannedCode = await showBarcodeScanner(context);

                          if (scannedCode != null && scannedCode.isNotEmpty) {
                            // Cerca il prodotto per SKU o barcode
                            final prodotto = controller.ricercaPerSku(scannedCode);

                            if (prodotto != null) {
                              // Prodotto trovato, selezionalo
                              controller.selezionaProdotto(prodotto);
                              onStateChanged();

                              if (context.mounted) {
                                final customColors = Theme.of(context).extension<AppColorExtension>();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Prodotto trovato: ${prodotto.nome}'),
                                    backgroundColor: customColors?.successColor ?? Colors.green,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            } else {
                              // Prodotto non trovato
                              if (context.mounted) {
                                final customColors = Theme.of(context).extension<AppColorExtension>();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Prodotto non trovato: $scannedCode'),
                                    backgroundColor: customColors?.errorColorStatus ?? Colors.red,
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  controller.setFiltroRicerca(value);
                  onStateChanged();
                },
              ),
            ],
          ),
        ),

        // Lista prodotti o prodotto selezionato
        Expanded(
          child: controller.hasProdottoSelezionato
              ? _ProdottoSelezionatoWidget(
                  controller: controller,
                  onStateChanged: onStateChanged,
                )
              : _ListaProdottiWidget(
                  controller: controller,
                  onStateChanged: onStateChanged,
                ),
        ),
      ],
    );
  }
}

/// Widget che mostra la lista dei prodotti filtrati
class _ListaProdottiWidget extends StatelessWidget {
  final CassaController controller;
  final VoidCallback onStateChanged;

  const _ListaProdottiWidget({
    required this.controller,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (controller.prodotti.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Nessun prodotto trovato',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: controller.prodotti.length,
      itemBuilder: (context, index) {
        final prodotto = controller.prodotti[index];
        return _CardProdotto(
          prodotto: prodotto,
          onTap: () {
            controller.selezionaProdotto(prodotto);
            onStateChanged();
          },
        );
      },
    );
  }
}

/// Card per visualizzare un singolo prodotto nella lista
class _CardProdotto extends StatelessWidget {
  final Prodotto_global prodotto;
  final VoidCallback onTap;

  const _CardProdotto({
    required this.prodotto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: ClipRRect(
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
        title: Text(
          prodotto.nome ?? '',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SKU: ${prodotto.sku ?? ''}'),
            Builder(
              builder: (context) {
                final customColors = theme.extension<AppColorExtension>();
                return Text(
                  '€${prodotto.prezzoEffettivo.toStringAsFixed(2)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: customColors?.successColor ?? Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }
            ),
          ],
        ),
        trailing: Icon(
          prodotto.hasVarianti ? Icons.arrow_forward_ios : Icons.add_shopping_cart,
          color: theme.primaryColor,
        ),
        onTap: onTap,
      ),
    );
  }
}

/// Widget che mostra il prodotto selezionato con opzioni di varianti e quantità
class _ProdottoSelezionatoWidget extends StatelessWidget {
  final CassaController controller;
  final VoidCallback onStateChanged;

  const _ProdottoSelezionatoWidget({
    required this.controller,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final prodotto = controller.prodottoSelezionato!;
    final theme = Theme.of(context);
    final customColors = theme.extension<AppColorExtension>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bottone indietro
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.arrow_back),
              label: const Text('Torna alla ricerca'),
              onPressed: () {
                controller.selezionaProdotto(controller.prodottoSelezionato!);
                controller.selezionaVariante(null);
                onStateChanged();
              },
            ),
          ),

          const SizedBox(height: 16),

          // Immagine prodotto
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: (prodotto.immagineUrl?.isNotEmpty ?? false)
                  ? Image.network(
                      prodotto.immagineUrl!,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.image_not_supported, size: 64),
                        );
                      },
                    )
                  : Container(
                      height: 200,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.shopping_bag, size: 64),
                    ),
            ),
          ),

          const SizedBox(height: 24),

          // Nome e prezzo
          Text(
            prodotto.nome ?? '',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            'SKU: ${prodotto.sku ?? ''}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            decoration: BoxDecoration(
              color: customColors?.priceBackground ?? (customColors?.successColor ?? Colors.green).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '€${prodotto.prezzoEffettivo.toStringAsFixed(2)}',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: customColors?.successColor ?? Colors.green,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 24),

          // Selezione varianti (se presenti)
          if (prodotto.hasVarianti) ...[
            Text(
              'Seleziona Variante',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            ...(prodotto.varianti?.map((variante) {
              final isSelected = controller.hasVarianteSelezionata &&
                  controller.varianteSelezionata!.id == variante.id;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: isSelected
                    ? customColors?.variantSelectedBackground ??
                        theme.primaryColor.withValues(alpha: 0.1)
                    : null,
                child: ListTile(
                  title: Text(variante.nomeVisualizzabile),
                  subtitle: Text(
                    '€${variante.prezzoEffettivo.toStringAsFixed(2)} - Stock: ${variante.quantita}',
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: theme.primaryColor)
                      : const Icon(Icons.circle_outlined),
                  enabled: variante.isDisponibile,
                  onTap: () {
                    controller.selezionaVariante(variante);
                    onStateChanged();
                  },
                ),
              );
            }) ?? []),

            const SizedBox(height: 24),
          ],

          // Selettore quantità
          Text(
            'Quantità',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filled(
                onPressed: () {
                  controller.decrementaQuantita();
                  onStateChanged();
                },
                icon: const Icon(Icons.remove),
                style: IconButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),

              const SizedBox(width: 24),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.primaryColor, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${controller.quantitaDaAggiungere}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 24),

              IconButton.filled(
                onPressed: () {
                  controller.incrementaQuantita();
                  onStateChanged();
                },
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Bottone Aggiungi al carrello
          ElevatedButton.icon(
            onPressed: (prodotto.hasVarianti && !controller.hasVarianteSelezionata)
                ? null
                : () {
                    if (controller.aggiungiAlCarrello()) {
                      final customColors = theme.extension<AppColorExtension>();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Prodotto aggiunto al carrello'),
                          duration: const Duration(seconds: 1),
                          backgroundColor: customColors?.successColor ?? Colors.green,
                        ),
                      );
                      onStateChanged();
                    }
                  },
            icon: const Icon(Icons.add_shopping_cart, size: 28),
            label: const Text(
              'AGGIUNGI AL CARRELLO',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: customColors?.successColor ?? Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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
                  ? [customColors.headerGradientStart, customColors.headerGradientEnd]
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    await _dialogSelezionaCliente(context, controller, onStateChanged);
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
                Icon(Icons.card_membership, color: theme.primaryColor, size: 20),
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
                    await _dialogCartaFedelta(context, controller, onStateChanged);
                  },
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scansiona'),
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

              // Sconto (se presente)
              if (scontrino.sconto > 0)
                _RigaTotale(
                  label: 'Sconto:',
                  valore: '-€${scontrino.sconto.toStringAsFixed(2)}',
                  colore: customColors?.errorColorStatus ?? Colors.red,
                ),

              // IVA
              if (scontrino.iva > 0)
                _RigaTotale(
                  label: 'IVA:',
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
                              _confermaVuotaCarrello(context, controller, onStateChanged);
                            },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Svuota'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: customColors?.errorColorStatus ?? Colors.red,
                        side: BorderSide(color: customColors?.errorColorStatus ?? Colors.red),
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
                              _confermaPagamento(context, controller, onStateChanged);
                            },
                      icon: const Icon(Icons.payment, size: 24),
                      label: const Text(
                        'PAGA',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: customColors?.successColor ?? Colors.green,
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

  void _confermaVuotaCarrello(BuildContext context, CassaController controller, VoidCallback onStateChanged) {
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
              backgroundColor: Theme.of(context).extension<AppColorExtension>()?.errorColorStatus ?? Colors.red,
            ),
            child: const Text('Svuota'),
          ),
        ],
      ),
    );
  }

  Future<void> _dialogSelezionaCliente(BuildContext context, CassaController controller, VoidCallback onStateChanged) async {
    final nomeController = TextEditingController(text: controller.clienteNome ?? '');
    final emailController = TextEditingController(text: controller.clienteEmail ?? '');
    final telefonoController = TextEditingController(text: controller.clienteTelefono ?? '');

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
                foregroundColor: Theme.of(context).extension<AppColorExtension>()?.errorColorStatus ?? Colors.red,
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              final nome = nomeController.text.trim();
              if (nome.isNotEmpty) {
                controller.setCliente(
                  nome: nome,
                  email: emailController.text.trim().isNotEmpty ? emailController.text.trim() : null,
                  telefono: telefonoController.text.trim().isNotEmpty ? telefonoController.text.trim() : null,
                );
                Navigator.pop(context);
                onStateChanged();
              } else {
                final customColors = Theme.of(context).extension<AppColorExtension>();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Il nome è obbligatorio'),
                    backgroundColor: customColors?.errorColorStatus ?? Colors.red,
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

  void _confermaPagamento(BuildContext context, CassaController controller, VoidCallback onStateChanged) {
    String metodoPagamento = controller.scontrinoCorrente.metodoPagamento;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Conferma Pagamento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Builder(
                builder: (context) {
                  final customColors = Theme.of(context).extension<AppColorExtension>();
                  return Text(
                    'Totale: €${controller.scontrinoCorrente.totale.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: customColors?.successColor ?? Colors.green,
                    ),
                  );
                }
              ),
              const SizedBox(height: 24),
              const Text(
                'Metodo di pagamento:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final customColors = Theme.of(context).extension<AppColorExtension>();
                  return RadioListTile<String>(
                    title: Row(
                      children: [
                        Icon(Icons.attach_money, color: customColors?.successColor ?? Colors.green),
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
                  );
                }
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Imposta il metodo di pagamento selezionato
                controller.scontrinoCorrente.metodoPagamento = metodoPagamento;

                final success = await controller.completaVendita();
                if (context.mounted) {
                  Navigator.pop(context);
                  if (success) {
                    final customColors = Theme.of(context).extension<AppColorExtension>();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Vendita completata con successo!'),
                        backgroundColor: customColors?.successColor ?? Colors.green,
                      ),
                    );
                    onStateChanged();
                  } else {
                    final customColors = Theme.of(context).extension<AppColorExtension>();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Errore durante il completamento della vendita'),
                        backgroundColor: customColors?.errorColorStatus ?? Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).extension<AppColorExtension>()?.successColor ?? Colors.green,
              ),
              child: const Text('Conferma'),
            ),
          ],
        ),
      ),
    );
  }

  /// Dialog per carta fedeltà
  Future<void> _dialogCartaFedelta(BuildContext context, CassaController controller, VoidCallback onStateChanged) async {
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
                final carta = await PlatformManager.cartaFedelta.findCustomerByCardNumber(numeroCarta);

                if (carta != null && context.mounted) {
                  // Carta trovata - associa il cliente
                  controller.setCliente(
                    nome: '${carta['first_name']} ${carta['last_name']}',
                    email: carta['email'],
                  );
                  onStateChanged();

                  final customColors = Theme.of(context).extension<AppColorExtension>();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Carta trovata! Cliente: ${carta['first_name']} ${carta['last_name']} - ${carta['points']} punti'),
                      backgroundColor: customColors?.successColor ?? Colors.green,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                } else if (context.mounted) {
                  final customColors = Theme.of(context).extension<AppColorExtension>();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Carta non trovata: $numeroCarta'),
                      backgroundColor: customColors?.errorColorStatus ?? Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  final customColors = Theme.of(context).extension<AppColorExtension>();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Errore: $e'),
                      backgroundColor: customColors?.errorColorStatus ?? Colors.red,
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            // Immagine
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: riga.immagineUrl != null && riga.immagineUrl!.isNotEmpty
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
                          child: const Icon(Icons.image_not_supported, size: 24),
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
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '${riga.quantita}',
                                style: theme.textTheme.bodyMedium?.copyWith(
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
                    final customColors = theme.extension<AppColorExtension>();
                    return Text(
                      '€${riga.subtotale.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: customColors?.successColor ?? Colors.green,
                      ),
                    );
                  }
                ),
                const SizedBox(height: 4),
                Builder(
                  builder: (context) {
                    final customColors = theme.extension<AppColorExtension>();
                    return InkWell(
                      onTap: () {
                        controller.rimuoviRiga(index);
                        onStateChanged();
                      },
                      child: Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: customColors?.errorColorStatus ?? Colors.red,
                      ),
                    );
                  }
                ),
              ],
            ),
          ],
        ),
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
