import 'package:flutter/material.dart';
import 'home.code.dart';

import '../login/login.gui.dart';
import '../report/report.gui.dart';
import '../prodotti/prodotti_gestisci/prodotti_gestisci.gui.dart';
import '../prodotti/prodotti_crea/prodotti_crea.gui.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final List<Tab> myTabs = [];
  final List<Widget> myTabViews = [];

  @override
  void initState() {
    super.initState();

    // Inizializza i tab con una scheda Home di default
    myTabs.add(Tab(text: 'Home'));
    myTabViews.add(Center(child: Text('Benvenuto nella Home!')));

    _tabController = TabController(length: myTabs.length, vsync: this);
  }

  void addTab(String title, Widget page) {
    setState(() {
      myTabs.add(Tab(text: title));
      myTabViews.add(page);
      _tabController.dispose();
      _tabController = TabController(length: myTabs.length, vsync: this);
      _tabController.index = myTabs.length - 1; // Seleziona il tab appena aggiunto
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My App'),
        backgroundColor: Colors.redAccent,
        bottom: TabBar(
          controller: _tabController,
          tabs: myTabs,
          isScrollable: true,
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
            child: Text('Login', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      drawer: Drawer(
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
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () {
                addTab('Home', Center(child: Text('Benvenuto nella Home!')));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.assessment),
              title: Text('Reports'),
              onTap: () {
                addTab('Reports', ReportsPage());
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.shopping_cart),
              title: Text('Prodotti'),
              onTap: () {
                addTab('Prodotti', ProdottiGestisciPage());
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.add),
              title: Text('Nuovo Prodotto'),
              onTap: () {
                addTab('Nuovo Prodotto', ProdottiCreaPage());
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: myTabViews,
      ),
    );
  }
}