import 'package:flutter/material.dart';
import '../class_coupon.dart';
import '../../theme/theme.dart';

/// Widget per visualizzare le statistiche dei coupon in modo compatto
class CouponStatsCompact extends StatelessWidget {
  final CouponStatsDisplay stats;
  final VoidCallback? onTap;

  const CouponStatsCompact({super.key, required this.stats, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.primaryColor.withValues(alpha: 0.8),
              theme.primaryColor,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: theme.primaryColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Statistiche Coupon',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
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
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget per visualizzare un piccolo badge del coupon
class CouponBadge extends StatelessWidget {
  final CouponDisplay coupon;
  final VoidCallback? onTap;

  const CouponBadge({super.key, required this.coupon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getTypeColor(coupon.discountType),
              _getTypeColor(coupon.discountType).withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: _getTypeColor(coupon.discountType).withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getTypeIcon(coupon.discountType),
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              coupon.code,
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              coupon.discountDisplay,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
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
}

/// Widget per visualizzare la lista dei coupon in modo compatto
class CouponListCompact extends StatelessWidget {
  final List<CouponDisplay> coupons;
  final Function(CouponDisplay)? onCouponTap;
  final Function(CouponDisplay)? onCouponDelete;

  const CouponListCompact({
    super.key,
    required this.coupons,
    this.onCouponTap,
    this.onCouponDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (coupons.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.separated(
      itemCount: coupons.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final coupon = coupons[index];
        return CouponListItemCompact(
          coupon: coupon,
          onTap: onCouponTap != null ? () => onCouponTap!(coupon) : null,
          onDelete: onCouponDelete != null
              ? () => onCouponDelete!(coupon)
              : null,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.discount_outlined,
            size: 64,
            color: theme.iconTheme.color?.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Nessun coupon disponibile',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget per visualizzare un singolo coupon in modo compatto
class CouponListItemCompact extends StatelessWidget {
  final CouponDisplay coupon;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const CouponListItemCompact({
    super.key,
    required this.coupon,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<AppColorExtension>()!;
    final isExpired = coupon.isExpired;
    final isActive = coupon.status == 'publish';

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _getTypeColor(coupon.discountType).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _getTypeIcon(coupon.discountType),
          color: _getTypeColor(coupon.discountType),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              coupon.code,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: customColors.stockAvailable.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              coupon.discountDisplay,
              style: theme.textTheme.labelSmall?.copyWith(
                color: customColors.stockAvailable,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          if (coupon.description.isNotEmpty)
            Text(
              coupon.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isExpired
                    ? Icons.timer_off
                    : isActive
                    ? Icons.check_circle
                    : Icons.pause_circle,
                size: 12,
                color: isExpired
                    ? Colors.red
                    : isActive
                    ? customColors.stockAvailable
                    : Colors.orange,
              ),
              const SizedBox(width: 4),
              Text(
                isExpired
                    ? 'Scaduto'
                    : isActive
                    ? 'Attivo'
                    : 'Non attivo',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isExpired
                      ? Colors.red
                      : isActive
                      ? customColors.stockAvailable
                      : Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.calendar_today,
                size: 12,
                color: theme.iconTheme.color?.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Text(
                coupon.expiryDisplay,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: onDelete != null
          ? IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onDelete,
            )
          : null,
      isThreeLine: coupon.description.isNotEmpty,
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
}

/// Widget per validare un coupon in tempo reale
class CouponValidationWidget extends StatefulWidget {
  final Function(String code)? onValidate;

  const CouponValidationWidget({super.key, this.onValidate});

  @override
  State<CouponValidationWidget> createState() => _CouponValidationWidgetState();
}

class _CouponValidationWidgetState extends State<CouponValidationWidget> {
  final TextEditingController _controller = TextEditingController();
  bool _isValidating = false;
  String? _validationMessage;
  bool? _isValid;

  void _validate() {
    if (_controller.text.isEmpty) return;

    setState(() {
      _isValidating = true;
      _validationMessage = null;
      _isValid = null;
    });

    widget.onValidate?.call(_controller.text);

    // Simulazione validazione (in realtà dovrebbe chiamare il servizio)
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isValidating = false;
          _isValid = true; // Esempio
          _validationMessage = 'Coupon valido!';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Verifica Coupon',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Inserisci codice coupon',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.confirmation_number),
                      suffixIcon: _isValidating
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : _isValid != null
                          ? Icon(
                              _isValid! ? Icons.check_circle : Icons.error,
                              color: _isValid! ? Colors.green : Colors.red,
                            )
                          : null,
                    ),
                    textCapitalization: TextCapitalization.characters,
                    onSubmitted: (_) => _validate(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isValidating ? null : _validate,
                  child: const Text('Verifica'),
                ),
              ],
            ),
            if (_validationMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (_isValid ?? false)
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (_isValid ?? false) ? Colors.green : Colors.red,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      (_isValid ?? false) ? Icons.check_circle : Icons.error,
                      color: (_isValid ?? false) ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _validationMessage!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: (_isValid ?? false)
                              ? Colors.green
                              : Colors.red,
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
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Widget per selezionare un coupon da una lista
class CouponSelectorDialog extends StatefulWidget {
  final List<CouponDisplay> coupons;
  final String? selectedCouponId;

  const CouponSelectorDialog({
    super.key,
    required this.coupons,
    this.selectedCouponId,
  });

  @override
  State<CouponSelectorDialog> createState() => _CouponSelectorDialogState();
}

class _CouponSelectorDialogState extends State<CouponSelectorDialog> {
  String? _selectedId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedCouponId;
  }

  List<CouponDisplay> get filteredCoupons {
    if (_searchQuery.isEmpty) return widget.coupons;
    return widget.coupons
        .where((c) => c.code.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
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
                  const Icon(Icons.discount, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Seleziona Coupon',
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
            // Ricerca
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Cerca coupon...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            // Lista
            Expanded(
              child: ListView.builder(
                itemCount: filteredCoupons.length,
                itemBuilder: (context, index) {
                  final coupon = filteredCoupons[index];
                  final isSelected = _selectedId == coupon.id.toString();

                  return ListTile(
                    selected: isSelected,
                    leading: Radio<String>(
                      value: coupon.id.toString(),
                      groupValue: _selectedId, // ignore: deprecated_member_use
                      onChanged: (value) => setState(
                        () => _selectedId = value,
                      ), // ignore: deprecated_member_use
                    ),
                    title: Text(
                      coupon.code,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(coupon.discountDisplay),
                    trailing: coupon.isExpired
                        ? const Chip(
                            label: Text('Scaduto'),
                            backgroundColor: Colors.red,
                            labelStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          )
                        : null,
                    onTap: () =>
                        setState(() => _selectedId = coupon.id.toString()),
                  );
                },
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: theme.dividerColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annulla'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _selectedId != null
                        ? () {
                            final selected = widget.coupons.firstWhere(
                              (c) => c.id.toString() == _selectedId,
                            );
                            Navigator.pop(context, selected);
                          }
                        : null,
                    child: const Text('Seleziona'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
