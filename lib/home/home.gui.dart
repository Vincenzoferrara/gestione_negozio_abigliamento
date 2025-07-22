import 'package:flutter/material.dart';
import 'home.code.dart';
import '../log/log.dart'; // Importa il logger

import '../login/login.gui.dart';
import '../report/report.gui.dart';
import '../prodotti/prodotti_gestisci/prodotti_gestisci.gui.dart';
import '../prodotti/prodotti_crea/prodotti_crea.gui.dart';
import 'package:docking/docking.dart';

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestione Negozio Abbigliamento',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: HomeScreen(),
      routes: {
        '/login': (context) => LoginPage(),
        '/prodotti/crea': (context) => ProdottiCreaPage(),
      },
    );
  }
}


class HomeScreen extends StatefulWidget {
  HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late HomeLogic _homeLogic;

  @override
  void initState() {
    super.initState();
    Logger.log('Inizializzando HomeScreen');
    _homeLogic = HomeLogic(setState: () => setState(() {}));
    _homeLogic.initDocking();
    Logger.log('HomeScreen inizializzato');
  }

  @override
  void dispose() {
    Logger.log('Disponendo HomeScreen');
    _homeLogic.dispose();
    super.dispose();
    Logger.log('HomeScreen disposto');
  }


  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.redAccent),
            child: Text(
              'My App Menu',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: Icon(Icons.assessment),
            title: Text('Reports'),
            onTap: () {
              Logger.log('Cliccato su Reports nel menu');
              _homeLogic.addDockingTab('Reports', ReportsPage());
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.shopping_cart),
            title: Text('Prodotti'),
            onTap: () {
              Logger.log('Cliccato su Prodotti nel menu');
              _homeLogic.addDockingTab('Prodotti', ProdottiGestisciPage());
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.add),
            title: Text('Nuovo Prodotto'),
            onTap: () {
              Logger.log('Cliccato su Nuovo Prodotto nel menu');
              _homeLogic.addDockingTab('Nuovo Prodotto', ProdottiCreaPage());
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            onTap: () {
              Logger.log('Cliccato su Settings nel menu');
              _homeLogic.addDockingTab('Settings', Center(child: Text('Settings Page')));
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.login),
            title: Text('Login'),
            onTap: () {
              Logger.log('Cliccato su Login nel menu');
              Navigator.pushNamed(context, '/login');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestione Negozio Abbigliamento'),
        backgroundColor: Colors.redAccent,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: _buildDrawer(),
      body: Docking(
  layout: _homeLogic.dockingLayout,
      ),
    );
  }
}