import 'package:flutter/material.dart';
import 'package:gestione_negozio_abigliamento/prodotti/prodotti_gestisci/prodotti_gestisci.code.dart';
import '../class_prodotti.dart';
import 'prodotti_gestisci.code.dart';

class ProdottiGestisciPage extends StatefulWidget {
  @override
  _ProdottiGestisciPageState createState() => _ProdottiGestisciPageState();
}

class _ProdottiGestisciPageState extends State<ProdottiGestisciPage> {
  final ProdottiGestioneController _controller = ProdottiGestioneController();

  @override
  void initState() {
    super.initState();
    _caricaProdotti();
  }

  Future<void> _caricaProdotti() async {
    await _controller.caricaProdotti();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isSmallScreen = constraints.maxWidth < 800;
          return isSmallScreen ? _buildMobileLayout() : _buildDesktopLayout();
        },
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Expanded(flex: 2, child: _ProductListWidget(controller: _controller, onStateChanged: _updateState)),
        if (_controller.hasProdottoSelezionato) ...[
          Divider(height: 1, color: Theme.of(context).dividerColor),
          Expanded(
            flex: 1,
            child: _ProductDetailsWidget(controller: _controller, onStateChanged: _updateState),
          ),
        ],
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(flex: 3, child: _ProductListWidget(controller: _controller, onStateChanged: _updateState)),
        VerticalDivider(width: 1, color: Theme.of(context).dividerColor),
        Expanded(
          flex: 2,
          child: _controller.hasProdottoSelezionato
              ? _ProductDetailsWidget(controller: _controller, onStateChanged: _updateState)
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
          Icon(Icons.inventory_2_outlined, size: 64, color: theme.iconTheme.color?.withOpacity(0.4)),
          SizedBox(height: 16),
          Text('Seleziona un prodotto', style: theme.textTheme.titleMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7))),
          Text('per vedere i dettagli', style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5))),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: () => Navigator.pushNamed(context, '/prodotti/crea'),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.redAccent, Colors.red.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.4), blurRadius: 12, offset: Offset(0, 4))],
        ),
        child: Icon(Icons.add, size: 28, color: Colors.white),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      tooltip: 'Crea Nuovo Prodotto',
    );
  }

  void _updateState() {
    setState(() {});
  }
}

// Widget per la lista dei prodotti
class _ProductListWidget extends StatelessWidget {
  final ProdottiGestioneController controller;
  final VoidCallback onStateChanged;

  const _ProductListWidget({required this.controller, required this.onStateChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(child: _buildList(context)),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.redAccent, Colors.red.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.3), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.inventory, color: Colors.white, size: 24),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gestione Prodotti', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('Visualizza e modifica i tuoi prodotti', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9))),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(15)),
            child: Text('${controller.numeroProdotti} prodotti',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListView.builder(
        padding: EdgeInsets.all(8),
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

// Widget per ogni item della lista prodotti
class _ProductListItem extends StatelessWidget {
  final ProdottoWoo prodotto;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProductListItem({required this.prodotto, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final displayInfo = ProdottoDisplayInfo.fromProdotto(prodotto);

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: isSelected ? 8 : 2,
      shadowColor: isSelected ? Colors.redAccent.withOpacity(0.3) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected ? BorderSide(color: Colors.redAccent, width: 2) : BorderSide.none,
      ),
      color: isSelected ? Colors.redAccent.withOpacity(isDark ? 0.1 : 0.05) : theme.cardColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(12),
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
    final theme = Theme.of(context);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildNameSection(context, info)),
            _buildPriceWidget(context),
          ],
        ),
        SizedBox(height: 4),
        Row(
          children: [
            Text('ID: ${info.id}', style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7))),
            SizedBox(width: 16),
            Text(info.categoria, style: Theme.of(context).textTheme.bodySmall),
            Spacer(),
            Icon(prodotto.inStock ? Icons.check_circle : Icons.cancel,
                size: 14, color: prodotto.inStock ? Colors.green : Colors.red),
            SizedBox(width: 4),
            Text(ProdottoUtils.getVariantiCountShort(prodotto.varianti.length),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7))),
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
        Text(info.nome, style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.redAccent : theme.textTheme.titleMedium?.color)),
        Text('ID: ${info.id} • SKU: ${info.sku}', style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.7))),
      ],
    );
  }

  Widget _buildCategorySection(BuildContext context, ProdottoDisplayInfo info) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(info.categoria, style: theme.textTheme.bodyMedium),
        Row(
          children: [
            Icon(prodotto.inStock ? Icons.check_circle : Icons.cancel,
                size: 16, color: prodotto.inStock ? Colors.green : Colors.red),
            SizedBox(width: 4),
            Text(info.disponibilita, style: theme.textTheme.bodySmall?.copyWith(
                color: prodotto.inStock ? Colors.green : Colors.red)),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceWidget(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (prodotto.prezzoScontato != null) ...[
          Text(PrezzoFormatter.formatPrezzo(prodotto.prezzoNormale),
              style: theme.textTheme.bodySmall?.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.6))),
          Text(PrezzoFormatter.formatPrezzo(prodotto.prezzoScontato!),
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red, fontWeight: FontWeight.bold)),
        ] else
          Text(PrezzoFormatter.formatPrezzo(prodotto.prezzoNormale),
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildVariantsChip(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.redAccent.withOpacity(0.1), Colors.red.withOpacity(0.05)]),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.palette, size: 14, color: Colors.redAccent),
          SizedBox(width: 4),
          Text('${prodotto.varianti.length}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent)),
        ],
      ),
    );
  }
}

