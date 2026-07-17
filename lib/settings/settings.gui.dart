import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/theme_settings.gui.dart';
import 'prodotti_settings.gui.dart';
import 'ai_settings.gui.dart';
import 'rfid_settings.gui.dart';
import 'shortcuts_settings.gui.dart';
import 'app_settings.dart';
import 'prodotti_image_settings.dart';
import 'wordpress_backend_settings.gui.dart';

/// Pagina principale delle impostazioni con TabView
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with AutomaticKeepAliveClientMixin {
  late AppSettings _appSettings;
  late ProductImageWarningSettings _productImageSettings;
  bool _isInitialized = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initSettings();
  }

  Future<void> _initSettings() async {
    _appSettings = AppSettings();
    _productImageSettings = ProductImageWarningSettings();
    await Future.wait([_appSettings.init(), _productImageSettings.init()]);
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Necessario per AutomaticKeepAliveClientMixin
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppSettings>.value(value: _appSettings),
        ChangeNotifierProvider<ProductImageWarningSettings>.value(
          value: _productImageSettings,
        ),
      ],
      child: DefaultTabController(
        length: 6,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Impostazioni'),
            bottom: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.cloud_sync), text: 'Backend'),
                Tab(icon: Icon(Icons.inventory), text: 'Prodotti'),
                Tab(icon: Icon(Icons.palette), text: 'Tema'),
                Tab(icon: Icon(Icons.psychology), text: 'IA'),
                Tab(icon: Icon(Icons.nfc), text: 'RFID'),
                Tab(icon: Icon(Icons.keyboard), text: 'Shortcut'),
                // Futuro: Network, Logs, About...
                // Tab(icon: Icon(Icons.wifi), text: 'Network'),
                // Tab(icon: Icon(Icons.bug_report), text: 'Logs'),
                // Tab(icon: Icon(Icons.info), text: 'About'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              WordPressBackendSettingsTab(),
              ProdottiSettingsTab(),
              ThemeSettingsTab(),
              AISettingsTab(),
              RFIDSettingsTab(),
              ShortcutsSettingsTab(),
              // Futuro: altre tab
              // NetworkSettingsTab(),
              // LogsSettingsTab(),
              // AboutTab(),
            ],
          ),
        ),
      ),
    );
  }
}
