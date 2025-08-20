import 'package:flutter/material.dart';
import 'dart:math' as math; // Necessario per la rotazione del banner
import 'prodotti_gestisci.code.dart';
import '../class_prodotti.dart';
import '../../theme/theme.dart';

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

class ProdottiGestisciPage extends StatefulWidget {
  const ProdottiGestisciPage({super.key});

  @override
  ProdottiGestisciPageState createState() => ProdottiGestisciPageState();
}

class ProdottiGestisciPageState extends State<ProdottiGestisciPage> {
  final ProdottiGestioneController _controller = ProdottiGestioneController();

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
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Expanded(
          flex: 2,
          child: _ProductListWidget(
            controller: _controller,
            onStateChanged: _updateState,
          ),
        ),
        if (_controller.hasProdottoSelezionato) ...[
          Divider(height: 1, color: Theme.of(context).dividerColor),
          Expanded(
            flex: 1,
            child: _ProductDetailsWidget(
              controller: _controller,
              onStateChanged: _updateState,
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
                    )
                  : _buildEmptyState(),
              Positioned(
                bottom: 20,
                right: 20,
                child: _buildCreateButton(),
              ),
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
            color: theme.iconTheme.color?.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Seleziona un prodotto',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          Text(
            'per vedere i dettagli',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    final customColors = Theme.of(context).extension<AppColorExtension>()!;
    return FloatingActionButton(
      onPressed: () => Navigator.pushNamed(context, '/prodotti/crea'),
      tooltip: 'Crea Nuovo Prodotto',
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [customColors.fabGradientStart, customColors.fabGradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.4),
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
      onPressed: () => Navigator.pushNamed(context, '/prodotti/crea'),
      tooltip: 'Crea Nuovo Prodotto',
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [customColors.fabGradientStart, customColors.fabGradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(
            Icons.add,
            size: 28,
          ),
        ),
      ),
    );
  }
}

class _ProductListWidget extends StatelessWidget {
  final ProdottiGestioneController controller;
  final VoidCallback onStateChanged;

  const _ProductListWidget({
    required this.controller,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FiltriWidget(controller: controller, onStateChanged: onStateChanged),
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
          isSelected: controller.isProdottoSelezionato(controller.prodotti[index]),
          onTap: () {
            controller.selezionaProdotto(controller.prodotti[index]);
            onStateChanged();
          },
        ),
      ),
    );
  }
}

class _FiltriWidget extends StatefulWidget {
  final ProdottiGestioneController controller;
  final VoidCallback onStateChanged;

