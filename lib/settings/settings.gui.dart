import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/theme_settings.gui.dart';
import 'prodotti_settings.gui.dart';
import 'ai_settings.gui.dart';
import 'app_settings.dart';

/// Pagina principale delle impostazioni con TabView
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with AutomaticKeepAliveClientMixin {
  late AppSettings _appSettings;
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
    await _appSettings.init();
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Necessario per AutomaticKeepAliveClientMixin
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return ChangeNotifierProvider.value(
      value: _appSettings,
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
        appBar: AppBar(
          title: const Text('Impostazioni'),
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.inventory),
                text: 'Prodotti',
              ),
              Tab(
                icon: Icon(Icons.palette),
                text: 'Tema',
              ),
              Tab(
                icon: Icon(Icons.psychology),
                text: 'IA',
              ),
              // Futuro: Network, Logs, About...
              // Tab(icon: Icon(Icons.wifi), text: 'Network'),
              // Tab(icon: Icon(Icons.bug_report), text: 'Logs'),
              // Tab(icon: Icon(Icons.info), text: 'About'),
            ],
          ),
        ),
          body: const TabBarView(
            children: [
              ProdottiSettingsTab(),
              ThemeSettingsTab(),
              AISettingsTab(),
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
