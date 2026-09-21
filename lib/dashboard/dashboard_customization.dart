import 'dart:convert';

import 'package:dashboard_grid/dashboard_grid.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dashboard.code.dart';
import 'dashboard_charts.dart';

/// The intentionally small set of widgets that have a real data source.
/// Keeping this registry closed prevents users from adding empty placeholders.
enum DashboardTileType {
  salesTrend,
  salesSummary,
  topProducts,
  orderStatuses,
  lowStock,
  customers,
}

class DashboardWidgetConfig {
  const DashboardWidgetConfig({
    required this.id,
    required this.type,
    required this.title,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.visible = true,
  });

  final String id;
  final DashboardTileType type;
  final String title;
  final int x;
  final int y;
  final int width;
  final int height;
  final bool visible;

  DashboardWidgetConfig copyWith({
    int? x,
    int? y,
    int? width,
    int? height,
    bool? visible,
  }) => DashboardWidgetConfig(
    id: id,
    type: type,
    title: title,
    x: x ?? this.x,
    y: y ?? this.y,
    width: width ?? this.width,
    height: height ?? this.height,
    visible: visible ?? this.visible,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'visible': visible,
  };
}

class DashboardLayoutManager {
  static const _prefsKey = 'dashboard_layout_v2';

  static const defaults = [
    DashboardWidgetConfig(
      id: 'sales-summary',
      type: DashboardTileType.salesSummary,
      title: 'Riepilogo vendite',
      x: 0,
      y: 0,
      width: 2,
      height: 1,
    ),
    DashboardWidgetConfig(
      id: 'low-stock',
      type: DashboardTileType.lowStock,
      title: 'Stock da controllare',
      x: 2,
      y: 0,
      width: 2,
      height: 1,
    ),
    DashboardWidgetConfig(
      id: 'sales-trend',
      type: DashboardTileType.salesTrend,
      title: 'Andamento vendite',
      x: 0,
      y: 1,
      width: 2,
      height: 2,
    ),
    DashboardWidgetConfig(
      id: 'order-statuses',
      type: DashboardTileType.orderStatuses,
      title: 'Stati ordini',
      x: 2,
      y: 1,
      width: 2,
      height: 2,
    ),
    DashboardWidgetConfig(
      id: 'top-products',
      type: DashboardTileType.topProducts,
      title: 'Top prodotti',
      x: 0,
      y: 3,
      width: 2,
      height: 2,
    ),
    DashboardWidgetConfig(
      id: 'customers',
      type: DashboardTileType.customers,
      title: 'Clienti',
      x: 2,
      y: 3,
      width: 2,
      height: 2,
    ),
  ];

  static Future<List<DashboardWidgetConfig>> load() async {
    final raw = (await SharedPreferences.getInstance()).getString(_prefsKey);
    if (raw == null) return defaults;
    try {
      final saved = jsonDecode(raw) as List<dynamic>;
      final byId = <String, Map<String, dynamic>>{
        for (final item in saved)
          if (item is Map)
            item['id']?.toString() ?? '': Map<String, dynamic>.from(item),
      };
      return [
        for (final item in defaults)
          if (byId[item.id] case final values?)
            item.copyWith(
              x: values['x'] is int ? values['x'] as int : item.x,
              y: values['y'] is int ? values['y'] as int : item.y,
              width: values['width'] is int
                  ? values['width'] as int
                  : item.width,
              height: values['height'] is int
                  ? values['height'] as int
                  : item.height,
              visible: values['visible'] is bool
                  ? values['visible'] as bool
                  : item.visible,
            )
          else
            item,
      ];
    } catch (_) {
      return defaults;
    }
  }

  static Future<void> save(List<DashboardWidgetConfig> layout) async {
    await (await SharedPreferences.getInstance()).setString(
      _prefsKey,
      jsonEncode(layout.map((tile) => tile.toJson()).toList()),
    );
  }

  static Future<void> reset() async {
    await (await SharedPreferences.getInstance()).remove(_prefsKey);
  }
}

class CustomizableDashboardPage extends StatefulWidget {
  const CustomizableDashboardPage({super.key});

