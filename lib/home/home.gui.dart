import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home.code.dart';
import '../login/gui/login.gui.dart';
import '../dashboard/dashboard_customization.dart';
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
import '../etichette/etichette.gui.dart';
import '../utenti/utenti.gui.dart';
import '../dipendenti/dipendenti.gui.dart';
import '../caldav/caldav_gui.dart';
import 'package:docking/docking.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

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
                      : [
                          AppTheme.lightGradientStart,
                          AppTheme.lightGradientEnd,
                        ]),
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: isMobile ? 40 : 80),
              Icon(
                Icons.store,
                size: isMobile ? 60 : 80,
                color: Theme.of(context).primaryColor,
              ),
              SizedBox(height: isMobile ? 16 : 20),
              Text(
                'Benvenuto nel Sistema di Gestione',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                  fontSize: isMobile ? 20 : null,
                  inherit: true,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isMobile ? 8 : 10),
              Text(
                'Negozio Abbigliamento',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: customColors!.subtitleColor,
                  fontSize: isMobile ? 16 : null,
                  inherit: true,
                ),
              ),
              SizedBox(height: isMobile ? 16 : 20),
              // Mostra stato di autenticazione
              _buildAuthStatusCard(),
              SizedBox(height: isMobile ? 16 : 20),
              _buildQuickActionCards(),
              SizedBox(height: isMobile ? 20 : 40),
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
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w500),
            ),
            if (!isConnected) ...[
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _showLoginModal,
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
          onTap: () =>
              _homeLogic.addDockingTab('Cassa', const CassaPage(), true),
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
          icon: Icons.people_alt,
          title: 'Utenti',
          subtitle: 'Gestione utenti',
          iconColor: Colors.indigo,
          onTap: () =>
              _homeLogic.addDockingTab('Utenti', const UtentiPage(), true),
        ),
        _buildQuickActionCard(
          icon: Icons.people_outline,
          title: 'Dipendenti',
          subtitle: 'Gestisci staff',
          iconColor: Colors.brown,
          onTap: () =>
              _homeLogic.addDockingTab('Dipendenti', DipendentiGui(), true),
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
          icon: Icons.calendar_today,
          title: 'CalDAV',
          subtitle: 'Calendari e task',
          iconColor: Colors.pink,
          onTap: () =>
              _homeLogic.addDockingTab('CalDAV', const CalDavGui(), true),
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
          icon: Icons.insert_chart,
          title: 'Report',
          subtitle: 'Visualizza report',
          iconColor: Colors.teal,
          onTap: () =>
              _homeLogic.addDockingTab('Report', const EtichettePage(), true),
        ),
        _buildQuickActionCard(
          icon: Icons.assessment,
          title: 'Dashboard',
          subtitle: 'Statistiche e Ads',
          iconColor: Colors.amber,
          onTap: () => _homeLogic.addDockingTab(
            'Dashboard',
            const CustomizableDashboardPage(),
            true,
          ),
        ),
        _buildQuickActionCard(
          icon: Icons.settings,
          title: 'Impostazioni',
          subtitle: 'Configura app',
          iconColor: Colors.grey,
          onTap: () => _homeLogic.addDockingTab(
            'Impostazioni',
            const SettingsPage(),
            true,
          ),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    return Card(
      elevation: isMobile ? 2 : 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: isMobile
              ? (screenWidth - 48) / 2
              : isTablet
              ? 140
              : 150,
          height: isMobile ? 100 : null,
          padding: EdgeInsets.all(isMobile ? 16 : 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: isMobile ? 32 : 32,
                color: iconColor ?? theme.primaryColor,
              ),
              SizedBox(height: isMobile ? 8 : 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 13 : null,
                  inherit: true,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (!isMobile) ...[
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: customColors.subtitleColor,
                    inherit: true,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showLoginModal() {
    final customColors = Theme.of(context).extension<AppColorExtension>()!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (isMobile) {
      _showMobileLoginModal(customColors);
    } else {
      _showDesktopLoginModal(customColors);
    }
  }

  void _showMobileLoginModal(AppColorExtension customColors) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle per trascinamento
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Accedi',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Warning message
            if (!_homeLogic.isConnected) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
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
                          'Accedi per utilizzare tutte le funzionalità',
                          style: TextStyle(
                            color: customColors.warningColor,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Login form
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: LoginPage(
                  onLoginSuccess: () {
                    Navigator.of(context).pop();
                    _homeLogic.onLoginSuccess();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Login effettuato!'),
                        backgroundColor: customColors.successColor,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDesktopLoginModal(AppColorExtension customColors) {
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Drawer(
      width: isMobile ? screenWidth * 0.8 : 300,
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
                    radius: isMobile ? 25 : 30,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    child: Icon(
                      Icons.store,
                      size: isMobile ? 25 : 30,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  SizedBox(height: isMobile ? 8 : 10),
                  Text(
                    'Gestione Negozio',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 18 : null,
                      inherit: true,
                    ),
                  ),
                  // Stato di autenticazione nel drawer
                  Text(
                    _homeLogic.isConnected
                        ? '🟢 Autenticato'
                        : '🔴 Non autenticato',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onPrimary.withValues(alpha: 0.8),
                      fontSize: isMobile ? 11 : 12,
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
                // Sezione principale - funzioni più usate su mobile
                if (isMobile) ...[
                  _buildDrawerSectionHeader('Principale'),
                  _buildDrawerItem(
                    icon: Icons.point_of_sale,
                    title: 'Cassa',
                    onTap: () {
                      _homeLogic.bottomNavIndex = 1;
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.shopping_cart,
                    title: 'Prodotti',
                    onTap: () {
                      _homeLogic.bottomNavIndex = 2;
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.receipt_long,
                    title: 'Ordini',
                    onTap: () {
                      _homeLogic.bottomNavIndex = 3;
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.people,
                    title: 'Clienti',
                    onTap: () {
                      _homeLogic.bottomNavIndex = 4;
                      Navigator.pop(context);
                    },
                  ),
                  const Divider(),
                ],

                // Funzioni aggiuntive
                _buildDrawerSectionHeader('Gestione'),
                if (!isMobile) ...[
                  _buildDrawerItem(
                    icon: Icons.people_alt,
                    title: 'Utenti',
                    onTap: () {
                      _homeLogic.addDockingTab(
                        'Utenti',
                        const UtentiPage(),
                        true,
                      );
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.people_outline,
                    title: 'Dipendenti',
                    onTap: () {
                      _homeLogic.addDockingTab(
                        'Dipendenti',
                        DipendentiGui(),
                        true,
                      );
                      Navigator.pop(context);
                    },
                  ),
                ],
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
                    _homeLogic.addDockingTab(
                      'Coupon',
                      const CouponGestisciView(),
                      true,
                    );
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.card_membership,
                  title: 'Carte Fedeltà',
                  onTap: () {
                    _homeLogic.addDockingTab(
                      'Carte Fedeltà',
                      const CartaFedeltaPage(),
                      true,
                    );
                    Navigator.pop(context);
                  },
                ),

                const Divider(),
                _buildDrawerSectionHeader('Strumenti'),
                _buildDrawerItem(
                  icon: Icons.insert_chart,
                  title: 'Report',
                  onTap: () {
                    _homeLogic.addDockingTab(
                      'Report',
                      const EtichettePage(),
                      true,
                    );
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.calendar_today,
                  title: 'CalDAV',
                  onTap: () {
                    _homeLogic.addDockingTab('CalDAV', const CalDavGui(), true);
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.assessment,
                  title: 'Dashboard',
                  onTap: () {
                    _homeLogic.addDockingTab(
                      'Dashboard',
                      const CustomizableDashboardPage(),
                      true,
                    );
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.settings,
                  title: 'Impostazioni',
                  onTap: () {
                    _homeLogic.addDockingTab(
                      'Settings',
                      const SettingsPage(),
                      true,
                    );
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
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Text(
              'Versione 1.0.0',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: isMobile ? 11 : 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerSectionHeader(String title) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isMobile ? 8 : 12,
      ),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: isMobile ? 11 : 12,
          fontWeight: FontWeight.bold,
        ),
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
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
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
                Icon(
                  Icons.logout,
                  size: 16,
                  color: customColors.errorColorStatus,
                ),
                const SizedBox(width: 8),
                Text(
                  'Logout',
                  style: TextStyle(color: customColors.errorColorStatus),
                ),
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
          backgroundColor: customColors.errorColorStatus.withValues(
            alpha: 0.15,
          ),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // Aggiorna lo stato responsive
    _homeLogic.updateResponsiveState(context);

    if (isMobile) {
      return _buildMobileLayout(context, theme, isDark);
    } else {
      return _buildDesktopLayout(context, theme, isDark);
    }
  }

  Widget _buildMobileLayout(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Negozio',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
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
      body: _buildMobileBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
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
                MaterialPageRoute(
                  builder: (context) => const LogViewerScreen(),
                ),
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
              child: Docking(layout: _homeLogic.dockingLayout!),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildMobileBody() {
    switch (_homeLogic.bottomNavIndex) {
      case 0:
        return _buildHomePage();
      case 1:
        return const CassaPage();
      case 2:
        return const ProdottiGestisciPage();
      case 3:
        return const OrdiniGestisciPage();
      case 4:
        return const ClientiGestisciPage();
      default:
        return _buildHomePage();
    }
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _homeLogic.bottomNavIndex,
      onTap: (index) {
        _homeLogic.bottomNavIndex = index;
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.point_of_sale),
          label: 'Cassa',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart),
          label: 'Prodotti',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long),
          label: 'Ordini',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clienti'),
      ],
    );
  }

  /// Crea il tema per il docking adattato al tema Material Design corrente
  TabbedViewThemeData _buildDockingTheme(ThemeData theme, bool isDark) {
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
    );
  }
}
