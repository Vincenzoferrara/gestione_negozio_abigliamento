import 'package:flutter/material.dart';
//import '../login/primo_avvio/primo_avvio_jwt_setup-dart';
import 'home.code.dart';
import '../log/log.dart';
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
  bool primo_avvio = true;

  @override
  void initState() {
    super.initState();
    _homeLogic = HomeLogic(setState: () => setState(() {}));
    //    if (primo_avvio == true) {
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     primo_avvio_popUp(context);
    //   });
    // }
  }

  //   void primo_avvio_popUp(BuildContext context) {
  //    showDialog(
  //   context: context,
  //   builder: (context) => AlertDialog(
  //     title: const Text("Vai al Wizard"),
  //     content: const Text("Vuoi aprire JWTSetupWizard?"),
  //     actions: [
  //       TextButton(
  //         onPressed: () {
  //           Navigator.of(context).pop(); // chiude il popup
  //           Navigator.push(
  //             context,
  //             MaterialPageRoute(builder: (context) => JWTSetupWizard()),
  //           );
  //         },
  //         child: const Text("Ok"),
  //       ),
  //     ],
  //   ),
  // );
  //   }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _createPageHomeDocking();
      _isInitialized = true;
    }
  }

  void _createPageHomeDocking() {
    final customColors = Theme.of(context).extension<AppColorExtension>()!;

    final homePageDocking = Scaffold(
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
              SizedBox(height: 20),
              Text(
                'Benvenuto nel Sistema di Gestione',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                'Negozio Abbigliamento',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: customColors.subtitleColor,
                ),
              ),
              SizedBox(height: 40),
              _buildQuickActionCards(),
            ],
          ),
        ),
      ),
    );
    _homeLogic.addDockingTab('Home', homePageDocking, false);
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
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32, color: customColors.cardIconColor),
              SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
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

  @override
  void dispose() {
    Logger.log('Disponendo HomeScreen');
    // Decommentare se HomeLogic ha un metodo dispose
    // _homeLogic.dispose();
    super.dispose();
    Logger.log('HomeScreen disposto');
  }

  Widget _buildDrawer() {
    final customColors = Theme.of(context).extension<AppColorExtension>()!;

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
                  SizedBox(height: 10),
                  Text(
                    'Gestione Negozio',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
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
                    _homeLogic.addDockingTab('Login', LoginPage(), true);
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.assessment,
                  title: 'Reports',
                  onTap: () {
                    _homeLogic.addDockingTab('Reports', ReportsPage(), true);
                    Navigator.pop(context);
                  },
                ),
                Divider(),
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
                Divider(),
                _buildDrawerItem(
                  icon: Icons.settings,
                  title: 'Impostazioni',
                  onTap: () {
                    _homeLogic.addDockingTab('Settings', settingsPage(), true);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
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
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gestione Negozio Abbigliamento',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      drawer: _buildDrawer(),
      body: _homeLogic.dockingLayout != null
          ? Docking(layout: _homeLogic.dockingLayout)
          : Center(child: CircularProgressIndicator()),
    );
  }
}
