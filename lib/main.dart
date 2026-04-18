import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home/home.gui.dart';
import 'log_viewer/app_logger.dart';
import 'notification/notification_service.dart';
import 'settings/theme/theme_settings.dart';

void main() async {
  // Assicurati che Flutter sia inizializzato
  WidgetsFlutterBinding.ensureInitialized();

  // Inizializza il logger
  await log.init();

  // Inizializza il theme manager
  final themeSettings = ThemeSettings();
  await themeSettings.init();

  log.d('Application started');

  // La funzione runApp avvia l'applicazione Flutter con il widget radice.
  runApp(MyApp(themeSettings: themeSettings));
}

// MyApp è il widget radice (root) della tua intera applicazione.
class MyApp extends StatelessWidget {
  final ThemeSettings themeSettings;

  const MyApp({super.key, required this.themeSettings});

  @override
  Widget build(BuildContext context) {
    // Wrappa l'app con ChangeNotifierProvider per rendere ThemeSettings disponibile ovunque
    return ChangeNotifierProvider.value(
      value: themeSettings,
      child: Consumer<ThemeSettings>(
        builder: (context, themeSettings, child) {
          return MaterialApp(
            title: 'Gestione Negozio Abbigliamento',
            scaffoldMessengerKey: notificationMessengerKey,

            // Usa i temi personalizzati con i colori scelti dall'utente
            theme: themeSettings.customLightTheme,
            darkTheme: themeSettings.customDarkTheme,

            // Usa il themeMode gestito dal ThemeSettings
            themeMode: themeSettings.themeMode,

            home: const HomeScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