// Widget per i dettagli del prodotto
class _ProductDetailsWidget extends StatelessWidget {
  final ProdottiGestioneController controller;
  final VoidCallback onStateChanged;

  const _ProductDetailsWidget({required this.controller, required this.onStateChanged});

  @override
  Widget build(BuildContext context) {
    final prodotto = controller.prodottoSelezionato!;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProductHeader(controller: controller),
            SizedBox(height: 20),
            _ProductInfoCard(prodotto: prodotto),
            SizedBox(height: 20),
            _ProductVariantsCard(controller: controller, onStateChanged: onStateChanged),
          ],
        ),
      ),
    );
  }
}

// Widget per l'header del prodotto con immagine
class _ProductHeader extends StatelessWidget {
  final ProdottiGestioneController controller;

  const _ProductHeader({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final prodotto = controller.prodottoSelezionato!;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [theme.cardColor, Colors.redAccent.withOpacity(0.05)]
              : [Colors.white, Colors.redAccent.withOpacity(0.02)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.1), blurRadius: 15, offset: Offset(0, 5))],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            _ProductImage(controller: controller),
            SizedBox(height: 20),
            Text(prodotto.nome, style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold, color: Colors.redAccent), textAlign: TextAlign.center),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(isDark ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: Text(prodotto.descrizioneBreve,
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.redAccent.shade700),
                  textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget per l'immagine del prodotto con animazione
class _ProductImage extends StatelessWidget {
  final ProdottiGestioneController controller;

  const _ProductImage({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final imageUrl = controller.getCurrentImageUrl();

    return AnimatedSwitcher(
      duration: Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(imageUrl),
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 2),
          boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.2), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: isDark ? [Colors.grey[800]!, Colors.grey[700]!] : [Colors.grey[100]!, Colors.grey[50]!]),
              ),
              child: Icon(Icons.image_not_supported, size: 60, color: Colors.redAccent.withOpacity(0.5)),
            ),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: isDark ? [Colors.grey[800]!, Colors.grey[700]!] : [Colors.grey[100]!, Colors.grey[50]!])),
                child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent))),
              );
            },
          ),
        ),
      ),
    );
  }
}

// Card per le informazioni del prodotto
class _ProductInfoCard extends StatelessWidget {
  final ProdottoWoo prodotto;

  const _ProductInfoCard({required this.prodotto});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final displayInfo = ProdottoDisplayInfo.fromProdotto(prodotto);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: theme.shadowColor.withOpacity(0.1), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.info_outline, color: Colors.redAccent, size: 20),
                ),
                SizedBox(width: 12),
                Text('Informazioni Prodotto', style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold, color: Colors.redAccent)),
              ],
            ),
            SizedBox(height: 16),
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

