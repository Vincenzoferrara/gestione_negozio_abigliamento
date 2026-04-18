import 'package:flutter/material.dart';
import 'package:docking/docking.dart';
import '../login/gui/login.code.dart';

class HomeLogic {
  DockingLayout? dockingLayout;
  VoidCallback setState;
  final List<DockingItem> docking_tabs = [];

  // Stack di navigazione per la modalità mobile
  final List<int> _navigationStack = [0]; // Inizia con la home (index 0)
  int get currentPageIndex => _navigationStack.isNotEmpty ? _navigationStack.last : 0;
  bool get canGoBack => _navigationStack.length > 1;

  // Callback per mostrare login
  final VoidCallback? showLoginCallback;

  HomeLogic({required this.setState, this.showLoginCallback});

  /// Verifica se l'utente è connesso
  bool get isConnected => loginCode.isConnected;

  /// URL del sito corrente
  String? get currentSiteUrl => loginCode.cachedSiteUrl;

  /// Controlla l'autenticazione all'avvio
  Future<void> checkAuthentication() async {
    try {
      final success = await loginCode.tryAutoLogin();
      if (success) {
        // Verifica che la connessione funzioni effettivamente
        final connectionWorking = await loginCode.testConnection();
        if (!connectionWorking) {
          // Se il test di connessione fallisce, disconnetti
          await loginCode.logout();
        }
      }
      setState();
    } catch (e) {
      // In caso di errore, assicurati che l'utente sia disconnesso
      await loginCode.logout();
      setState();
    }
  }

  /// Chiamato dopo login riuscito
  void onLoginSuccess() {
    setState(); // Aggiorna l'UI
  }

  /// Esegue il logout
  Future<void> logout() async {
    await loginCode.logout();
    setState(); // Aggiorna l'UI
  }

  void addDockingTab(String title, Widget page, bool closable, {bool isMobile = false}) {
    // Controlla se l'utente è connesso prima di aprire una tab
    // Eccezione per Dashboard, Impostazioni e Report che hanno il proprio controllo di autenticazione
    final allowedWithoutAuth = ['Dashboard', 'Reports', 'Impostazioni', 'Report'];
    if (!isConnected && showLoginCallback != null && !allowedWithoutAuth.contains(title)) {
      showLoginCallback!();
      return;
    }

    // Permetti duplicati aggiungendo un numero incrementale
    String uniqueTitle = title;
    int counter = 1;

    // Conta quante tab con lo stesso titolo base esistono già
    while (docking_tabs.any((item) => item.name == uniqueTitle)) {
      counter++;
      uniqueTitle = '$title #$counter';
    }

    // Wrappa il widget in un Container con chiave unica per evitare problemi di disposed
    final wrappedPage = Container(
      key: ValueKey(uniqueTitle),
      child: page,
    );

    final newItem = DockingItem(name: uniqueTitle, widget: wrappedPage, closable: closable);
    docking_tabs.add(newItem);

    // Se siamo in modalità mobile, aggiungi allo stack di navigazione
    if (isMobile) {
      _navigationStack.add(docking_tabs.length - 1);
    }

    _updateDockingLayout(focusLast: true); // Focus sul nuovo tab
  }

  /// Imposta una singola scheda non chiudibile, rimuovendo tutte le altre.
  void setInitialTab(String title, Widget page) {
    docking_tabs.clear();

    // Wrappa il widget con chiave unica
    final wrappedPage = Container(
      key: ValueKey(title),
      child: page,
    );

    final initialItem = DockingItem(name: title, widget: wrappedPage, closable: false);
    docking_tabs.add(initialItem);
    _updateDockingLayout();
  }

  void _updateDockingLayout({bool focusLast = false}) {
    // Rimuovi eventuali tab disposed prima di aggiornare il layout
    docking_tabs.removeWhere((item) => item.disposed);

    if (docking_tabs.isEmpty) {
      // Se non ci sono più schede, ricrea la scheda Home di default.
      final homeItem = DockingItem(
        name: 'Home',
        widget: const Center(
          child: Text('Nessuna scheda aperta. Apri una sezione dal menu.')
        ),
        closable: false,
      );
      dockingLayout = DockingLayout(root: DockingTabs([homeItem]));
    } else {
      // Crea le tabs
      final tabs = DockingTabs(docking_tabs);

      // Se focusLast è true, imposta l'ultimo tab aggiunto come selezionato
      if (focusLast) {
        tabs.selectedIndex = docking_tabs.length - 1;
      }

      dockingLayout = DockingLayout(root: tabs);
    }
    setState();
  }

  /// Torna indietro nella navigazione mobile
  void goBack() {
    if (canGoBack) {
      _navigationStack.removeLast();

      // Rimuovi anche la tab dal docking se era closable
      if (docking_tabs.isNotEmpty && docking_tabs.length > currentPageIndex) {
        if (docking_tabs[currentPageIndex + 1].closable) {
          docking_tabs.removeAt(currentPageIndex + 1);
        }
      }

      _updateDockingLayout(focusLast: false);
    }
  }

  /// Naviga a una pagina specifica (per modalità mobile)
  void navigateToPage(int index) {
    if (index >= 0 && index < docking_tabs.length) {
      _navigationStack.add(index);
      _updateDockingLayout(focusLast: false);
    }
  }

  /// Chiamato quando un tab viene chiuso dal docking
  void onTabClosed(DockingItem item) {
    // Rimuovi l'item dalla lista se presente e non ancora disposed
    docking_tabs.remove(item);

    // Aggiorna il layout per riflettere i cambiamenti
    _updateDockingLayout();
  }
}