import 'package:flutter/material.dart';
import 'package:docking/docking.dart';

import '../caldav/caldav_gui.dart';
import '../carta_fedelta/carta_fedelta.gui.dart';
import '../cassa/cassa.gui.dart';
import '../clienti/clienti_gestisci.gui.dart';
import '../coupon/coupon_gestisci/coupon_gestisci_view.gui.dart';
import '../dashboard/dashboard_customization.dart';
import '../dipendenti/dipendenti.gui.dart';
import '../login/gui/login.gui.dart';
import '../notification/notification_service.dart';
import '../ordini/ordini_gestisci/ordini_gestisci.gui.dart';
import '../prodotti/prodotti_crea/prodotti_crea.gui.dart';
import '../prodotti/prodotti_gestisci/prodotti_gestisci.gui.dart';
import '../report/report.gui.dart';
import '../rfid/rfid_gui.dart';
import '../settings/settings.gui.dart';
import '../theme/theme.dart';
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
    final customColors = Theme.of(context).extension<AppColorExtension>()!;

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
        ),
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
              'Versione 1.0.0',
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
        final isDark = theme.brightness == Brightness.dark;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: customColors != null
                    ? [customColors.gradientStart, customColors.gradientEnd]
                    : (isDark
                          ? [
                              AppTheme.darkGradientStart,
                              AppTheme.darkGradientEnd,
                            ]
                          : [
                              AppTheme.lightGradientStart,
                              AppTheme.lightGradientEnd,
                            ]),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Icon(Icons.store, size: 80, color: theme.primaryColor),
                      const SizedBox(height: 20),
                      Text(
                        'Benvenuto nel Sistema di Gestione',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Negozio Abbigliamento',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: customColors?.subtitleColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildAuthStatusCard(context),
                      const SizedBox(height: 24),
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

  Widget _buildAuthStatusCard(BuildContext context) {
    final customColors = Theme.of(context).extension<AppColorExtension>()!;
    final isConnected = homeLogic.isConnected;

    final statusColor = isConnected
        ? customColors.successColor
        : customColors.errorColorStatus;
    final statusIcon = isConnected ? Icons.check_circle : Icons.error;
    final statusText = isConnected
        ? 'Connesso e autenticato'
        : 'Non autenticato - Alcune funzioni non disponibili';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Icon(statusIcon, color: statusColor, size: 20),
            Text(
              statusText,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w500),
            ),
            if (!isConnected)
              ElevatedButton.icon(
                onPressed: onShowLogin,
                icon: const Icon(Icons.login, size: 16),
                label: const Text('Accedi'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCards(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final cards = sections
        .map(
          (section) => _buildQuickActionCard(
            context,
            section: section,
            onTap: () => onOpenSection(section),
          ),
        )
        .toList();

    if (isMobile) {
      return Column(
        children: cards
            .map(
              (card) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: card,
              ),
            )
            .toList(),
      );
    }

    return Wrap(spacing: 16, runSpacing: 16, children: cards);
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required _HomeSection section,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final customColors = theme.extension<AppColorExtension>()!;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: isMobile ? double.infinity : 150,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(section.icon, size: 32, color: section.iconColor),
              const SizedBox(height: 8),
              Text(
                section.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                section.subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: customColors.subtitleColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
