import 'package:flutter/material.dart';
import 'package:docking/docking.dart';

class HomeLogic {
  late DockingLayout dockingLayout;
  VoidCallback setState;
  final List<DockingItem> docking_tabs = [];

  HomeLogic({required this.setState});

  void addDockingTab(String title, Widget page, bool closable) {
    final newItem = DockingItem(name: title, widget: page, closable: closable);
    docking_tabs.add(newItem);
    updateDockingLayout();
  }

  void updateDockingLayout() {
    dockingLayout = DockingLayout(root: DockingTabs(docking_tabs));
    setState();
  }
}