  const _FiltriWidget({
    required this.controller,
    required this.onStateChanged,
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

  String _getOrdinamentoText(OrdinamentoProdotti ordinamento) {
    switch (ordinamento) {
      case OrdinamentoProdotti.nomeCrescente: return 'Nome (A-Z)';
      case OrdinamentoProdotti.nomeDecrescente: return 'Nome (Z-A)';
      case OrdinamentoProdotti.prezzoCrescente: return 'Prezzo (Crescente)';
      case OrdinamentoProdotti.prezzoDecrescente: return 'Prezzo (Decrescente)';
      case OrdinamentoProdotti.nessuno: return 'Ordina per...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          TextField(
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
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            decoration: BoxDecoration(
              color: Theme.of(context).inputDecorationTheme.fillColor,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: Theme.of(context).inputDecorationTheme.enabledBorder!.borderSide.color,
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

class _ProductListItem extends StatelessWidget {
  final ProdottoWoo prodotto;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProductListItem({
    required this.prodotto,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<AppColorExtension>()!;
    final displayInfo = ProdottoDisplayInfo.fromProdotto(prodotto);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: isSelected ? 8 : 2,
      shadowColor: isSelected ? theme.primaryColor.withOpacity(0.3) : null,
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
            Expanded(child: _buildNameSection(context, info)),
            _buildPriceWidget(context),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text('ID: ${info.id}', style: textTheme.bodySmall?.copyWith(color: textTheme.bodySmall?.color?.withOpacity(0.7))),
            const SizedBox(width: 16),
            Text(info.categoria, style: textTheme.bodySmall),
            const Spacer(),
            Icon(
              prodotto.inStock ? Icons.check_circle : Icons.cancel,
              size: 14,
              color: prodotto.inStock ? customColors.stockAvailable : customColors.stockUnavailable,
            ),
            const SizedBox(width: 4),
            Text(
              ProdottoUtils.getVariantiCountShort(prodotto.varianti.length),
              style: textTheme.bodySmall?.copyWith(color: textTheme.bodySmall?.color?.withOpacity(0.7)),
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
            color: isSelected ? theme.primaryColor : theme.textTheme.titleMedium?.color,
          ),
        ),
        Text(
          'ID: ${info.id} • SKU: ${info.sku}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
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
              color: prodotto.inStock ? customColors.stockAvailable : customColors.stockUnavailable,
            ),
            const SizedBox(width: 4),
            Text(
              info.disponibilita,
              style: theme.textTheme.bodySmall?.copyWith(
                color: prodotto.inStock ? customColors.stockAvailable : customColors.stockUnavailable,
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
            PrezzoFormatter.formatPrezzo(prodotto.prezzoNormale),
            style: theme.textTheme.bodySmall?.copyWith(
              decoration: TextDecoration.lineThrough,
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
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
            PrezzoFormatter.formatPrezzo(prodotto.prezzoNormale),
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
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
          colors: [theme.primaryColor.withOpacity(0.1), theme.primaryColor.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.palette, size: 14, color: theme.primaryColor),
          const SizedBox(width: 4),
          Text(
            '${prodotto.varianti.length}',
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

class _ProductDetailsWidget extends StatelessWidget {
  final ProdottiGestioneController controller;
  final VoidCallback onStateChanged;

  const _ProductDetailsWidget({
    required this.controller,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final prodotto = controller.prodottoSelezionato!;
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProductHeader(controller: controller),
            const SizedBox(height: 20),
            _ProductInfoCard(prodotto: prodotto),
            const SizedBox(height: 20),
            _ProductVariantsCard(
              controller: controller,
              onStateChanged: onStateChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductHeader extends StatelessWidget {
  final ProdottiGestioneController controller;

  const _ProductHeader({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prodotto = controller.prodottoSelezionato!;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: theme.brightness == Brightness.dark
              ? [theme.cardColor, theme.primaryColor.withOpacity(0.05)]
              : [theme.cardColor, theme.primaryColor.withOpacity(0.02)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _ProductImage(controller: controller),
            const SizedBox(height: 20),
            Text(
              prodotto.nome,
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
                color: theme.primaryColor.withOpacity(theme.brightness == Brightness.dark ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
              ),
              child: Text(
                prodotto.descrizioneBreve,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.primaryColor.withOpacity(0.8),
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
          border: Border.all(color: theme.primaryColor.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: theme.primaryColor.withOpacity(0.2),
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
            errorBuilder: (_, __, ___) => _buildImagePlaceholder(context, icon: Icons.image_not_supported),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildImagePlaceholder(context, child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
              ));
            },
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(BuildContext context, {IconData? icon, Widget? child}) {
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
        child: child ?? Icon(
          icon,
          size: 60,
          color: theme.primaryColor.withOpacity(0.5),
        ),
      ),
    );
  }
}

class _ProductInfoCard extends StatelessWidget {
  final ProdottoWoo prodotto;

  const _ProductInfoCard({required this.prodotto});

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
            color: theme.shadowColor.withOpacity(0.1),
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
                    color: theme.primaryColor.withOpacity(theme.brightness == Brightness.dark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.info_outline, color: theme.primaryColor, size: 20),
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
            _InfoRow(label: 'Categoria', value: displayInfo.categoria),
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
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: theme.primaryColor.withOpacity(0.1)),
              ),
              child: SelectableText(value, style: theme.textTheme.bodyMedium),
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

  const _ProductVariantsCard({required this.controller, required this.onStateChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prodotto = controller.prodottoSelezionato!;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: theme.shadowColor.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVariantsHeader(context, prodotto.varianti.length),
            const SizedBox(height: 16),
            _VariantFiltersWidget(controller: controller, onStateChanged: onStateChanged),
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
            color: theme.primaryColor.withOpacity(theme.brightness == Brightness.dark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.palette, color: theme.primaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          'Varianti Disponibili',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.primaryColor),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)]),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            '$variantsCount',
            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold),
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6)),
          ),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: variantiDaMostrare.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final variante = variantiDaMostrare[index];
        return _VariantItem(
          variante: variante,
          isSelected: controller.isVarianteSelezionata(variante),
          onTap: () {
            controller.selezionaVariante(variante);
            onStateChanged();
          },
        );
      },
    );
  }
}

class _VariantFiltersWidget extends StatelessWidget {
  final ProdottiGestioneController controller;
  final VoidCallback onStateChanged;

  const _VariantFiltersWidget({required this.controller, required this.onStateChanged});

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
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filtra per:', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
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
          ...opzioniFiltro.entries.map((entry) => _buildFilterRow(context, entry.key, entry.value)),
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

  Widget _buildFilterRow(BuildContext context, String nomeAttributo, List<AttributoVariante> opzioni) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 70,
            child: Text('$nomeAttributo:', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: opzioni.map((opzione) {
                final isSelected = controller.isFiltroVarianteSelezionato(nomeAttributo, opzione.opzione);
                if (nomeAttributo.toLowerCase() == 'colore' && opzione.valore != null) {
                  return _ColorSwatchChip(
                    color: hexToColor(opzione.valore!),
                    isSelected: isSelected,
                    onTap: () {
                      controller.setFiltroVariante(nomeAttributo, opzione.opzione);
                      onStateChanged();
                    },
                  );
                }
                return _TextSwatchChip(
                  text: opzione.opzione,
                  isSelected: isSelected,
                  onTap: () {
                    controller.setFiltroVariante(nomeAttributo, opzione.opzione);
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

  const _ColorSwatchChip({required this.color, required this.isSelected, required this.onTap});

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
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
          boxShadow: isSelected
              ? [BoxShadow(color: Theme.of(context).primaryColor, spreadRadius: 2, blurRadius: 2)]
              : [],
        ),
        child: isSelected
            ? Icon(
                Icons.check,
                size: 18,
                color: ThemeData.estimateBrightnessForColor(color) == Brightness.dark ? Colors.white : Colors.black,
              )
            : null,
      ),
    );
  }
}

class _TextSwatchChip extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _TextSwatchChip({required this.text, required this.isSelected, required this.onTap});

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
          color: isSelected ? theme.primaryColor : theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? theme.primaryColor : theme.dividerColor),
        ),
        child: Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isSelected ? theme.colorScheme.onPrimary : theme.textTheme.bodyMedium?.color,
          ),
        ),
      ),
    );
  }
}

class _VariantItem extends StatelessWidget {
  final VarianteWoo variante;
  final bool isSelected;
  final VoidCallback onTap;

