import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home.code.dart';
import '../login/gui/login.gui.dart';
import '../report/report.gui.dart';
import '../prodotti/prodotti_gestisci/prodotti_gestisci.gui.dart';
import '../prodotti/prodotti_crea/prodotti_crea.gui.dart';
import '../settings/settings.gui.dart';
import '../settings/theme/theme_settings.dart';
import '../theme/theme.dart';
import '../log_viewer/log_viewer.gui.dart';
import '../cassa/cassa.gui.dart';
import '../coupon/coupon_gestisci/coupon_gestisci_view.gui.dart';
import '../ordini/ordini_gestisci/ordini_gestisci.gui.dart';
import '../clienti/clienti_gestisci.gui.dart';
import '../carta_fedelta/carta_fedelta.gui.dart';
import 'package:docking/docking.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late HomeLogic _homeLogic;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _homeLogic = HomeLogic(
      setState: () => setState(() {}),
      showLoginCallback: _showLoginModal,
    );
    
    // Avvia il controllo dell'autenticazione immediatamente
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    await _homeLogic.checkAuthentication();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _createHomeDashboard();
      _isInitialized = true;
    }
    // NON ricreare il docking, altrimenti perdi le tab aperte!
    // Il tema si aggiorna automaticamente tramite rebuild
  }

  void _createHomeDashboard() {
    // Usa StatefulBuilder per permettere rebuild della home page
    final homePageDocking = StatefulBuilder(
      builder: (context, setStateHome) {
        return _buildHomePage();
      },
    );
    _homeLogic.setInitialTab('Home', homePageDocking);
  }

  Widget _buildHomePage() {
    final theme = Theme.of(context);
    final customColors = theme.extension<AppColorExtension>();
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: customColors != null
              ? [customColors.gradientStart, customColors.gradientEnd]
              : (isDark
                  ? [AppTheme.darkGradientStart, AppTheme.darkGradientEnd]
                  : [AppTheme.lightGradientStart, AppTheme.lightGradientEnd]),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.store,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 20),
              Text(
                'Benvenuto nel Sistema di Gestione',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                  inherit: true,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Negozio Abbigliamento',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: customColors!.subtitleColor,
                  inherit: true,
                ),
              ),
              const SizedBox(height: 20),
              // Mostra stato di autenticazione
              _buildAuthStatusCard(),
              const SizedBox(height: 20),
              _buildQuickActionCards(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthStatusCard() {
    final customColors = Theme.of(context).extension<AppColorExtension>()!;
    final isConnected = _homeLogic.isConnected;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isConnected) {
      statusColor = customColors.successColor;
      statusIcon = Icons.check_circle;
      statusText = 'Connesso e autenticato';
    } else {
      statusColor = customColors.errorColorStatus;
      statusIcon = Icons.error;
      statusText = 'Non autenticato - Alcune funzioni non disponibili';
    }

    return Card(
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(statusIcon, color: statusColor, size: 20),
            const SizedBox(width: 8),
            Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (!isConnected) ...[
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _showLoginModal,
                icon: const Icon(Icons.login, size: 16),
                label: const Text('Accedi'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCards() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildQuickActionCard(
          icon: Icons.point_of_sale,
          title: 'Cassa',
          subtitle: 'Punto vendita',
          iconColor: Colors.green,
          onTap: () => _homeLogic.addDockingTab(
            'Cassa',
            const CassaPage(),
            true,
          ),
        ),
        _buildQuickActionCard(
          icon: Icons.shopping_cart,
          title: 'Prodotti',
          subtitle: 'Gestisci inventario',
          iconColor: Colors.blue,
          onTap: () => _homeLogic.addDockingTab(
            'Prodotti',
            const ProdottiGestisciPage(),
            true,
          ),
        ),
        _buildQuickActionCard(
          icon: Icons.add_circle,
          title: 'Nuovo Prodotto',
          subtitle: 'Aggiungi articolo',
          iconColor: Colors.purple,
          onTap: () => _homeLogic.addDockingTab(
            'Nuovo Prodotto',
            const ProdottiCreaPage(),
            true,
          ),
        ),
        _buildQuickActionCard(
          icon: Icons.local_offer,
          title: 'Coupon',
          subtitle: 'Gestisci sconti',
          iconColor: Colors.orange,
          onTap: () => _homeLogic.addDockingTab(
            'Coupon',
            const CouponGestisciView(),
            true,
          ),
        ),
        _buildQuickActionCard(
          icon: Icons.receipt_long,
          title: 'Ordini',
          subtitle: 'Gestisci ordini',
          iconColor: Colors.red,
          onTap: () => _homeLogic.addDockingTab(
            'Ordini',
            const OrdiniGestisciPage(),
            true,
          ),
        ),
        _buildQuickActionCard(
          icon: Icons.people,
          title: 'Clienti',
          subtitle: 'Gestisci clienti',
          iconColor: Colors.cyan,
          onTap: () => _homeLogic.addDockingTab(
            'Clienti',
            const ClientiGestisciPage(),
            true,
          ),
        ),
        _buildQuickActionCard(
          icon: Icons.card_membership,
          title: 'Carte Fedeltà',
          subtitle: 'Programma punti',
          iconColor: Colors.deepPurple,
          onTap: () => _homeLogic.addDockingTab(
            'Carte Fedeltà',
            const CartaFedeltaPage(),
            true,
          ),
        ),
        _buildQuickActionCard(
          icon: Icons.assessment,
          title: 'Reports',
          subtitle: 'Visualizza statistiche',
          iconColor: Colors.amber,
          onTap: () => _homeLogic.addDockingTab('Reports', const ReportsPage(), true),
        ),
        _buildQuickActionCard(
          icon: Icons.settings,
          title: 'Impostazioni',
          subtitle: 'Configura app',
          iconColor: Colors.grey,
          onTap: () => _homeLogic.addDockingTab('Impostazioni', const SettingsPage(), true),
        ),
        _buildQuickActionCard(
          icon: Icons.login,
          title: 'Login',
          subtitle: 'Autenticazione',
          onTap: _showLoginModal,
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);
    final customColors = theme.extension<AppColorExtension>()!;

    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 150,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32, color: iconColor ?? theme.primaryColor),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(
                      fontWeight: FontWeight.bold,
                      inherit: true,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: customColors.subtitleColor,
                      inherit: true,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLoginModal() {
    final customColors = Theme.of(context).extension<AppColorExtension>()!;

    showDialog(
      context: context,
      barrierDismissible: false, // Non può essere chiuso cliccando fuori
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
                    border: Border.all(color: customColors.warningColor.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: customColors.warningColor, size: 20),
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
                    // Mostra un messaggio di successo
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Login effettuato con successo!'),
                        backgroundColor: customColors.successColor,
                      ),
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
                          inherit: true,
                        ),
                  ),
                  // Stato di autenticazione nel drawer
                  Text(
                    _homeLogic.isConnected
                        ? '🟢 Autenticato'
                        : '🔴 Non autenticato',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
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
                  icon: Icons.login,
                  title: 'Login',
                  onTap: () {
                    Navigator.pop(context);
                    _showLoginModal();
                  },
                ),
                const Divider(),
                _buildDrawerItem(
                  icon: Icons.point_of_sale,
                  title: 'Cassa',
                  onTap: () {
                    _homeLogic.addDockingTab('Cassa', const CassaPage(), true);
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.shopping_cart,
                  title: 'Gestisci Prodotti',
                  onTap: () {
                    _homeLogic.addDockingTab(
                      'Prodotti',
                      const ProdottiGestisciPage(),
                      true,
                    );
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.add_circle_outline,
                  title: 'Nuovo Prodotto',
                  onTap: () {
                    _homeLogic.addDockingTab(
                      'Nuovo Prodotto',
                      const ProdottiCreaPage(),
                      true,
                    );
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.local_offer,
                  title: 'Coupon',
                  onTap: () {
                    _homeLogic.addDockingTab('Coupon', const CouponGestisciView(), true);
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.receipt_long,
                  title: 'Ordini',
                  onTap: () {
                    _homeLogic.addDockingTab('Ordini', const OrdiniGestisciPage(), true);
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.people,
                  title: 'Clienti',
                  onTap: () {
                    _homeLogic.addDockingTab('Clienti', const ClientiGestisciPage(), true);
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.card_membership,
                  title: 'Carte Fedeltà',
                  onTap: () {
                    _homeLogic.addDockingTab('Carte Fedeltà', const CartaFedeltaPage(), true);
                    Navigator.pop(context);
                  },
                ),
                const Divider(),
                _buildDrawerItem(
                  icon: Icons.assessment,
                  title: 'Reports',
                  onTap: () {
                    _homeLogic.addDockingTab('Reports', const ReportsPage(), true);
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.settings,
                  title: 'Impostazioni',
                  onTap: () {
                    _homeLogic.addDockingTab('Settings', const SettingsPage(), true);
                    Navigator.pop(context);
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
          Container(
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

  // Widget per il pulsante di autenticazione nell'AppBar migliorato
  Widget _buildAuthButton() {
    final customColors = Theme.of(context).extension<AppColorExtension>()!;

    if (_homeLogic.isConnected) {
      // Utente autenticato
      return PopupMenuButton<String>(
          offset: const Offset(0, 45),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: customColors.successColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: customColors.successColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: customColors.successColor,
                  child: Icon(
                    Icons.person,
                    size: 16,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Autenticato',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    if (_homeLogic.isConnected)
                      Text(
                        '● Online',
                        style: TextStyle(
                          fontSize: 10,
                          color: customColors.successColor.withValues(alpha: 0.8),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 16,
                ),
              ],
            ),
          ),
          itemBuilder: (context) => [
            PopupMenuItem(
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Stato: Connesso'),
                      if (_homeLogic.currentSiteUrl != null)
                        Text(
                          _homeLogic.currentSiteUrl!,
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                    ],
                  ),
                ],
              ),
              onTap: () {},
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 16, color: customColors.errorColorStatus),
                  const SizedBox(width: 8),
                  Text('Logout', style: TextStyle(color: customColors.errorColorStatus)),
                ],
              ),
            ),
          ],
          onSelected: (value) async {
            if (value == 'logout') {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Sei sicuro di voler uscire?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Annulla'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
              
              if (shouldLogout == true) {
                await _homeLogic.logout();
              }
            }
          },
        );
    } else {
      // Utente non autenticato
      return TextButton.icon(
        onPressed: _showLoginModal,
        icon: const Icon(Icons.login, size: 16),
        label: const Text('Login'),
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          backgroundColor: customColors.errorColorStatus.withValues(alpha: 0.15),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: customColors.errorColorStatus.withValues(alpha: 0.3),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestione Negozio Abbigliamento',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          // Pulsante Log Viewer
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bug_report, color: Colors.red, size: 20),
            ),
            tooltip: 'Visualizza Log',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const LogViewerScreen()),
              );
            },
          ),
          // Pulsante Toggle Tema
          Consumer<ThemeSettings>(
            builder: (context, themeSettings, child) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return IconButton(
                icon: Icon(
                  isDark ? Icons.wb_sunny : Icons.nightlight_round,
                  color: isDark ? Colors.amber : Colors.indigo,
                ),
                tooltip: 'Cambia Tema',
                onPressed: () => themeSettings.toggleTheme(),
              );
            },
          ),
          _buildAuthButton(),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildDrawer(),
      body: _homeLogic.dockingLayout != null
          ? TabbedViewTheme(
              data: _buildDockingTheme(theme, isDark),
              child: Docking(layout: _homeLogic.dockingLayout),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  /// Crea il tema per il docking adattato al tema Material Design corrente
  TabbedViewThemeData _buildDockingTheme(ThemeData theme, bool isDark) {
    return TabbedViewThemeData(
      tab: TabThemeData(
        textStyle: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white70 : Colors.black87,
        ) ?? TextStyle(
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
              right: BorderSide(
                color: theme.primaryColor,
                width: 1,
              ),
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
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
        ),
      ),
    );
  }
}