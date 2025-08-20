import 'package:flutter/material.dart';
import 'home/home.gui.dart'; // Importa la tua schermata principale
import 'theme/theme.dart';   // Importa il file dove hai definito i temi

void main() {
  // La funzione runApp avvia l'applicazione Flutter con il widget radice.
  runApp(MyApp());
}

// MyApp è il widget radice (root) della tua intera applicazione.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp è il widget principale che abilita molte delle funzionalità
    // di Material Design, inclusa la gestione del tema globale e della navigazione.
    return MaterialApp(
      // Il titolo dell'applicazione, usato dal sistema operativo (es. nel task manager).
      title: 'Gestione Negozio Abbigliamento',

      // ------ IMPOSTAZIONE DEL TEMA GLOBALE ------

      // Definisce il tema predefinito da usare quando il dispositivo è in modalità "chiara".
      // Stai correttamente usando la definizione statica dalla tua classe AppTheme.
      theme: AppTheme.lightTheme,

      // Definisce il tema da usare quando il dispositivo è in modalità "scura".
      darkTheme: AppTheme.darkTheme,

      // Determina quale tema deve essere attivo.
      // Impostando ThemeMode.system, l'app ascolterà le impostazioni del sistema
      // operativo del telefono e applicherà automaticamente il tema chiaro o scuro.
      // Questa è la scelta consigliata per una migliore esperienza utente.
      themeMode: ThemeMode.system,
      
      // ---------------------------------------------

      // Il widget da mostrare come schermata iniziale dell'app.
      home: HomeScreen(),

      // Rimuove la fastidiosa etichetta "DEBUG" che appare in alto a destra
      // nell'angolo durante lo sviluppo.
      debugShowCheckedModeBanner: false,
    );
  }
}