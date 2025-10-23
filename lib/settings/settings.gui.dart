import 'package:flutter/material.dart';
import 'theme/theme_settings.gui.dart';

/// Pagina principale delle impostazioni con TabView
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 1, // Per ora solo Theme, in futuro aggiungeremo altre tab
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Impostazioni'),
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.palette),
                text: 'Tema',
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
            ThemeSettingsTab(),
            // Futuro: altre tab
            // NetworkSettingsTab(),
            // LogsSettingsTab(),
            // AboutTab(),
          ],
        ),
      ),
    );
  }
}
