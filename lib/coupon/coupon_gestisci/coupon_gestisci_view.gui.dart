import 'package:flutter/material.dart';
import '../class_coupon.dart';
import '../../theme/theme.dart';
import 'coupon_gestisci.code.dart';

/// Widget principale per la gestione dei coupon.
/// Supporta la gestione di coupon globali e per singolo utente.
class CouponGestisciView extends StatefulWidget {
  final String? userEmail; // Se presente, gestisce coupon per utente specifico

  const CouponGestisciView({super.key, this.userEmail});

  @override
  State<CouponGestisciView> createState() => _CouponGestisciViewState();
}

class _CouponGestisciViewState extends State<CouponGestisciView>
    with AutomaticKeepAliveClientMixin {
  final CouponGestisciController _controller = CouponGestisciController();

  // Filtri
  String? _filtroTipo;
  String? _filtroStatus;
  String _searchQuery = '';

  // UI State
  bool _isLoading = true;
  String? _errorMessage;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  Future<void> _loadCoupons() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _controller.loadCoupons(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        status: _filtroStatus,
        type: _filtroTipo,
        userEmail: widget.userEmail,
      );
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => CouponFormDialog(
        userEmail: widget.userEmail,
        onSaved: () {
          Navigator.of(context).pop();
          _loadCoupons();
        },
      ),
    );
  }

  void _showEditDialog(CouponDisplay coupon) {
    showDialog(
      context: context,
      builder: (context) => CouponFormDialog(
        coupon: coupon,
        userEmail: widget.userEmail,
        onSaved: () {
          Navigator.of(context).pop();
          _loadCoupons();
        },
      ),
    );
  }

  Future<void> _deleteCoupon(CouponDisplay coupon) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma eliminazione'),
        content: Text(
          'Sei sicuro di voler eliminare il coupon "${coupon.code}"?',
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

    if (confirm == true) {
      try {
        await _controller.deleteCoupon(coupon.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coupon eliminato con successo')),
        );
        _loadCoupons();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Errore: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Necessario per AutomaticKeepAliveClientMixin
    final theme = Theme.of(context);
    final customColors = theme.extension<AppColorExtension>()!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.userEmail != null
              ? 'Coupon per ${widget.userEmail}'
              : 'Gestione Coupon',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCoupons,
            tooltip: 'Ricarica',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateDialog,
            tooltip: 'Nuovo Coupon',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(theme),
          _buildStatisticsCard(theme, customColors),
          Expanded(child: _buildContent(theme, customColors)),
        ],
      ),
    );
  }

  Widget _buildFilters(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Barra di ricerca
          TextField(
            decoration: InputDecoration(
              hintText: 'Cerca per codice coupon...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: theme.brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[100],
            ),
            onChanged: (value) {
              _searchQuery = value;
              _loadCoupons();
            },
          ),
          const SizedBox(height: 12),
          // Filtri
          Row(
            children: [
              Expanded(
                child: _buildDropdownFilter(
                  theme,
                  'Tipo',
                  _filtroTipo,
                  [
                    const DropdownMenuItem(value: null, child: Text('Tutti')),
                    const DropdownMenuItem(
                      value: 'percent',
                      child: Text('Percentuale'),
                    ),
                    const DropdownMenuItem(
                      value: 'fixed_cart',
                      child: Text('Fisso Carrello'),
                    ),
                    const DropdownMenuItem(
                      value: 'fixed_product',
                      child: Text('Fisso Prodotto'),
                    ),
                  ],
                  (value) {
                    setState(() {
                      _filtroTipo = value;
                      _loadCoupons();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdownFilter(
                  theme,
                  'Status',
                  _filtroStatus,
                  [
                    const DropdownMenuItem(value: null, child: Text('Tutti')),
                    const DropdownMenuItem(
                      value: 'publish',
                      child: Text('Pubblicato'),
                    ),
                    const DropdownMenuItem(
                      value: 'draft',
                      child: Text('Bozza'),
                    ),
                    const DropdownMenuItem(
                      value: 'trash',
                      child: Text('Cestino'),
                    ),
                  ],
                  (value) {
                    setState(() {
                      _filtroStatus = value;
                      _loadCoupons();
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter<T>(
    ThemeData theme,
    String label,
    T? value,
    List<DropdownMenuItem<T>> items,
    ValueChanged<T?> onChanged,
  ) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: theme.brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[100],
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _buildStatisticsCard(ThemeData theme, AppColorExtension customColors) {
    if (_controller.stats == null) return const SizedBox.shrink();

    final stats = _controller.stats!;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor,
            theme.primaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            theme,
            'Totali',
            stats.totalCoupons.toString(),
            Icons.confirmation_number,
          ),
          _buildStatItem(
            theme,
            'Attivi',
            stats.activeCoupons.toString(),
            Icons.check_circle,
          ),
          _buildStatItem(
            theme,
            'Utilizzi',
            stats.totalUsage.toString(),
            Icons.trending_up,
          ),
          _buildStatItem(
            theme,
            'Sconto Tot.',
            '€${stats.totalDiscount}',
            Icons.euro,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(ThemeData theme, AppColorExtension customColors) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: theme.primaryColor),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text('Errore nel caricamento', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadCoupons,
              icon: const Icon(Icons.refresh),
              label: const Text('Riprova'),
            ),
          ],
        ),
      );
    }

    if (_controller.coupons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.discount_outlined,
              size: 80,
              color: theme.iconTheme.color?.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text('Nessun coupon trovato', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Crea il tuo primo coupon',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.7,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showCreateDialog,
              icon: const Icon(Icons.add),
              label: const Text('Nuovo Coupon'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _controller.coupons.length,
      itemBuilder: (context, index) {
        final coupon = _controller.coupons[index];
        return CouponCard(
          coupon: coupon,
          onEdit: () => _showEditDialog(coupon),
          onDelete: () => _deleteCoupon(coupon),
          onToggleStatus: () async {
            final messenger = ScaffoldMessenger.of(context);
            try {
              await _controller.toggleCouponStatus(coupon);
              _loadCoupons();
            } catch (e) {
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(content: Text('Errore: ${e.toString()}')),
              );
            }
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Card per visualizzare un singolo coupon
class CouponCard extends StatelessWidget {
  final CouponDisplay coupon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  const CouponCard({
    super.key,
    required this.coupon,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<AppColorExtension>()!;
    final isExpired = coupon.isExpired;
    final isActive = coupon.status == 'publish';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isExpired
              ? Colors.red.withValues(alpha: 0.3)
              : isActive
              ? theme.primaryColor.withValues(alpha: 0.3)
              : theme.dividerColor,
          width: isExpired || isActive ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Badge tipo coupon
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getTypeColor(coupon.discountType),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getTypeIcon(coupon.discountType),
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getTypeLabel(coupon.discountType),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Badge status
                _buildStatusBadge(theme, customColors),
                const Spacer(),
                // Azioni rapide
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                        break;
                      case 'toggle':
                        onToggleStatus();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Modifica'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(isActive ? Icons.pause : Icons.play_arrow),
                          const SizedBox(width: 8),
                          Text(isActive ? 'Disattiva' : 'Attiva'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Elimina', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Codice coupon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.primaryColor.withValues(alpha: 0.3),
                  style: BorderStyle.solid,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.confirmation_number, color: theme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    coupon.code,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    coupon.discountDisplay,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: customColors.stockAvailable,
                    ),
                  ),
                ],
              ),
            ),
            if (coupon.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                coupon.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Informazioni aggiuntive
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildInfoChip(
                  theme,
                  Icons.calendar_today,
                  'Scadenza: ${coupon.expiryDisplay}',
                  isExpired ? Colors.red : null,
                ),
                if (coupon.usageLimit != null)
                  _buildInfoChip(
                    theme,
                    Icons.repeat,
                    'Limite: ${coupon.usageCount}/${coupon.usageLimit}',
                  ),
                if (coupon.minimumAmount != null)
                  _buildInfoChip(
                    theme,
                    Icons.shopping_cart,
                    'Min: €${coupon.minimumAmount}',
                  ),
                if (coupon.freeShipping)
                  _buildInfoChip(
                    theme,
                    Icons.local_shipping,
                    'Spedizione Gratis',
                    Colors.green,
                  ),
                if (coupon.emailRestrictions.isNotEmpty)
                  _buildInfoChip(
                    theme,
                    Icons.person,
                    'Email: ${coupon.emailRestrictions.first}',
                    Colors.blue,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme, AppColorExtension customColors) {
    Color color;
    String label;
    IconData icon;

    if (coupon.isExpired) {
      color = Colors.red;
      label = 'SCADUTO';
      icon = Icons.timer_off;
    } else if (coupon.status == 'publish') {
      color = customColors.stockAvailable;
      label = 'ATTIVO';
      icon = Icons.check_circle;
    } else if (coupon.status == 'draft') {
      color = Colors.orange;
      label = 'BOZZA';
      icon = Icons.edit;
    } else {
      color = Colors.grey;
      label = 'CESTINO';
      icon = Icons.delete;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    ThemeData theme,
    IconData icon,
    String label, [
    Color? color,
  ]) {
    final chipColor =
        color ??
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ??
        Colors.grey;

    return Chip(
      avatar: Icon(icon, size: 16, color: chipColor),
      label: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(color: chipColor),
      ),
      backgroundColor: chipColor.withValues(alpha: 0.1),
      side: BorderSide(color: chipColor.withValues(alpha: 0.3)),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'percent':
        return Colors.purple;
      case 'fixed_cart':
        return Colors.blue;
      case 'fixed_product':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'percent':
        return Icons.percent;
      case 'fixed_cart':
        return Icons.shopping_cart;
      case 'fixed_product':
        return Icons.inventory;
      default:
        return Icons.discount;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'percent':
        return 'Percentuale';
      case 'fixed_cart':
        return 'Fisso Carrello';
      case 'fixed_product':
        return 'Fisso Prodotto';
      default:
        return 'Altro';
    }
  }
}

/// Dialog per creare/modificare un coupon
class CouponFormDialog extends StatefulWidget {
  final CouponDisplay? coupon;
  final String? userEmail;
  final VoidCallback onSaved;

  const CouponFormDialog({
    super.key,
    this.coupon,
    this.userEmail,
    required this.onSaved,
  });

  @override
  State<CouponFormDialog> createState() => _CouponFormDialogState();
}

class _CouponFormDialogState extends State<CouponFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final CouponGestisciController _controller = CouponGestisciController();

  late TextEditingController _codeController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _minimumAmountController;
  late TextEditingController _maximumAmountController;
  late TextEditingController _usageLimitController;
  late TextEditingController _usageLimitPerUserController;

  String _discountType = 'percent';
  String _status = 'publish';
  bool _freeShipping = false;
  bool _excludeSaleItems = false;
  DateTime? _dateExpires;
  List<String> _emailRestrictions = [];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    // Inizializza i controller
    _codeController = TextEditingController(text: widget.coupon?.code ?? '');
    _amountController = TextEditingController(
      text: widget.coupon?.amount ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.coupon?.description ?? '',
    );
    _minimumAmountController = TextEditingController(
      text: widget.coupon?.minimumAmount ?? '',
    );
    _maximumAmountController = TextEditingController(
      text: widget.coupon?.maximumAmount ?? '',
    );
    _usageLimitController = TextEditingController(
      text: widget.coupon?.usageLimit?.toString() ?? '',
    );
    _usageLimitPerUserController = TextEditingController(
      text: widget.coupon?.usageLimitPerUser?.toString() ?? '',
    );

    if (widget.coupon != null) {
      _discountType = widget.coupon!.discountType;
      _status = widget.coupon!.status;
      _freeShipping = widget.coupon!.freeShipping;
      _excludeSaleItems = widget.coupon!.excludeSaleItems;
      _dateExpires = widget.coupon!.dateExpires;
      _emailRestrictions = List.from(widget.coupon!.emailRestrictions);
    }

    // Se c'è un userEmail, aggiungilo alle restrizioni
    if (widget.userEmail != null &&
        !_emailRestrictions.contains(widget.userEmail)) {
      _emailRestrictions.add(widget.userEmail!);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      if (widget.coupon == null) {
        // Crea nuovo coupon
        await _controller.createCoupon(
          code: _codeController.text,
          discountType: _discountType,
          amount: _amountController.text,
          status: _status,
          description: _descriptionController.text,
          dateExpires: _dateExpires,
          usageLimit: int.tryParse(_usageLimitController.text),
          usageLimitPerUser: int.tryParse(_usageLimitPerUserController.text),
          freeShipping: _freeShipping,
          excludeSaleItems: _excludeSaleItems,
          minimumAmount: _minimumAmountController.text.isEmpty
              ? null
              : _minimumAmountController.text,
          maximumAmount: _maximumAmountController.text.isEmpty
              ? null
              : _maximumAmountController.text,
          emailRestrictions: _emailRestrictions.isEmpty
              ? null
              : _emailRestrictions,
        );
      } else {
        // Aggiorna coupon esistente
        await _controller.updateCoupon(
          widget.coupon!.id,
          code: _codeController.text,
          discountType: _discountType,
          amount: _amountController.text,
          status: _status,
          description: _descriptionController.text,
          dateExpires: _dateExpires,
          usageLimit: int.tryParse(_usageLimitController.text),
          usageLimitPerUser: int.tryParse(_usageLimitPerUserController.text),
          freeShipping: _freeShipping,
          excludeSaleItems: _excludeSaleItems,
          minimumAmount: _minimumAmountController.text.isEmpty
              ? null
              : _minimumAmountController.text,
          maximumAmount: _maximumAmountController.text.isEmpty
              ? null
              : _maximumAmountController.text,
          emailRestrictions: _emailRestrictions.isEmpty
              ? null
              : _emailRestrictions,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.coupon == null
                ? 'Coupon creato con successo'
                : 'Coupon aggiornato con successo',
          ),
        ),
      );
      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Errore: ${e.toString()}')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.coupon == null ? Icons.add : Icons.edit,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.coupon == null ? 'Nuovo Coupon' : 'Modifica Coupon',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          labelText: 'Codice Coupon *',
                          hintText: 'es. SCONTO20',
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Campo obbligatorio'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _discountType,
                        decoration: const InputDecoration(
                          labelText: 'Tipo Sconto',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'percent',
                            child: Text('Percentuale'),
                          ),
                          DropdownMenuItem(
                            value: 'fixed_cart',
                            child: Text('Fisso sul Carrello'),
                          ),
                          DropdownMenuItem(
                            value: 'fixed_product',
                            child: Text('Fisso sul Prodotto'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _discountType = value!),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _amountController,
                        decoration: InputDecoration(
                          labelText: _discountType == 'percent'
                              ? 'Percentuale Sconto *'
                              : 'Importo Sconto *',
                          hintText: _discountType == 'percent'
                              ? 'es. 20'
                              : 'es. 10.00',
                          border: const OutlineInputBorder(),
                          suffixText: _discountType == 'percent' ? '%' : '€',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Campo obbligatorio'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Descrizione',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _status,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'publish',
                            child: Text('Pubblicato'),
                          ),
                          DropdownMenuItem(
                            value: 'draft',
                            child: Text('Bozza'),
                          ),
                        ],
                        onChanged: (value) => setState(() => _status = value!),
                      ),
                      const SizedBox(height: 16),
                      // Data scadenza
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _dateExpires ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365 * 5),
                            ),
                          );
                          if (date != null) {
                            setState(() => _dateExpires = date);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Data Scadenza',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            _dateExpires != null
                                ? '${_dateExpires!.day}/${_dateExpires!.month}/${_dateExpires!.year}'
                                : 'Nessuna scadenza',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _usageLimitController,
                              decoration: const InputDecoration(
                                labelText: 'Limite Utilizzi',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _usageLimitPerUserController,
                              decoration: const InputDecoration(
                                labelText: 'Limite Per Utente',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _minimumAmountController,
                              decoration: const InputDecoration(
                                labelText: 'Importo Minimo',
                                border: OutlineInputBorder(),
                                prefixText: '€ ',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _maximumAmountController,
                              decoration: const InputDecoration(
                                labelText: 'Importo Massimo',
                                border: OutlineInputBorder(),
                                prefixText: '€ ',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Spedizione Gratuita'),
                        value: _freeShipping,
                        onChanged: (value) =>
                            setState(() => _freeShipping = value),
                      ),
                      SwitchListTile(
                        title: const Text('Escludi Prodotti in Saldo'),
                        value: _excludeSaleItems,
                        onChanged: (value) =>
                            setState(() => _excludeSaleItems = value),
                      ),
                      if (widget.userEmail != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.primaryColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.person, color: theme.primaryColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Riservato a: ${widget.userEmail}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border(top: BorderSide(color: theme.dividerColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Annulla'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.coupon == null ? 'Crea' : 'Salva'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _minimumAmountController.dispose();
    _maximumAmountController.dispose();
    _usageLimitController.dispose();
    _usageLimitPerUserController.dispose();
    _controller.dispose();
    super.dispose();
  }
}
