import 'package:docking/docking.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../login/gui/login.code.dart';
import '../utenti/class_user_global.dart';

const double homeSmallScreenBreakpoint = 768;

enum HomeTabOpenMode { singleton, duplicate }

class HomeTabMeta {
  const HomeTabMeta({
    required this.id,
    required this.sectionId,
    required this.baseTitle,
    required this.displayTitle,
    required this.isHome,
  });

  final String id;
  final String sectionId;
  final String baseTitle;
  final String displayTitle;
  final bool isHome;
}

class HomeLogic extends ChangeNotifier {
  HomeLogic({required this.setState, this.showLoginCallback})
    : desktopLayout = DockingLayout();

  final VoidCallback setState;
  final VoidCallback? showLoginCallback;
  final DockingLayout desktopLayout;

  HomeTabMeta? _mobileEntry;
  Widget? _mobileContent;
  int _tabSequence = 0;
  bool _isChecking = true;
  UserGlobal? _currentUser;

  /// Unica fonte di verita: delega a `loginCode` (WooConnect).
  /// Tutte le card usano questo getter tramite `openSection(requiresAuth)`.
  bool get isConnected => loginCode.isConnected;

  /// True durante la verifica iniziale o il reload del profilo.
  bool get isChecking => _isChecking;

  /// Profilo WP corrente (nome + avatar), null se non autenticato.
  UserGlobal? get currentUser => _currentUser;

  String? get displayName => _currentUser?.displayName;

  String? get avatarUrl => _currentUser?.avatarUrl;

  String? get currentSiteUrl => loginCode.cachedSiteUrl;

  String _appVersionLabel = 'Versione non disponibile';

  String get appVersionLabel => _appVersionLabel;

  HomeTabMeta? get mobileEntry => _mobileEntry;

  Widget? get mobileContent => _mobileContent;

  bool get isShowingMobileHome => _mobileEntry?.isHome ?? true;

  Future<void> checkAuthentication() async {
    _isChecking = true;
    _emit();
    try {
      await loadAppVersion();
      final success = await loginCode.tryAutoLogin();
      if (success) {
        final connectionWorking = await loginCode.testConnection();
        if (!connectionWorking) {
          await loginCode.logout();
        }
      }
      if (isConnected) {
        await _loadCurrentUser();
      } else {
        _currentUser = null;
      }
    } catch (_) {
      await loginCode.logout();
      _currentUser = null;
    } finally {
      _isChecking = false;
      _emit();
    }
  }

  Future<void> loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _appVersionLabel = 'Versione ${info.version}';
    } catch (_) {
      _appVersionLabel = 'Versione non disponibile';
    }
  }

  Future<void> onLoginSuccess() async {
    _emit();
    await _loadCurrentUser();
    _emit();
  }

  Future<void> _loadCurrentUser() async {
    if (!isConnected) {
      _currentUser = null;
      return;
    }
    try {
      final profile = await loginCode.currentUserProfile();
      if (profile != null) {
        _currentUser = profile;
        return;
      }
      final fallbackName = await loginCode.loggedUsername();
      _currentUser = (fallbackName != null && fallbackName.trim().isNotEmpty)
          ? UserGlobal(username: fallbackName.trim(), name: fallbackName.trim())
          : null;
    } catch (_) {
      _currentUser = null;
    }
  }

  Future<void> logout() async {
    await loginCode.logout();
    _currentUser = null;
    _emit();
  }

  void setHomePage({required String title, required Widget page}) {
    final homeMeta = HomeTabMeta(
      id: 'home',
      sectionId: 'home',
      baseTitle: title,
      displayTitle: title,
      isHome: true,
    );

    desktopLayout.root = DockingItem(
      id: homeMeta.id,
      name: homeMeta.displayTitle,
      value: homeMeta,
      widget: KeyedSubtree(
        key: const ValueKey('home-docking-content'),
        child: page,
      ),
      closable: false,
      keepAlive: true,
    );
    _mobileEntry = homeMeta;
    _mobileContent = page;
    _emit();
  }

  void openSection({
    required bool isSmallScreen,
    required String sectionId,
    required String title,
    required Widget page,
    required HomeTabOpenMode openMode,
    required bool requiresAuth,
  }) {
    if (requiresAuth && !isConnected) {
      showLoginCallback?.call();
      return;
    }

    if (isSmallScreen) {
      _mobileEntry = HomeTabMeta(
        id: '$sectionId-mobile',
        sectionId: sectionId,
        baseTitle: title,
        displayTitle: title,
        isHome: false,
      );
      _mobileContent = KeyedSubtree(
        key: ValueKey('${sectionId}-mobile-content'),
        child: page,
      );
      _emit();
      return;
    }

    if (openMode == HomeTabOpenMode.singleton) {
      final existingItem = _findSectionItem(sectionId);
      if (existingItem != null) {
        _focusItem(existingItem);
        _emit();
        return;
      }
    }

    final tabMeta = HomeTabMeta(
      id: _nextTabId(sectionId),
      sectionId: sectionId,
      baseTitle: title,
      displayTitle: _buildDisplayTitle(sectionId, title, openMode),
      isHome: false,
    );

    desktopLayout.addItemOnRoot(
      newItem: DockingItem(
        id: tabMeta.id,
        name: tabMeta.displayTitle,
        value: tabMeta,
        widget: KeyedSubtree(
          key: ValueKey('${tabMeta.id}-docking-content'),
          child: page,
        ),
        keepAlive: true,
      ),
      dropIndex: _rootDropIndex(),
    );
    final newItem = desktopLayout.findDockingItem(tabMeta.id);
    if (newItem != null) {
      _focusItem(newItem);
    }
    _emit();
  }

  void goHomeMobile() {
    final homeItem = desktopLayout.findDockingItem('home');
    if (homeItem == null) {
      return;
    }
    _mobileEntry = homeItem.value as HomeTabMeta?;
    _mobileContent = homeItem.widget;
    _emit();
  }

  void focusHomeDesktop() {
    final homeItem = desktopLayout.findDockingItem('home');
    if (homeItem == null) {
      return;
    }
    _focusItem(homeItem);
    _emit();
  }

  DockingItem? _findSectionItem(String sectionId) {
    for (final area in desktopLayout.layoutAreas()) {
      if (area is! DockingItem) {
        continue;
      }
      final meta = area.value as HomeTabMeta?;
      if (meta?.sectionId == sectionId) {
        return area;
      }
    }
    return null;
  }

  void _focusItem(DockingItem item) {
    final parentTabs = desktopLayout.findDockingTabsWithItem(item.id);
    if (parentTabs != null) {
      parentTabs.selectedIndex = parentTabs.indexOf(item);
      desktopLayout.rebuild();
    }
  }

  int _rootDropIndex() {
    final root = desktopLayout.root;
    if (root is DockingTabs) {
      return root.childrenCount;
    }
    return 1;
  }

  String _buildDisplayTitle(
    String sectionId,
    String title,
    HomeTabOpenMode openMode,
  ) {
    if (openMode == HomeTabOpenMode.singleton) {
      return title;
    }

    int sectionCount = 0;
    for (final area in desktopLayout.layoutAreas()) {
      if (area is! DockingItem) {
        continue;
      }
      final meta = area.value as HomeTabMeta?;
      if (meta?.sectionId == sectionId) {
        sectionCount++;
      }
    }

    return sectionCount == 0 ? title : '$title #${sectionCount + 1}';
  }

  String _nextTabId(String sectionId) {
    _tabSequence++;
    return '$sectionId-$_tabSequence';
  }

  void _emit() {
    notifyListeners();
    setState();
  }
}
