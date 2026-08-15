import 'package:flutter/material.dart';
import 'package:docking/docking.dart';

import '../caldav/caldav_gui.dart';
import '../carta_fedelta/carta_fedelta.gui.dart';
import '../cassa/cassa.gui.dart';
import '../clienti/clienti_gestisci.gui.dart';
import '../coupon/coupon_gestisci/coupon_gestisci_view.gui.dart';
import '../dashboard/dashboard_customization.dart';
import '../dipendenti/dipendenti.gui.dart';
import '../inventory/inventory.gui.dart';
import '../login/gui/login.gui.dart';
import '../notification/notification_service.dart';
import '../ordini/ordini_gestisci/ordini_gestisci.gui.dart';
import '../prodotti/prodotti_crea/prodotti_crea.gui.dart';
import '../prodotti/prodotti_gestisci/prodotti_gestisci.gui.dart';
import '../report/report.gui.dart';
import '../rfid/rfid_gui.dart';
import '../settings/settings.gui.dart';
import '../theme/theme.dart';
import '../updater/updater.gui.dart';
import '../updater/updater_service.dart';
import '../utenti/utenti.gui.dart';
import 'home.code.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late HomeLogic _homeLogic;
  late final VoidCallback _desktopTabsListener;
  late final List<_HomeSection> _sections;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _homeLogic = HomeLogic(
      setState: () => setState(() {}),
      showLoginCallback: _showLoginModal,
    );
    _desktopTabsListener = () => setState(() {});
    _homeLogic.desktopLayout.addListener(_desktopTabsListener);
    _sections = _buildSections();
    _initializeAuth();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showReleaseNotesAfterUpdate();
    });
  }

  Future<void> _initializeAuth() async {
    await _homeLogic.checkAuthentication();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _homeLogic.setHomePage(title: 'Home', page: _buildHomeTabContent());
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _homeLogic.desktopLayout.removeListener(_desktopTabsListener);
    super.dispose();
  }

  List<_HomeSection> _buildSections() {
    return [
      _HomeSection(
        id: 'cassa',
        title: 'Cassa',
        subtitle: 'Punto vendita',
        icon: Icons.point_of_sale,
        iconColor: Colors.green,
        openMode: HomeTabOpenMode.singleton,
        builder: () => const CassaPage(),
      ),
      _HomeSection(
        id: 'prodotti',
        title: 'Prodotti',
        subtitle: 'Gestisci inventario',
        icon: Icons.shopping_cart,
        iconColor: Colors.blue,
        openMode: HomeTabOpenMode.duplicate,
        builder: () => const ProdottiGestisciPage(),
      ),
      _HomeSection(
        id: 'inventario-mgws',
        title: 'Inventario MGWS',
        subtitle: 'Sync, reconcile, RFID',
        icon: Icons.inventory_2,
        iconColor: AppTheme.primaryColor,
        openMode: HomeTabOpenMode.singleton,
        requiresAuth: false,
        builder: () => const InventoryPage(),
      ),
      _HomeSection(
        id: 'nuovo-prodotto',
        title: 'Nuovo Prodotto',
        subtitle: 'Aggiungi articolo',
        icon: Icons.add_circle,
        iconColor: Colors.purple,
        openMode: HomeTabOpenMode.duplicate,
        builder: () => const ProdottiCreaPage(),
      ),
      _HomeSection(
        id: 'coupon',
        title: 'Coupon',
        subtitle: 'Gestisci sconti',
        icon: Icons.local_offer,
        iconColor: Colors.orange,
        openMode: HomeTabOpenMode.duplicate,
        builder: () => const CouponGestisciView(),
      ),
      _HomeSection(
        id: 'ordini',
        title: 'Ordini',
        subtitle: 'Gestisci ordini',
        icon: Icons.receipt_long,
        iconColor: Colors.red,
        openMode: HomeTabOpenMode.duplicate,
        builder: () => const OrdiniGestisciPage(),
      ),
      _HomeSection(
        id: 'clienti',
        title: 'Clienti',
        subtitle: 'Gestisci clienti',
        icon: Icons.people,
        iconColor: Colors.cyan,
        openMode: HomeTabOpenMode.duplicate,
        builder: () => const ClientiGestisciPage(),
      ),
      _HomeSection(
        id: 'carte-fedelta',
        title: 'Carte Fedeltà',
        subtitle: 'Programma punti',
        icon: Icons.card_membership,
        iconColor: Colors.deepPurple,
        openMode: HomeTabOpenMode.singleton,
        builder: () => const CartaFedeltaPage(),
      ),
      _HomeSection(
        id: 'report',
        title: 'Report',
        subtitle: 'Visualizza report',
        icon: Icons.insert_chart,
        iconColor: Colors.teal,
        openMode: HomeTabOpenMode.singleton,
        requiresAuth: false,
        builder: () => const EtichettePage(),
      ),
      _HomeSection(
        id: 'dashboard',
        title: 'Dashboard',
        subtitle: 'Statistiche e Ads',
        icon: Icons.assessment,
        iconColor: Colors.amber,
        openMode: HomeTabOpenMode.singleton,
        requiresAuth: false,
        builder: () => const CustomizableDashboardPage(),
      ),
      _HomeSection(
        id: 'impostazioni',
        title: 'Impostazioni',
        subtitle: 'Configura app',
        icon: Icons.settings,
        iconColor: Colors.grey,
        openMode: HomeTabOpenMode.singleton,
        requiresAuth: false,
        builder: () => const SettingsPage(),
      ),
      _HomeSection(
        id: 'aggiornamenti',
        title: 'Aggiornamenti',
        subtitle: 'Aggiorna app desktop',
        icon: Icons.system_update,
        iconColor: Colors.lightBlue,
        openMode: HomeTabOpenMode.singleton,
        requiresAuth: false,
        builder: () => const UpdaterPage(),
      ),
      _HomeSection(
        id: 'utenti',
        title: 'Utenti',
        subtitle: 'Gestione utenti',
        icon: Icons.people_alt,
        iconColor: Colors.indigo,
        openMode: HomeTabOpenMode.duplicate,
        builder: () => const UtentiPage(),
      ),
      _HomeSection(
        id: 'caldav',
        title: 'CalDAV',
        subtitle: 'Calendario e contatti',
        icon: Icons.calendar_today,
        iconColor: Colors.brown,
        openMode: HomeTabOpenMode.singleton,
        builder: () => const CalDavGui(),
      ),
      _HomeSection(
        id: 'dipendenti',
        title: 'Dipendenti',
        subtitle: 'Gestisci personale',
        icon: Icons.work,
        iconColor: Colors.pink,
        openMode: HomeTabOpenMode.singleton,
        builder: () => const DipendentiGui(),
      ),
      _HomeSection(
        id: 'rfid',
        title: 'RFID',
        subtitle: 'Scansione tag',
        icon: Icons.nfc,
        iconColor: Colors.blueGrey,
        openMode: HomeTabOpenMode.singleton,
        builder: () => const RFIDTestWidget(),
      ),
    ];
  }

  Widget _buildHomeTabContent() {
    return _HomeLandingPage(
      homeLogic: _homeLogic,
      sections: _sections,
      onOpenSection: _openSection,
      onShowLogin: _showLoginModal,
    );
  }

  bool _isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < homeSmallScreenBreakpoint;
  }

  void _openSection(_HomeSection section) {
    _homeLogic.openSection(
      isSmallScreen: _isSmallScreen(context),
      sectionId: section.id,
      title: section.title,
      page: section.builder(),
      openMode: section.openMode,
      requiresAuth: section.requiresAuth,
    );
  }

  void _showLoginModal() {
    if (_isSmallScreen(context)) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Autenticazione Richiesta'),
              leading: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ),
            body: _buildLoginContent(context),
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Container(
          width: 500,
          height: 600,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Autenticazione Richiesta',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildLoginContent(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginContent(BuildContext context) {
    final customColors = Theme.of(context).extension<AppColorExtension>()!;

    return Padding(
      padding: EdgeInsets.all(_isSmallScreen(context) ? 16 : 0),
      child: Column(
        children: [
          if (!_homeLogic.isConnected)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: customColors.warningColor.withValues(alpha: 0.1),
                border: Border.all(
                  color: customColors.warningColor.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: customColors.warningColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Per utilizzare le funzionalità dell\'app è necessario autenticarsi',
                      style: TextStyle(color: customColors.warningColor),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Expanded(
            child: LoginPage(
              onLoginSuccess: () {
                Navigator.of(context).pop();
                _homeLogic.onLoginSuccess();
                NotificationService.instance.messageBar(
                  'successo',
                  'home',
                  'Login effettuato con successo!',
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    child: Icon(
                      Icons.store,
                      size: 30,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Gestione Negozio',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _homeLogic.isConnected ? 'Autenticato' : 'Non autenticato',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onPrimary.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.home,
                  title: 'Home',
                  onTap: () {
                    Navigator.pop(context);
                    if (_isSmallScreen(context)) {
                      _homeLogic.goHomeMobile();
                    } else {
                      _homeLogic.focusHomeDesktop();
                    }
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.login,
                  title: 'Login',
                  onTap: () {
                    Navigator.pop(context);
                    _showLoginModal();
                  },
                ),
                const Divider(),
                for (final section in _sections)
                  _buildDrawerItem(
                    icon: section.icon,
                    title: section.title,
                    onTap: () {
                      Navigator.pop(context);
                      _openSection(section);
                    },
                  ),
                if (_homeLogic.isConnected) ...[
                  const Divider(),
                  _buildDrawerItem(
                    icon: Icons.logout,
                    title: 'Logout',
                    onTap: () async {
                      Navigator.pop(context);
                      await _homeLogic.logout();
                    },
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _homeLogic.appVersionLabel,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSmallScreen = _isSmallScreen(context);
    final showMobileBack = isSmallScreen && !_homeLogic.isShowingMobileHome;
    final appBarTitle = showMobileBack
        ? (_homeLogic.mobileEntry?.displayTitle ?? 'Gestione Negozio')
        : 'Gestione Negozio Abbigliamento';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          appBarTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        automaticallyImplyLeading: !showMobileBack,
        leading: showMobileBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _homeLogic.goHomeMobile,
              )
            : null,
      ),
      drawer: showMobileBack ? null : _buildDrawer(),
      body: isSmallScreen
          ? (_homeLogic.mobileContent ?? const SizedBox.shrink())
          : MultiSplitViewTheme(
              data: _buildMultiSplitTheme(theme, isDark),
              child: TabbedViewTheme(
                data: _buildTabbedViewTheme(theme, isDark),
                child: Docking(
                  layout: _homeLogic.desktopLayout,
                  draggable: true,
                  maximizableItem: true,
                  maximizableTab: true,
                  maximizableTabsArea: true,
                ),
              ),
            ),
    );
  }

  MultiSplitViewThemeData _buildMultiSplitTheme(ThemeData theme, bool isDark) {
    return MultiSplitViewThemeData(
      dividerThickness: 8,
      dividerPainter: DividerPainters.grooved1(
        color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
        highlightedColor: theme.primaryColor,
        backgroundColor: isDark
            ? theme.colorScheme.surfaceContainerHighest
            : Colors.grey.shade200,
      ),
    );
  }

  TabbedViewThemeData _buildTabbedViewTheme(ThemeData theme, bool isDark) {
    return TabbedViewThemeData(
      tab: TabThemeData(
        textStyle:
            theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black87,
            ) ??
            TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surface : Colors.grey.shade200,
          border: Border(
            right: BorderSide(
              color: isDark
                  ? theme.colorScheme.outline.withValues(alpha: 0.3)
                  : theme.colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        normalButtonColor: isDark ? Colors.white70 : Colors.black54,
        hoverButtonColor: isDark ? Colors.white : Colors.black87,
        closeIcon: IconProvider.data(Icons.close),
        selectedStatus: TabStatusThemeData(
          decoration: BoxDecoration(
            color: theme.primaryColor,
            border: Border(
              right: BorderSide(color: theme.primaryColor, width: 1),
            ),
          ),
          fontColor: theme.colorScheme.onPrimary,
          normalButtonColor: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
          hoverButtonColor: theme.colorScheme.onPrimary,
        ),
        highlightedStatus: TabStatusThemeData(
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.surfaceContainer
                : Colors.grey.shade300,
            border: Border(
              right: BorderSide(
                color: isDark
                    ? theme.colorScheme.outline.withValues(alpha: 0.3)
                    : theme.colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
        ),
      ),
      tabsArea: TabsAreaThemeData(
        color: isDark ? theme.colorScheme.surface : Colors.grey.shade100,
        buttonsAreaDecoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surface : Colors.grey.shade100,
        ),
      ),
      contentArea: ContentAreaThemeData(
        decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
      ),
    )..materialDesignIcons();
  }

  Future<void> _showReleaseNotesAfterUpdate() async {
    final notes = await UpdaterService().releaseNotesForInstalledUpdate();
    if (!mounted || notes == null) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          notes.title.isEmpty
              ? 'Novita versione ${notes.version}'
              : notes.title,
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 420),
          child: SingleChildScrollView(
            child: SelectableText(
              notes.body.isEmpty
                  ? 'Aggiornamento installato. Nessuna nota di rilascio disponibile.'
                  : notes.body,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }
}

class _HomeSection {
  const _HomeSection({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.openMode,
    required this.builder,
    this.requiresAuth = true,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final HomeTabOpenMode openMode;
  final bool requiresAuth;
  final Widget Function() builder;
}

class _HomeLandingPage extends StatelessWidget {
  const _HomeLandingPage({
    required this.homeLogic,
    required this.sections,
    required this.onOpenSection,
    required this.onShowLogin,
  });

  final HomeLogic homeLogic;
  final List<_HomeSection> sections;
  final ValueChanged<_HomeSection> onOpenSection;
  final VoidCallback onShowLogin;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: homeLogic,
      builder: (context, _) {
        final theme = Theme.of(context);
        final customColors = theme.extension<AppColorExtension>();
        final colorScheme = theme.colorScheme;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _landingGradientColors(theme, customColors),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colorScheme.surface.withValues(alpha: 0.92),
                              colorScheme.primaryContainer.withValues(
                                alpha: 0.38,
                              ),
                              (customColors?.variantSelectedBackground ??
                                      colorScheme.surfaceContainerHighest)
                                  .withValues(alpha: 0.42),
                            ],
                          ),
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.16),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withValues(alpha: 0.10),
                              blurRadius: 34,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isCompact = constraints.maxWidth < 720;
                            final heroIcon = Container(
                              width: isCompact ? 76 : 92,
                              height: isCompact ? 76 : 92,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(26),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    colorScheme.primary,
                                    colorScheme.tertiary.withValues(
                                      alpha: 0.86,
                                    ),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withValues(
                                      alpha: 0.28,
                                    ),
                                    blurRadius: 22,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.store,
                                size: isCompact ? 36 : 44,
                                color: colorScheme.onPrimary,
                              ),
                            );
                            final heroCopy = Column(
                              crossAxisAlignment: isCompact
                                  ? CrossAxisAlignment.center
                                  : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Benvenuto nel Sistema di Gestione',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: colorScheme.onSurface,
                                        letterSpacing: -0.4,
                                      ),
                                  textAlign: isCompact
                                      ? TextAlign.center
                                      : TextAlign.start,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Negozio Abbigliamento',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color:
                                        customColors?.subtitleColor ??
                                        colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: isCompact
                                      ? TextAlign.center
                                      : TextAlign.start,
                                ),
                              ],
                            );

                            if (isCompact) {
                              return Column(
                                children: [
                                  heroIcon,
                                  const SizedBox(height: 22),
                                  heroCopy,
                                ],
                              );
                            }

                            return Row(
                              children: [
                                heroIcon,
                                const SizedBox(width: 24),
                                Expanded(child: heroCopy),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildAuthStatusCard(context),
                      const SizedBox(height: 28),
                      _buildQuickActionCards(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Color> _landingGradientColors(
    ThemeData theme,
    AppColorExtension? customColors,
  ) {
    if (customColors != null) {
      return [customColors.gradientStart, customColors.gradientEnd];
    }

    return theme.brightness == Brightness.dark
        ? [AppTheme.darkGradientStart, AppTheme.darkGradientEnd]
        : [AppTheme.lightGradientStart, AppTheme.lightGradientEnd];
  }

  int _quickActionColumnCount(double maxWidth) {
    if (maxWidth < 620) return 1;
    if (maxWidth < 900) return 2;
    if (maxWidth < 1160) return 3;
    return 4;
  }

  Widget _buildAuthStatusCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final customColors = theme.extension<AppColorExtension>()!;
    final isConnected = homeLogic.isConnected;

    final statusColor = isConnected
        ? customColors.successColor
        : customColors.errorColorStatus;
    final statusIcon = isConnected ? Icons.check_circle : Icons.error;
    final statusText = isConnected
        ? 'Connesso e autenticato'
        : 'Non autenticato - Alcune funzioni non disponibili';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: statusColor.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          statusText,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isConnected)
                FilledButton.tonalIcon(
                  onPressed: onShowLogin,
                  icon: const Icon(Icons.login, size: 18),
                  label: const Text('Accedi'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuickActionCards(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 18.0;
        final columns = _quickActionColumnCount(constraints.maxWidth);
        final cardWidth = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final section in sections)
              _buildQuickActionCard(
                context,
                section: section,
                width: cardWidth,
                onTap: () => onOpenSection(section),
              ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required _HomeSection section,
    required double width,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final customColors = theme.extension<AppColorExtension>()!;

    return SizedBox(
      width: width,
      child: Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        color: Colors.transparent,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.surface.withValues(alpha: 0.94),
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.68),
                ],
              ),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.14),
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: section.iconColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: section.iconColor.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Icon(
                          section.icon,
                          size: 28,
                          color: section.iconColor,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.72,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    section.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    section.subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: customColors.subtitleColor,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
