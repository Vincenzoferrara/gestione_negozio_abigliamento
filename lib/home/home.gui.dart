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
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late HomeLogic _homeLogic;

  @override
  void initState() {
    super.initState();
    _homeLogic = HomeLogic(vsync: this, setState: () => setState(() {}));
    _homeLogic.initTabs();
  }

  @override
  void dispose() {
    _homeLogic.dispose();
    super.dispose();
  }

  Widget _buildTabBar() {
    if (_homeLogic.myTabs.isEmpty) return SizedBox.shrink();

    return TabBar(
      controller: _homeLogic.tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      tabs: _homeLogic.myTabs.asMap().entries.map((entry) {
        int index = entry.key;
        MyTab tab = entry.value;
        
        return Tab(
          child: Container(
            constraints: BoxConstraints(minWidth: 120),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Text(
                    tab.title,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (tab.closable) ...[
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _homeLogic.removeTab(index),
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.1),
                      ),
                      child: Icon(Icons.close, size: 14),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTabContent() {
    if (_homeLogic.myTabViews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store,
              size: 80,
              color: Colors.redAccent.withOpacity(0.5),
            ),
            SizedBox(height: 20),
            Text(
              'Benvenuto nella Gestione Negozio',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Seleziona una sezione dal menu per iniziare',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _homeLogic.tabController,
      children: _homeLogic.myTabViews,
    );
  }

  Widget _buildHorizontalLayout() {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestione Negozio Abbigliamento'),
        backgroundColor: Colors.redAccent,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: _buildTabBar(),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_homeLogic.orientation == TabOrientation.horizontal 
                ? Icons.view_agenda 
                : Icons.view_day),
            onPressed: _homeLogic.toggleOrientation,
            tooltip: _homeLogic.orientation == TabOrientation.horizontal 
                ? 'Visualizzazione verticale' 
                : 'Visualizzazione orizzontale',
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _buildTabContent(),
    );
  }

  Widget _buildVerticalLayout() {
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
        actions: [
          IconButton(
            icon: Icon(_homeLogic.orientation == TabOrientation.horizontal 
                ? Icons.view_agenda 
                : Icons.view_day),
            onPressed: _homeLogic.toggleOrientation,
            tooltip: _homeLogic.orientation == TabOrientation.horizontal 
                ? 'Visualizzazione verticale' 
                : 'Visualizzazione orizzontale',
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Row(
        children: [
          // Pannello laterale con i tab
          Container(
            width: 200,
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey[300]!)),
            ),
            child: _homeLogic.myTabs.isNotEmpty
                ? Column(
                    children: [
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                        ),
                        child: Center(
                          child: Text(
                            'Schede Aperte',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _homeLogic.myTabs.length,
                          itemBuilder: (context, index) {
                            MyTab tab = _homeLogic.myTabs[index];
                            bool isSelected = _homeLogic.tabController.index == index;
                            
                            return Container(
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.redAccent.withOpacity(0.1) : null,
                                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                              ),
                              child: ListTile(
                                dense: true,
                                title: Text(
                                  tab.title,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Colors.redAccent : null,
                                  ),
                                ),
                                trailing: tab.closable
                                    ? IconButton(
                                        icon: Icon(Icons.close, size: 16),
                                        onPressed: () => _homeLogic.removeTab(index),
                                      )
                                    : null,
                                onTap: () {
                                  if (_homeLogic.tabController.length > index) {
                                    _homeLogic.tabController.animateTo(index);
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Text(
                      'Nessuna scheda aperta',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
          ),
          // Contenuto principale
          Expanded(
            child: _buildTabContent(),
          ),
        ],
      ),
    );
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
              _homeLogic.addTab('Reports', ReportsPage());
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.shopping_cart),
            title: Text('Prodotti'),
            onTap: () {
              _homeLogic.addTab('Prodotti', ProdottiGestisciPage());
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.add),
            title: Text('Nuovo Prodotto'),
            onTap: () {
              _homeLogic.addTab('Nuovo Prodotto', ProdottiCreaPage());
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            onTap: () {
              _homeLogic.addTab('Settings', Center(child: Text('Settings Page')));
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.login),
            title: Text('Login'),
            onTap: () {
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
    return _homeLogic.orientation == TabOrientation.horizontal
        ? _buildHorizontalLayout()
        : _buildVerticalLayout();
  }
}