  const _VariantItem({
    required this.variante,
    required this.isSelected,
    required this.onTap,
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
      backgroundColor = customColors.stockUnavailable.withOpacity(theme.brightness == Brightness.dark ? 0.25 : 0.1);
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
            ? [theme.cardColor.withOpacity(0.5), theme.cardColor.withOpacity(0.3)]
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (variante.immagineUrl != null && variante.immagineUrl!.isNotEmpty) ...[
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
          color: isOutOfStock ? customColors.stockUnavailable : (isSelected ? theme.primaryColor : theme.dividerColor),
          width: isSelected || isOutOfStock ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          variante.immagineUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: theme.brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[100],
            child: Icon(Icons.image, size: 20, color: theme.iconTheme.color?.withOpacity(0.5)),
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
                  color: isOutOfStock ? customColors.stockUnavailable.withOpacity(0.8) : (isSelected ? theme.primaryColor : theme.textTheme.bodyLarge?.color),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              const SizedBox(height: 4),
              Text(
                'SKU: ${variante.sku}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7)),
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
            color: isSelected && !isOutOfStock ? theme.primaryColor : customColors.priceBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            PrezzoFormatter.formatPrezzo(variante.prezzo),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isSelected && !isOutOfStock ? theme.colorScheme.onPrimary : customColors.stockAvailable,
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
              color: isOutOfStock ? customColors.stockUnavailable : (isSelected ? theme.primaryColor : theme.iconTheme.color?.withOpacity(0.7)),
            ),
            const SizedBox(width: 4),
            Text(
              '${variante.quantita}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isOutOfStock ? customColors.stockUnavailable : (isSelected ? theme.primaryColor : theme.textTheme.bodySmall?.color?.withOpacity(0.7)),
                fontWeight: isSelected || isOutOfStock ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildColorSwatch(BuildContext context) {
    final colorAttr = variante.attributoColore;
    if (colorAttr == null || colorAttr.valore == null) return const SizedBox.shrink();
    final color = hexToColor(colorAttr.valore!);
    return Container(
      width: 28,
      height: 28,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 2, offset: const Offset(0, 1))],
      ),
      child: isSelected && variante.quantita > 0
          ? Icon(
              Icons.check,
              size: 16,
              color: ThemeData.estimateBrightnessForColor(color) == Brightness.dark ? Colors.white : Colors.black,
            )
          : null,
    );
  }

  Widget _buildSelectedIndicator(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
      child: Icon(Icons.check, size: 16, color: Theme.of(context).colorScheme.onPrimary),
    );
  }
}