import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'carta_fedelta.code.dart';
import '../notification/notification_service.dart';
import '../theme/theme.dart';
import '../reuse_class/gui/barcode_scanner.dart';

class CartaFedeltaPage extends StatefulWidget {
  const CartaFedeltaPage({super.key});

  @override
  CartaFedeltaPageState createState() => CartaFedeltaPageState();
}

class CartaFedeltaPageState extends State<CartaFedeltaPage>
    with AutomaticKeepAliveClientMixin {
  final CartaFedeltaController _controller = CartaFedeltaController();
  final TextEditingController _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _caricaDati();
  }

  Future<void> _caricaDati() async {
    await _controller.caricaClientiConCarta();
    await _controller.caricaStatistiche();
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostraDialogCercaCarta(context),
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scansiona Carta'),
      ),
    );
  }

  /// Layout per desktop
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // LATO SINISTRO - Lista carte (60%)
        Expanded(flex: 6, child: _buildListaCarteWidget()),

        // Divider verticale
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: Theme.of(context).dividerColor,
        ),

        // LATO DESTRO - Dettagli carta (40%)
        Expanded(flex: 4, child: _buildDettagliCartaWidget()),
      ],
    );
  }

  /// Layout per mobile
  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Lista carte
        Expanded(flex: 2, child: _buildListaCarteWidget()),

        Divider(height: 1, color: Theme.of(context).dividerColor),

        // Dettagli carta (collapsible)
        if (_controller.hasCartaSelezionata)
          Expanded(flex: 1, child: _buildDettagliCartaWidget()),
      ],
    );
  }

  /// Widget lista carte
  Widget _buildListaCarteWidget() {
    final theme = Theme.of(context);
    final customColors = theme.extension<AppColorExtension>();

    return Column(
      children: [
        // Header con ricerca e statistiche
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
              Row(
                children: [
                  const Icon(
                    Icons.card_membership,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Carte Fedeltà',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Badge totale carte
                  if (_controller.statistiche != null)
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
                        '${_controller.statistiche!['total_customers_with_card'] ?? 0}',
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Statistiche rapide
              if (_controller.statistiche != null) _buildStatisticheRapide(),

              const SizedBox(height: 16),

              // Campo di ricerca
              TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Cerca per nome, email, numero carta...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white),
                          onPressed: () {
                            _searchController.clear();
                            _controller.setSearchQuery('');
                            _updateState();
                          },
                        ),
                      IconButton(
                        icon: const Icon(
                          Icons.qr_code_scanner,
                          color: Colors.white,
                        ),
                        onPressed: () => _mostraDialogCercaCarta(context),
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
                  _controller.setSearchQuery(value);
                  _updateState();
                },
              ),
            ],
          ),
        ),

        // Lista carte
        Expanded(
          child: _controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _controller.clientiConCarta.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _caricaDati,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _controller.clientiConCarta.length,
                    itemBuilder: (context, index) {
                      final carta = _controller.clientiConCarta[index];
                      return _buildCardCarta(carta);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  /// Statistiche rapide
  Widget _buildStatisticheRapide() {
    final stats = _controller.statistiche!;
    final tierDist = stats['tier_distribution'] as Map<String, dynamic>;

    return Row(
      children: [
        Expanded(
          child: _buildStatChip(
            label: 'Punti Totali',
            value: '${stats['total_points_issued'] ?? 0}',
            icon: Icons.stars,
            color: Colors.amber,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatChip(
            label: 'Oro',
            value: '${tierDist['gold'] ?? 0}',
            icon: Icons.workspace_premium,
            color: const Color(0xFFFFD700),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatChip(
            label: 'Argento',
            value: '${tierDist['silver'] ?? 0}',
            icon: Icons.workspace_premium,
            color: const Color(0xFFC0C0C0),
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  /// Card per visualizzare una carta fedeltà
  Widget _buildCardCarta(Map<String, dynamic> carta) {
    final theme = Theme.of(context);
    final customColors = theme.extension<AppColorExtension>();

    final isSelected =
        _controller.hasCartaSelezionata &&
        _controller.cartaSelezionata!['customer_id'] == carta['customer_id'];

    final tier = carta['tier'] as String? ?? 'bronze';
    final punti = carta['points'] as int? ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: isSelected
          ? customColors?.variantSelectedBackground ??
                theme.primaryColor.withValues(alpha: 0.1)
          : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTierColor(tier),
          child: Icon(Icons.card_membership, color: Colors.white),
        ),
        title: Text(
          '${carta['first_name']} ${carta['last_name']}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Carta: ${carta['card_number']}'),
            Row(
              children: [
                Icon(Icons.stars, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  '$punti punti',
                  style: TextStyle(
                    color: customColors?.successColor ?? Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getTierColor(tier),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _controller.getNomeTier(tier),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: theme.primaryColor)
            : const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          _controller.selezionaCarta(carta);
          _updateState();
        },
      ),
    );
  }

  /// Widget dettagli carta selezionata
  Widget _buildDettagliCartaWidget() {
    if (!_controller.hasCartaSelezionata) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.card_membership_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Seleziona una carta',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    final carta = _controller.cartaSelezionata!;
    final theme = Theme.of(context);
    final customColors = theme.extension<AppColorExtension>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  _controller.deselezionaCarta();
                  _updateState();
                },
              ),
              Expanded(
                child: Text(
                  'Dettagli Carta',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Card visuale
          _buildVisualCard(carta),

          const SizedBox(height: 24),

          // Informazioni cliente
          _buildInfoSection('Informazioni Cliente', [
            _buildInfoRow(
              'Nome',
              '${carta['first_name']} ${carta['last_name']}',
            ),
            _buildInfoRow('Email', carta['email'] ?? 'N/A'),
            _buildInfoRow('ID Cliente', '#${carta['customer_id']}'),
          ]),

          const SizedBox(height: 16),

          // Gestione punti
          _buildInfoSection('Gestione Punti', [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _mostraDialogGestionePunti(
                      context,
                      carta,
                      aggiungi: true,
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Aggiungi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          customColors?.successColor ?? Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _mostraDialogGestionePunti(
                      context,
                      carta,
                      aggiungi: false,
                    ),
                    icon: const Icon(Icons.remove),
                    label: const Text('Rimuovi'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          customColors?.errorColorStatus ?? Colors.red,
                      side: BorderSide(
                        color: customColors?.errorColorStatus ?? Colors.red,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ]),

          const SizedBox(height: 16),

          // Gestione tier
          _buildInfoSection('Tier Fedeltà', [_buildTierSelector(carta)]),

          const SizedBox(height: 16),

          // Azioni
          _buildInfoSection('Azioni', [
            ElevatedButton.icon(
              onPressed: () => _mostraDialogStoricoPunti(context, carta),
              icon: const Icon(Icons.history),
              label: const Text('Visualizza Storico'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _confermaRimozioneCarta(context, carta),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Rimuovi Carta'),
              style: OutlinedButton.styleFrom(
                foregroundColor: customColors?.errorColorStatus ?? Colors.red,
                side: BorderSide(
                  color: customColors?.errorColorStatus ?? Colors.red,
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  /// Card visuale della carta fedeltà
  Widget _buildVisualCard(Map<String, dynamic> carta) {
    final tier = carta['tier'] as String? ?? 'bronze';
    final punti = carta['points'] as int? ?? 0;
    final cardNumber = carta['card_number'] as String? ?? '';

    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getTierColor(tier),
            _getTierColor(tier).withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.card_membership, color: Colors.white, size: 32),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _controller.getNomeTier(tier).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            cardNumber,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${carta['first_name']} ${carta['last_name']}'.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PUNTI',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    '$punti',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.stars, color: Colors.white, size: 28),
            ],
          ),
        ],
      ),
    );
  }

  /// Sezione informazioni
  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  /// Riga informazione
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  /// Selettore tier
  Widget _buildTierSelector(Map<String, dynamic> carta) {
    final tierCorrente = carta['tier'] as String? ?? 'bronze';
    final tiers = ['bronze', 'silver', 'gold', 'platinum'];

    return Wrap(
      spacing: 8,
      children: tiers.map((tier) {
        final isSelected = tier == tierCorrente;
        return ChoiceChip(
          label: Text(_controller.getNomeTier(tier)),
          selected: isSelected,
          selectedColor: _getTierColor(tier),
          backgroundColor: _getTierColor(tier).withValues(alpha: 0.3),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          onSelected: (selected) async {
            if (selected && tier != tierCorrente) {
              final success = await _controller.aggiornaTier(
                customerId: carta['customer_id'],
                numeroCarta: carta['card_number'],
                nuovoTier: tier,
              );

              if (success && mounted) {
                NotificationService.instance.messageBar(
                  'successo',
                  'carta_fedelta',
                  'Tier aggiornato con successo',
                );
                _updateState();
              }
            }
          },
        );
      }).toList(),
    );
  }

  /// Empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.card_membership_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Nessuna carta fedeltà',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Scansiona o cerca una carta per iniziare',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // =======================================================
  // == DIALOGS                                           ==
  // =======================================================

  /// Dialog per cercare/scansionare carta
  Future<void> _mostraDialogCercaCarta(BuildContext context) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerca Carta Fedeltà'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Numero Carta',
                hintText: 'Inserisci o scansiona',
                prefixIcon: const Icon(Icons.card_membership),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: () async {
                    final scanned = await showBarcodeScanner(context);
                    if (scanned != null) {
                      controller.text = scanned;
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
              final numeroCarta = controller.text.trim();
              if (numeroCarta.isEmpty) return;

              Navigator.pop(context);

              final carta = await _controller.cercaCartaPerNumero(numeroCarta);

              if (carta != null && mounted) {
                _controller.selezionaCarta(carta);
                _updateState();

                if (mounted) {
                  NotificationService.instance.messageBar(
                    'successo',
                    'carta_fedelta',
                    'Carta trovata!',
                  );
                }
              } else {
                if (mounted) {
                  NotificationService.instance.messageBar(
                    'errore',
                    'carta_fedelta',
                    'Carta non trovata',
                  );
                }
              }
            },
            child: const Text('Cerca'),
          ),
        ],
      ),
    );

    controller.dispose();
  }

  /// Dialog gestione punti
  Future<void> _mostraDialogGestionePunti(
    BuildContext context,
    Map<String, dynamic> carta, {
    required bool aggiungi,
  }) async {
    final puntiController = TextEditingController();
    final noteController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(aggiungi ? 'Aggiungi Punti' : 'Rimuovi Punti'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: puntiController,
              decoration: const InputDecoration(
                labelText: 'Punti',
                prefixIcon: Icon(Icons.stars),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Note (opzionale)',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
              final punti = int.tryParse(puntiController.text) ?? 0;
              if (punti <= 0) return;

              Navigator.pop(context);

              final success = aggiungi
                  ? await _controller.aggiungiPunti(
                      customerId: carta['customer_id'],
                      punti: punti,
                      note: noteController.text.trim().isNotEmpty
                          ? noteController.text.trim()
                          : null,
                    )
                  : await _controller.sottraiPunti(
                      customerId: carta['customer_id'],
                      punti: punti,
                      note: noteController.text.trim().isNotEmpty
                          ? noteController.text.trim()
                          : null,
                    );

              if (success && mounted) {
                NotificationService.instance.messageBar(
                  'successo',
                  'carta_fedelta',
                  aggiungi
                      ? 'Punti aggiunti con successo'
                      : 'Punti rimossi con successo',
                );
                _updateState();
              }
            },
            child: Text(aggiungi ? 'Aggiungi' : 'Rimuovi'),
          ),
        ],
      ),
    );

    puntiController.dispose();
    noteController.dispose();
  }

  /// Dialog storico punti
  Future<void> _mostraDialogStoricoPunti(
    BuildContext context,
    Map<String, dynamic> carta,
  ) async {
    final storico = await _controller.getStoricoPunti(carta['customer_id']);

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Storico Punti'),
        content: SizedBox(
          width: double.maxFinite,
          child: storico.isEmpty
              ? const Center(child: Text('Nessuno storico disponibile'))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: storico.length,
                  itemBuilder: (context, index) {
                    final entry = storico[index];
                    final amount = entry['amount'] as int? ?? 0;
                    final isPositive = amount >= 0;

                    return ListTile(
                      leading: Icon(
                        isPositive ? Icons.add_circle : Icons.remove_circle,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                      title: Text(entry['note'] ?? 'N/A'),
                      subtitle: Text(entry['date'] ?? ''),
                      trailing: Text(
                        '${isPositive ? '+' : ''}$amount',
                        style: TextStyle(
                          color: isPositive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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

  /// Conferma rimozione carta
  Future<void> _confermaRimozioneCarta(
    BuildContext context,
    Map<String, dynamic> carta,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma Rimozione'),
        content: const Text(
          'Sei sicuro di voler rimuovere questa carta fedeltà? I punti rimarranno sul cliente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rimuovi'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await _controller.rimuoviCarta(carta['customer_id']);

      if (success && mounted) {
        NotificationService.instance.messageBar(
          'successo',
          'carta_fedelta',
          'Carta rimossa con successo',
        );
        _updateState();
      }
    }
  }

  // =======================================================
  // == HELPER METHODS                                    ==
  // =======================================================

  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'platinum':
        return const Color(0xFFE5E4E2);
      case 'gold':
        return const Color(0xFFFFD700);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'bronze':
      default:
        return const Color(0xFFCD7F32);
    }
  }
}