  @override
  State<CustomizableDashboardPage> createState() =>
      _CustomizableDashboardPageState();
}

class _CustomizableDashboardPageState extends State<CustomizableDashboardPage> {
  final DashboardReportGateway _reports = ReportService();
  var _period = PeriodoReport.mese();
  List<DashboardWidgetConfig> _layout = DashboardLayoutManager.defaults;
  DashboardData? _dashboard;
  ReportVenditeDettagliato? _salesReport;
  Object? _error;
  var _loading = true;
  var _editing = false;
  var _requestVersion = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    final requestVersion = ++_requestVersion;
    setState(() {
      _loading = _dashboard == null;
      _error = null;
    });
    try {
      final layoutFuture = DashboardLayoutManager.load();
      final dashboardFuture = _reports.getDashboard(
        periodo: _period,
        forceRefresh: refresh,
      );
      final result = await Future.wait<Object>([layoutFuture, dashboardFuture]);
      if (!mounted || requestVersion != _requestVersion) return;
      setState(() {
        _layout = result[0] as List<DashboardWidgetConfig>;
        _dashboard = result[1] as DashboardData;
        _salesReport = null;
        _loading = false;
      });
      if (_layout.any(
        (tile) => tile.type == DashboardTileType.topProducts && tile.visible,
      )) {
        _loadSalesReport(requestVersion);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _loadSalesReport(int requestVersion) async {
    try {
      final report = await _reports.getReportVendite(periodo: _period);
      if (!mounted || requestVersion != _requestVersion) return;
      setState(() => _salesReport = report);
    } catch (_) {
      // The rest of the dashboard remains useful when this optional tile fails.
    }
  }

  void _changePeriod(PeriodoReport period) {
    setState(() => _period = period);
    _load(refresh: true);
  }

  Future<void> _saveLayout(List<DashboardWidgetConfig> layout) async {
    setState(() => _layout = layout);
    await DashboardLayoutManager.save(layout);
    if (_salesReport == null &&
        layout.any(
          (tile) => tile.type == DashboardTileType.topProducts && tile.visible,
        )) {
      _loadSalesReport(_requestVersion);
    }
  }

  Future<void> _resetLayout() async {
    await DashboardLayoutManager.reset();
    await _saveLayout(DashboardLayoutManager.defaults);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _DashboardToolbar(
              period: _period,
              isEditing: _editing,
              onPeriodChanged: _changePeriod,
              onRefresh: () => _load(refresh: true),
              onEditChanged: () => setState(() => _editing = !_editing),
              onManage: _showTileManager,
              onReset: _resetLayout,
            ),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading && _dashboard == null)
      return const Center(child: CircularProgressIndicator());
    if (_error != null && _dashboard == null) {
      return _DashboardMessage(
        icon: Icons.cloud_off_outlined,
        message: 'Impossibile caricare la dashboard',
        action: FilledButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh),
          label: const Text('Riprova'),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 600 ? 2 : 4;
        final width = ((constraints.maxWidth - (columns + 1) * 8) / columns)
            .clamp(160.0, 440.0);
        return Stack(
          children: [
            _DashboardGrid(
              key: ValueKey('${columns}_${_layout.hashCode}_${_editing}'),
              columns: columns,
              tileWidth: width,
              layout: _layout,
              editing: _editing,
              dashboard: _dashboard,
              salesReport: _salesReport,
              onLayoutChanged: _saveLayout,
            ),
            if (_loading)
              const Positioned(
                top: 8,
                right: 16,
                child: SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _showTileManager() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('Widget dashboard')),
            for (final tile in _layout)
              SwitchListTile(
                title: Text(tile.title),
                value: tile.visible,
                onChanged: (visible) => _saveLayout([
                  for (final item in _layout)
                    item.id == tile.id ? item.copyWith(visible: visible) : item,
                ]),
              ),
          ],
        ),
      ),
    );
  }
}

class _DashboardToolbar extends StatelessWidget {
  const _DashboardToolbar({
    required this.period,
    required this.isEditing,
    required this.onPeriodChanged,
    required this.onRefresh,
    required this.onEditChanged,
    required this.onManage,
    required this.onReset,
  });

