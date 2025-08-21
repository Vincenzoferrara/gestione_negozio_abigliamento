import 'package:flutter/material.dart';
import 'package:docking/docking.dart';
import '../login/jwt_api/jwt_connect.dart';

enum AuthState { 
  checking,        // Verifica autenticazione in corso
  authenticated,   // Utente autenticato
  notAuthenticated // Utente non autenticato
}

class HomeLogic {
  late DockingLayout dockingLayout;
  VoidCallback setState;
  VoidCallback? showLoginCallback;
  final List<DockingItem> docking_tabs = [];
  final JwtConnect _jwt = JwtConnect();
  
  AuthState _authState = AuthState.checking;
  AuthState get authState => _authState;

  HomeLogic({required this.setState, this.showLoginCallback});

  /// Controlla lo stato di autenticazione all'avvio
  Future<void> checkAuthentication() async {
    _authState = AuthState.checking;
    setState(); // Aggiorna immediatamente per mostrare lo stato "checking"
    
    try {
      final bool isLoggedIn = await _jwt.tryAutoConnect();
      _authState = isLoggedIn ? AuthState.authenticated : AuthState.notAuthenticated;
    } catch (e) {
      _authState = AuthState.notAuthenticated;
    }
    setState();
  }

  /// Chiamato quando il login ha successo
  void onLoginSuccess() {
    _authState = AuthState.authenticated;
    setState();
  }

  /// Esegue il logout e pulisce lo stato
  Future<void> logout() async {
    _authState = AuthState.checking;
    setState(); // Mostra subito lo stato di caricamento
    
    try {
      await _jwt.disconnect();
    } catch (e) {
      // Ignora errori durante il logout
    }
    
    _authState = AuthState.notAuthenticated;
    setState();
  }

  /// Verifica se l'utente è attualmente connesso
  bool get isConnected => _jwt.isConnected;
  
  /// Ottiene l'URL del sito corrente
  String? get currentSiteUrl => _jwt.currentSiteUrl;

  /// Forza la visualizzazione del login (chiamato quando il token scade)
  void forceReauth() {
    _authState = AuthState.notAuthenticated;
    if (showLoginCallback != null) {
      showLoginCallback!();
    }
    setState();
  }

  /// Controlla l'autenticazione prima di eseguire operazioni sensibili
  bool checkAuthForOperation() {
    if (!isConnected) {
      forceReauth();
      return false;
    }
    return true;
  }

  void addDockingTab(String title, Widget page, bool closable) {
    // Non blocchiamo la creazione di tab, ma le operazioni all'interno falliranno se non auth
    if (docking_tabs.any((item) => item.name == title)) return;
    
    final newItem = DockingItem(name: title, widget: page, closable: closable);
    docking_tabs.add(newItem);
    _updateDockingLayout();
  }

  /// Imposta una singola scheda non chiudibile, rimuovendo tutte le altre.
  void setInitialTab(String title, Widget page) {
    docking_tabs.clear();
    final initialItem = DockingItem(name: title, widget: page, closable: false);
    docking_tabs.add(initialItem);
    _updateDockingLayout();
  }

  void _updateDockingLayout() {
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
      dockingLayout = DockingLayout(root: DockingTabs(docking_tabs));
    }
    setState();
  }

  /// Wrapper per operazioni che richiedono autenticazione
  Future<T?> executeAuthenticatedOperation<T>(Future<T> Function() operation) async {
    if (!checkAuthForOperation()) {
      return null;
    }
    
    try {
      return await operation();
    } catch (e) {
      // Se l'errore indica token scaduto/non valido, forza re-auth
      if (e.toString().contains('401') || e.toString().contains('Unauthorized') || 
          e.toString().contains('403') || e.toString().contains('token')) {
        forceReauth();
      }
      rethrow;
    }
  }
}