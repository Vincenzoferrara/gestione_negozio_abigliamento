import 'package:flutter/material.dart';
import '../log/log.dart';
import 'package:docking/docking.dart';

class HomeLogic {
  late DockingLayout dockingLayout;
  VoidCallback setState;
  final List<DockingItem> _tabs = [];

  HomeLogic({required this.setState});

  void initDocking() {
    // Aggiungi una scheda predefinita "Home"
    _tabs.add(DockingItem(name: 'Home', widget: Center(child: Text('Benvenuto nella pagina Home!'))));

    dockingLayout = DockingLayout(
      root: DockingTabs(_tabs),
    );
  }

  void addDockingTab(String title, Widget page) {
    Logger.log('Aggiungendo tab: $title');
    final newItem = DockingItem(name: title, widget: page);
    _tabs.add(newItem);
    dockingLayout.root = DockingTabs(List.from(_tabs));
    setState();
  }

  void removeDockingTab(String title) {
    final idx = _tabs.indexWhere((item) => item.name == title);
    if (idx == -1) return;
    Logger.log('Rimuovendo tab: $title');
    _tabs.removeAt(idx);
    dockingLayout.root = DockingTabs(List.from(_tabs));
    setState();
  }

  void dispose() {
    Logger.log('Disponendo HomeLogic');
  }
}