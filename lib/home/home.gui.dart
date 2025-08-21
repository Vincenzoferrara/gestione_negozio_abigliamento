import 'package:flutter/material.dart';
import 'home.code.dart';
import '../login/gui/login.gui.dart';
import '../report/report.gui.dart';
import '../prodotti/prodotti_gestisci/prodotti_gestisci.gui.dart';
import '../prodotti/prodotti_crea/prodotti_crea.gui.dart';
import '../settings/settings.gui.dart';
import '../theme/theme.dart';
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
  }

  void _createHomeDashboard() {
    final homePageDocking = _buildHomePage();
    _homeLogic.setInitialTab('Home', homePageDocking);
  }

  Widget _buildHomePage() {
    final customColors = Theme.of(context).extension<AppColorExtension>()!;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [customColors.gradientStart, customColors.gradientEnd],
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
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Negozio Abbigliamento',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: customColors.subtitleColor,
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
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (_homeLogic.authState) {
      case AuthState.checking:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        statusText = 'Verifica autenticazione...';
        break;
      case AuthState.authenticated:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Connesso e autenticato';
        break;
      case AuthState.notAuthenticated:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        statusText = 'Non autenticato - Alcune funzioni non disponibili';
        break;
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
            if (_homeLogic.authState == AuthState.notAuthenticated) ...[
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
          icon: Icons.shopping_cart,
          title: 'Prodotti',
          subtitle: 'Gestisci inventario',
          onTap: () => _homeLogic.addDockingTab(
            'Prodotti',
            ProdottiGestisciPage(),
            true,
          ),
        ),
        _buildQuickActionCard(
          icon: Icons.add_circle,
          title: 'Nuovo Prodotto',
          subtitle: 'Aggiungi articolo',
          onTap: () => _homeLogic.addDockingTab(
            'Nuovo Prodotto',
            ProdottiCreaPage(),
            true,
          ),
        ),
        _buildQuickActionCard(
          icon: Icons.assessment,
          title: 'Reports',
          subtitle: 'Visualizza statistiche',
          onTap: () => _homeLogic.addDockingTab('Reports', ReportsPage(), true),
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
  }) {
    final customColors = Theme.of(context).extension<AppColorExtension>()!;

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
              Icon(icon, size: 32, color: customColors.cardIconColor),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

  void _showLoginModal() {
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
                  if (_homeLogic.authState != AuthState.checking)
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (_homeLogic.authState == AuthState.notAuthenticated)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    border: Border.all(color: Colors.orange.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Per utilizzare le funzionalità dell\'app è necessario autenticarsi',
                          style: TextStyle(color: Colors.orange.shade800),
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
                      const SnackBar(
                        content: Text('Login effettuato con successo!'),
                        backgroundColor: Colors.green,
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
                  Theme.of(context).primaryColor.withOpacity(0.8),
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
                  // Stato di autenticazione nel drawer
                  Text(
                    _homeLogic.authState == AuthState.authenticated 
                        ? '🟢 Autenticato' 
                        : _homeLogic.authState == AuthState.checking
                            ? '🟡 Verifica...'
                            : '🔴 Non autenticato',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
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
                  icon: Icons.assessment,
                  title: 'Reports',
                  onTap: () {
                    _homeLogic.addDockingTab('Reports', ReportsPage(), true);
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.shopping_cart,
                  title: 'Gestisci Prodotti',
                  onTap: () {
                    _homeLogic.addDockingTab(
                      'Prodotti',
                      ProdottiGestisciPage(),
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
                      ProdottiCreaPage(),
                      true,
                    );
                    Navigator.pop(context);
                  },
                ),
                const Divider(),
                _buildDrawerItem(
                  icon: Icons.settings,
                  title: 'Impostazioni',
                  onTap: () {
                    _homeLogic.addDockingTab('Settings', settingsPage(), true);
                    Navigator.pop(context);
                  },
                ),
                if (_homeLogic.authState == AuthState.authenticated) ...[
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
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  // Widget per il pulsante di autenticazione nell'AppBar migliorato
  Widget _buildAuthButton() {
    switch (_homeLogic.authState) {
      case AuthState.checking:
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(right: 8),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
              const Text(
                'Verifica...',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        );
      case AuthState.authenticated:
        return PopupMenuButton<String>(
          offset: const Offset(0, 45),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.green.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.green,
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
                          color: Colors.green.shade200,
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
              child: const Row(
                children: [
                  Icon(Icons.logout, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Logout', style: TextStyle(color: Colors.red)),
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
      case AuthState.notAuthenticated:
        return TextButton.icon(
          onPressed: _showLoginModal,
          icon: const Icon(Icons.login, size: 16),
          label: const Text('Login'),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            backgroundColor: Colors.red.withOpacity(0.15),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: Colors.red.withOpacity(0.3),
              ),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestione Negozio Abbigliamento',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          _buildAuthButton(),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildDrawer(),
      body: _homeLogic.dockingLayout != null
          ? Docking(layout: _homeLogic.dockingLayout)
          : const Center(child: CircularProgressIndicator()),
    );
  }
}