// Card per le varianti del prodotto
class _ProductVariantsCard extends StatelessWidget {
  final ProdottiGestioneController controller;
  final VoidCallback onStateChanged;

  const _ProductVariantsCard({required this.controller, required this.onStateChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final prodotto = controller.prodottoSelezionato!;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: theme.shadowColor.withOpacity(0.1), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVariantsHeader(context, prodotto.varianti.length),
            SizedBox(height: 16),
            if (controller.hasVarianteSelezionata) ...[
              _buildResetButton(context),
              SizedBox(height: 12),
            ],
            _buildVariantsList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildVariantsHeader(BuildContext context, int variantsCount) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.palette, color: Colors.redAccent, size: 20),
        ),
        SizedBox(width: 12),
        Text('Varianti Disponibili', style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold, color: Colors.redAccent)),
        Spacer(),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.redAccent, Colors.red.shade400]),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text('$variantsCount', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildResetButton(BuildContext context) {
    return Container(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          controller.selezionaVariante(null);
          onStateChanged();
        },
        icon: Icon(Icons.clear, size: 16),
        label: Text('Mostra immagine principale'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.redAccent,
          side: BorderSide(color: Colors.redAccent),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildVariantsList(BuildContext context) {
    final prodotto = controller.prodottoSelezionato!;

    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: prodotto.varianti.length,
      separatorBuilder: (_, __) => SizedBox(height: 10),
      itemBuilder: (context, index) {
        final variante = prodotto.varianti[index];
        final isSelected = controller.isVarianteSelezionata(variante);

        return _VariantItem(
          variante: variante,
          isSelected: isSelected,
          onTap: () {
            controller.selezionaVariante(variante);
            onStateChanged();
          },
        );
      },
    );
  }
}

// Widget per ogni variante
class _VariantItem extends StatelessWidget {
  final VarianteWoo variante;
  final bool isSelected;
  final VoidCallback onTap;

  const _VariantItem({required this.variante, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
            colors: [
              Colors.redAccent.withOpacity(isDark ? 0.15 : 0.1),
              Colors.red.withOpacity(isDark ? 0.1 : 0.05),
            ],
          )
              : LinearGradient(
            colors: isDark
                ? [theme.cardColor.withOpacity(0.5), theme.cardColor.withOpacity(0.3)]
                : [Colors.grey[50]!, Colors.grey[25] ?? Colors.grey[50]!],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.redAccent : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.redAccent.withOpacity(0.2), blurRadius: 8, offset: Offset(0, 2))]
              : null,
        ),
        child: Row(
          children: [
            if (variante.immagineUrl != null && variante.immagineUrl!.isNotEmpty) ...[
              _buildVariantImage(context, isDark),
              SizedBox(width: 12),
            ],
            Expanded(child: _buildVariantInfo(context)),
            _buildVariantPrice(context),
            if (isSelected) ...[
              SizedBox(width: 8),
              _buildSelectedIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVariantImage(BuildContext context, bool isDark) {
    final theme = Theme.of(context);

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? Colors.redAccent : theme.dividerColor,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          variante.immagineUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: isDark ? Colors.grey[800] : Colors.grey[100],
            child: Icon(Icons.image, size: 20,
                color: Theme.of(context).iconTheme.color?.withOpacity(0.5)),
          ),
        ),
      ),
    );
  }

  Widget _buildVariantInfo(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          variante.nome,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.redAccent : theme.textTheme.bodyLarge?.color,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'SKU: ${variante.sku}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildVariantPrice(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.redAccent
                : theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            PrezzoFormatter.formatPrezzo(variante.prezzo),
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
          ),
        ),
        SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory,
              size: 14,
              color: isSelected
                  ? Colors.redAccent
                  : theme.iconTheme.color?.withOpacity(0.7),
            ),
            SizedBox(width: 4),
            Text(
              '${variante.quantita}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? Colors.redAccent
                    : theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectedIndicator() {
    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
      child: Icon(Icons.check, size: 16, color: Colors.white),
    );
  }
}

// Widget riutilizzabile per le righe di informazioni
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
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
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.05),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.redAccent.withOpacity(0.1)),
              ),
              child: Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}