  final PeriodoReport period;
  final bool isEditing;
  final ValueChanged<PeriodoReport> onPeriodChanged;
  final VoidCallback onRefresh;
  final VoidCallback onEditChanged;
  final VoidCallback onManage;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text(
              'Dashboard',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            PopupMenuButton<PeriodoReport>(
              tooltip: 'Cambia periodo',
              onSelected: onPeriodChanged,
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: PeriodoReport.oggi(),
                  child: const Text('Oggi'),
                ),
                PopupMenuItem(
                  value: PeriodoReport.settimana(),
                  child: const Text('Questa settimana'),
                ),
                PopupMenuItem(
                  value: PeriodoReport.mese(),
                  child: const Text('Questo mese'),
                ),
                PopupMenuItem(
                  value: PeriodoReport.anno(),
                  child: const Text('Quest’anno'),
                ),
              ],
              child: Chip(
                label: Text(period.descrizione),
                avatar: const Icon(Icons.calendar_today_outlined, size: 18),
              ),
            ),
            IconButton(
              onPressed: onRefresh,
              tooltip: 'Aggiorna',
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              onPressed: onEditChanged,
              tooltip: isEditing ? 'Termina modifica' : 'Modifica disposizione',
              icon: Icon(isEditing ? Icons.check : Icons.drag_indicator),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => value == 'manage' ? onManage() : onReset(),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'manage', child: Text('Gestisci widget')),
                PopupMenuItem(
                  value: 'reset',
                  child: Text('Ripristina disposizione'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardGrid extends StatefulWidget {
  const _DashboardGrid({
    super.key,
    required this.columns,
    required this.tileWidth,
    required this.layout,
    required this.editing,
    required this.dashboard,
    required this.salesReport,
    required this.onLayoutChanged,
  });

  final int columns;
  final double tileWidth;
  final List<DashboardWidgetConfig> layout;
  final bool editing;
  final DashboardData? dashboard;
  final ReportVenditeDettagliato? salesReport;
  final ValueChanged<List<DashboardWidgetConfig>> onLayoutChanged;

  @override
  State<_DashboardGrid> createState() => _DashboardGridState();
}

class _DashboardGridState extends State<_DashboardGrid> {
  late DashboardGrid _grid;

  @override
  void initState() {
    super.initState();
    _buildGrid();
  }

  @override
  void didUpdateWidget(covariant _DashboardGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    // DashboardWidget builders close over the report snapshot; rebuilding the
    // package configuration here keeps tiles current after a refresh, period
    // change, or delayed top-products response.
    if (oldWidget.layout != widget.layout ||
        oldWidget.columns != widget.columns ||
        oldWidget.dashboard != widget.dashboard ||
        oldWidget.salesReport != widget.salesReport) {
      _buildGrid();
    }
  }

  void _buildGrid() {
    _grid = DashboardGrid(maxColumns: widget.columns);
    for (final tile in widget.layout.where((tile) => tile.visible)) {
      final width = tile.width.clamp(1, widget.columns);
      final x = tile.x.clamp(0, widget.columns - width);
      _grid.addWidget(
        DashboardWidget(
          id: tile.id,
          x: x,
          y: tile.y.clamp(0, 100),
          width: width,
          height: tile.height.clamp(1, 3),
          builder: (_) => _DashboardTile(
            tile: tile,
            dashboard: widget.dashboard,
            salesReport: widget.salesReport,
          ),
        ),
      );
    }
    _grid.listener = (changes) {
      final positions = {
        for (final change in changes) change.widgetId: change.to,
      };
      widget.onLayoutChanged([
        for (final tile in widget.layout)
          if (positions[tile.id] case final position?)
            tile.copyWith(x: position.x, y: position.y)
          else
            tile,
      ]);
    };
  }

  @override
  Widget build(BuildContext context) => Dashboard(
    config: _grid,
    editMode: widget.editing,
    widgetWidth: widget.tileWidth,
    widgetHeight: 180,
    widgetSpacing: 8,
    cellPreviewDecoration: TableCellDecoration(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: .08),
      ),
    ),
  );
}

