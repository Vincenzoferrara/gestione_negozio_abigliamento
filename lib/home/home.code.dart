import 'package:flutter/material.dart';

enum TabOrientation { horizontal, vertical }

class HomeLogic {
  List<MyTab> myTabs = [];
  List<Widget> myTabViews = [];
  late TabController tabController;
  late TickerProvider vsync;
  VoidCallback setState;
  TabOrientation orientation = TabOrientation.horizontal;

  HomeLogic({required this.vsync, required this.setState});

  void initTabs() {
    // Non aggiungere nessun tab inizialmente
  }

  void addTab(String title, Widget page, {bool closable = true, bool allowDuplicates = true}) {
    // Se non permettiamo duplicati, controlla se esiste già
    if (!allowDuplicates) {
      int existingIndex = myTabs.indexWhere((tab) => tab.title == title);
      if (existingIndex != -1) {
        // Se esiste, selezionalo
        if (myTabs.isNotEmpty) {
          tabController.animateTo(existingIndex);
        }
        return;
      }
    } else {
      // Se permettiamo duplicati, aggiungi un numero progressivo se necessario
      String finalTitle = title;
      int count = myTabs.where((tab) => tab.title.startsWith(title)).length;
      if (count > 0) {
        finalTitle = "$title (${count + 1})";
      }
      title = finalTitle;
    }

    myTabs.add(MyTab(title: title, closable: closable));
    myTabViews.add(page);
    
    // Gestione del TabController senza ricrearlo continuamente
    if (myTabs.length == 1) {
      // Primo tab: crea il controller
      tabController = TabController(
        length: myTabs.length, 
        vsync: vsync,
        initialIndex: 0,
      );
    } else {
      // Tab successivi: dispone del vecchio e crea il nuovo con un delay
      TabController oldController = tabController;
      
      tabController = TabController(
        length: myTabs.length, 
        vsync: vsync,
        initialIndex: myTabs.length - 1,
      );
      
      // Dispone del vecchio controller dopo un breve delay
      Future.delayed(Duration(milliseconds: 100), () {
        oldController.dispose();
      });
    }
    
    setState();
  }

  void removeTab(int index) {
    if (myTabs.length <= 1 || !myTabs[index].closable) {
      return;
    }

    int currentIndex = tabController.index;
    
    myTabs.removeAt(index);
    myTabViews.removeAt(index);
    
    // Determina il nuovo indice prima di ricreare il controller
    int newIndex;
    if (currentIndex >= index && currentIndex > 0) {
      newIndex = currentIndex - 1;
    } else if (currentIndex >= myTabs.length) {
      newIndex = myTabs.length - 1;
    } else {
      newIndex = currentIndex;
    }
    
    newIndex = newIndex.clamp(0, myTabs.length - 1);
    
    // Gestione sicura del TabController
    TabController oldController = tabController;
    
    tabController = TabController(
      length: myTabs.length,
      vsync: vsync,
      initialIndex: newIndex,
    );
    
    setState();
    
    // Dispone del vecchio controller dopo un delay
    Future.delayed(Duration(milliseconds: 100), () {
      oldController.dispose();
    });
  }

  void toggleOrientation() {
    orientation = orientation == TabOrientation.horizontal 
        ? TabOrientation.vertical 
        : TabOrientation.horizontal;
    setState();
  }

  void dispose() {
    if (myTabs.isNotEmpty) {
      tabController.dispose();
    }
  }
}

class MyTab {
  final String title;
  final bool closable;

  MyTab({required this.title, this.closable = true});
}