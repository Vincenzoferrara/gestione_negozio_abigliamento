import 'package:flutter/material.dart';

class settingsPage extends StatelessWidget {
  const settingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container( // Aggiunto Container per definire le dimensioni
          padding: EdgeInsets.all(16),
          child: Text(
            'Pagina di impostazioni',
            style: TextStyle(fontSize: 24),
            textAlign: TextAlign.center, // Allinea il testo al centro
          ),
        ),
      ),
    );
  }
}







