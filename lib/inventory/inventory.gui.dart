import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'inventory.code.dart';
import 'inventory_counts.gui.dart';
import 'inventory_movements.gui.dart';
import 'inventory_purchase_orders.gui.dart';
import 'inventory_quick_load.gui.dart';
import 'inventory_receipts.gui.dart';
import 'inventory_reorder.gui.dart';
import 'inventory_suppliers.gui.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({
    super.key,
    this.controller,
    this.quickLoadController,
    this.supplierController,
    this.reorderController,
    this.purchaseOrderController,
    this.receiptController,
    this.movementController,
    this.countController,
  });

  final InventoryController? controller;
  final InventoryQuickLoadController? quickLoadController;
  final InventorySupplierController? supplierController;
  final InventoryReorderController? reorderController;
  final InventoryPurchaseOrderController? purchaseOrderController;
  final InventoryReceiptController? receiptController;
  final InventoryMovementController? movementController;
  final InventoryCountSessionController? countController;

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  late final InventoryController _controller;
  late final InventoryQuickLoadController _quickLoadController;
  late final InventorySupplierController _supplierController;
  late final InventoryReorderController _reorderController;
  late final InventoryPurchaseOrderController _purchaseOrderController;
  late final InventoryReceiptController _receiptController;
  late final InventoryMovementController _movementController;
  late final InventoryCountSessionController _countController;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? InventoryController();
    _quickLoadController =
        widget.quickLoadController ?? InventoryQuickLoadController();
    _supplierController =
        widget.supplierController ?? InventorySupplierController();
    _reorderController =
        widget.reorderController ?? InventoryReorderController();
    _purchaseOrderController =
        widget.purchaseOrderController ?? InventoryPurchaseOrderController();
    _receiptController =
        widget.receiptController ?? InventoryReceiptController();
    _movementController =
        widget.movementController ?? InventoryMovementController();
    _countController =
        widget.countController ?? InventoryCountSessionController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkReadiness());
  }

  Future<void> _checkReadiness() async {
    final pending = _controller.checkMgwsReadiness();
    setState(() {});
    await pending;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorExtension>()!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.gradientStart, colors.gradientEnd],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 760;
              return SingleChildScrollView(
                key: const ValueKey('inventory-shell'),
                padding: EdgeInsets.all(isSmall ? 12 : 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Column(
                      key: ValueKey(
                        isSmall
                            ? 'inventory-small-layout'
                            : 'inventory-desktop-layout',
                      ),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Header(isSmall: isSmall),
                        const SizedBox(height: 16),
                        _BackendStatus(controller: _controller),
                        const SizedBox(height: 16),
                        _SectionGrid(isSmall: isSmall),
                        const SizedBox(height: 16),
                        _OperationTabs(
                          isSmall: isSmall,
                          quickLoadController: _quickLoadController,
                          supplierController: _supplierController,
                          reorderController: _reorderController,
                          purchaseOrderController: _purchaseOrderController,
                          receiptController: _receiptController,
                          movementController: _movementController,
                          countController: _countController,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Le schede preparano la navigazione dei flussi MGWS. '
                          'I workflow operativi saranno attivati nelle schermate dedicate.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _InventorySection {
  const _InventorySection({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}

const _sections = [
  _InventorySection(
    title: 'Quick Load',
    subtitle: 'Carico rapido auditato per prodotto, barcode o ubicazione.',
    icon: Icons.flash_on,
  ),
  _InventorySection(
    title: 'Fornitori',
    subtitle: 'Anagrafica fornitori MGWS con edit e cancellazione protetta.',
    icon: Icons.storefront,
  ),
  _InventorySection(
    title: 'Riordino',
    subtitle: 'Soglie, suggerimenti e regole fornitore gestite da MGWS.',
    icon: Icons.trending_up,
  ),
  _InventorySection(
    title: 'Ordini Fornitore',
    subtitle: 'Bozze e righe ordine pronte per il ciclo acquisti.',
    icon: Icons.assignment,
  ),
  _InventorySection(
    title: 'Ricezione/Convalida',
    subtitle: 'DDT, differenze e convalida finale prima dei movimenti.',
    icon: Icons.fact_check,
  ),
  _InventorySection(
    title: 'Movimenti',
    subtitle: 'Ledger consultivo dei movimenti stock generati da MGWS.',
    icon: Icons.timeline,
  ),
  _InventorySection(
    title: 'Inventario fisico',
    subtitle: 'Sessioni di conta, letture fisiche e approvazione proposta.',
    icon: Icons.inventory,
  ),
];

class _Header extends StatelessWidget {
  const _Header({required this.isSmall});

  final bool isSmall;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorExtension>()!;
    final scheme = theme.colorScheme;
    final icon = Container(
      width: isSmall ? 58 : 72,
      height: isSmall ? 58 : 72,
      decoration: BoxDecoration(
        color: scheme.onPrimary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(Icons.inventory_2, color: scheme.onPrimary, size: 34),
    );
    final copy = Column(
      crossAxisAlignment: isSmall
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          'Inventario MGWS',
          textAlign: isSmall ? TextAlign.center : TextAlign.start,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: scheme.onPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Shell operativa per carichi, riordini, ricezioni, movimenti e conte fisiche.',
          textAlign: isSmall ? TextAlign.center : TextAlign.start,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onPrimary.withValues(alpha: 0.88),
          ),
        ),
      ],
    );
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [colors.headerGradientStart, colors.headerGradientEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: isSmall
          ? Column(children: [icon, const SizedBox(height: 16), copy])
          : Row(
              children: [
                icon,
                const SizedBox(width: 18),
                Expanded(child: copy),
              ],
            ),
    );
  }
}

class _BackendStatus extends StatelessWidget {
  const _BackendStatus({required this.controller});

  final InventoryController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorExtension>()!;
    final scheme = theme.colorScheme;
    final available = controller.isMgwsAvailable == true;
    final checking = controller.isCheckingAvailability;
    final statusColor = checking
        ? colors.warningColor
        : available
        ? colors.successColor
        : colors.errorColorStatus;
    final title = checking
        ? 'Verifica backend MGWS'
        : available
        ? 'Backend MGWS disponibile'
        : 'Backend MGWS richiesto';
    final message = checking
        ? 'Controllo connessione inventario in corso.'
        : available
        ? 'Puoi usare le sezioni quando i workflow dedicati saranno aperti.'
        : 'Accedi o configura il backend MGWS prima di usare i flussi inventario.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(
            available ? Icons.check_circle : Icons.admin_panel_settings,
            color: statusColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.subtitleColor,
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

class _SectionGrid extends StatelessWidget {
  const _SectionGrid({required this.isSmall});

  final bool isSmall;

  @override
  Widget build(BuildContext context) {
    final spacing = isSmall ? 12.0 : 16.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = isSmall
            ? 1
            : constraints.maxWidth < 980
            ? 2
            : 3;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final section in _sections)
              SizedBox(
                width: width,
                child: _SectionCard(section: section),
              ),
          ],
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section});

  final _InventorySection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorExtension>()!;
    final scheme = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(section.icon, color: scheme.primary, size: 30),
            const SizedBox(height: 12),
            Text(
              section.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              section.subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.subtitleColor,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OperationTabs extends StatelessWidget {
  const _OperationTabs({
    required this.isSmall,
    required this.quickLoadController,
    required this.supplierController,
    required this.reorderController,
    required this.purchaseOrderController,
    required this.receiptController,
    required this.movementController,
    required this.countController,
  });

  final bool isSmall;
  final InventoryQuickLoadController quickLoadController;
  final InventorySupplierController supplierController;
  final InventoryReorderController reorderController;
  final InventoryPurchaseOrderController purchaseOrderController;
  final InventoryReceiptController receiptController;
  final InventoryMovementController movementController;
  final InventoryCountSessionController countController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DefaultTabController(
      length: _sections.length,
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: scheme.primary,
                unselectedLabelColor: scheme.onSurfaceVariant,
                tabs: [
                  for (final section in _sections) Tab(text: section.title),
                ],
              ),
              SizedBox(
                height: isSmall ? 920 : 640,
                child: TabBarView(
                  children: [
                    SingleChildScrollView(
                      primary: false,
                      child: InventoryQuickLoadPanel(
                        controller: quickLoadController,
                      ),
                    ),
                    InventorySupplierPanel(controller: supplierController),
                    InventoryReorderPanel(controller: reorderController),
                    InventoryPurchaseOrderPanel(
                      controller: purchaseOrderController,
                    ),
                    InventoryReceiptPanel(
                      controller: receiptController,
                      purchaseOrderController: purchaseOrderController,
                    ),
                    InventoryMovementLedgerPanel(
                      controller: movementController,
                    ),
                    InventoryCountPanel(controller: countController),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
