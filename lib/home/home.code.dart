import 'package:flutter/material.dart';

class TabItem {
  final String title;
  final Widget page;
  TabItem({required this.title, required this.page});
}

class HomeController {
  List<TabItem> tabs = [TabItem(title: 'Home', page: Center(child: Text('Home')))];
  TabController? tabController;
  late TickerProvider tickerProvider;

  void setTabController(TickerProvider ticker) {
    tickerProvider = ticker;
    tabController = TabController(length: tabs.length, vsync: tickerProvider);
  }

  void addTab(BuildContext context, String title, Widget page) {
    tabs.add(TabItem(title: title, page: page));
    tabController = TabController(length: tabs.length, vsync: tickerProvider);
    Navigator.pop(context);
    (context as Element).markNeedsBuild();
  }
}