class _DashboardTile extends StatelessWidget {
  const _DashboardTile({
    required this.tile,
    required this.dashboard,
    required this.salesReport,
  });

  final DashboardWidgetConfig tile;
  final DashboardData? dashboard;
  final ReportVenditeDettagliato? salesReport;

  @override
  Widget build(BuildContext context) {
    final content = switch (tile.type) {
      DashboardTileType.salesSummary => _salesSummary(),
      DashboardTileType.salesTrend => _salesTrend(),
      DashboardTileType.topProducts => _topProducts(),
      DashboardTileType.orderStatuses => _orderStatuses(),
      DashboardTileType.lowStock => _lowStock(),
      DashboardTileType.customers => _customers(),
    };
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tile.title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }

  Widget _salesSummary() {
    final sales = dashboard?.vendite;
    if (sales == null) return const _NoData();
    return Wrap(
      spacing: 18,
      runSpacing: 10,
      children: [
        _Metric(
          label: 'Fatturato',
          value: ReportFormatter.formatCurrency(sales.totaleVendite),
        ),
        _Metric(
          label: 'Ordini',
          value: ReportFormatter.formatNumber(sales.numeroOrdini),
        ),
        _Metric(
          label: 'Ticket medio',
          value: ReportFormatter.formatCurrency(sales.ticketMedio),
        ),
        if (!sales.isStabile)
          _Metric(label: 'Confronto', value: sales.variazioneFormatted),
      ],
    );
  }

  Widget _salesTrend() {
    final data = dashboard?.vendite.andamentoGiornaliero;
    if (data == null || data.isEmpty) return const _NoData();
    return SalesLineChart(
      vendite: data,
      animate: false,
      showArea: true,
      title: '',
    );
  }

  Widget _topProducts() {
    final products = salesReport?.topProdotti;
    if (products == null || products.isEmpty) return const _NoData();
    return ListView.separated(
      itemCount: products.length.clamp(0, 5),
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, index) {
        final product = products[index];
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Text(
            '${index + 1}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          title: Text(
            product.titolo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text('${product.quantitaVenduta} unità'),
          trailing: Text(ReportFormatter.formatCurrency(product.totaleVendite)),
        );
      },
    );
  }

  Widget _orderStatuses() {
    final orders = dashboard?.ordini.ordiniPerStato;
    if (orders == null || orders.isEmpty) return const _NoData();
    return OrderStatusPieChart(ordersByStatus: orders, animate: false);
  }

  Widget _lowStock() {
    final products = dashboard?.prodotti.prodottiStockBasso;
    if (products == null || products.isEmpty) return const _NoData();
    return ListView.builder(
      itemCount: products.length.clamp(0, 5),
      itemBuilder: (_, index) {
        final product = products[index];
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.warning_amber_rounded),
          title: Text(
            product['name']?.toString() ?? 'Prodotto',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text('${product['stock_quantity'] ?? 0}'),
        );
      },
    );
  }

  Widget _customers() {
    final customers = dashboard?.clienti;
    if (customers == null) return const _NoData();
    return Wrap(
      spacing: 18,
      runSpacing: 10,
      children: [
        _Metric(
          label: 'Totali',
          value: ReportFormatter.formatNumber(customers.totaleClienti),
        ),
        _Metric(
          label: 'Nuovi',
          value: ReportFormatter.formatNumber(customers.nuoviClienti),
        ),
        _Metric(
          label: 'Attivi',
          value: ReportFormatter.formatNumber(customers.clientiAttivi),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      Text(
        value,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    ],
  );
}

class _NoData extends StatelessWidget {
  const _NoData();
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Dati non disponibili'));
}

class _DashboardMessage extends StatelessWidget {
  const _DashboardMessage({
    required this.icon,
    required this.message,
    required this.action,
  });
  final IconData icon;
  final String message;
  final Widget action;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 44),
        const SizedBox(height: 12),
        Text(message),
        const SizedBox(height: 12),
        action,
      ],
    ),
  );
}
