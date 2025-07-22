import 'package:flutter/material.dart';
import 'prodotti_crea.code.dart'; // Importa la logica

class ProdottiCreaPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Crea Prodotto'), backgroundColor: Colors.redAccent),
      body: Center(
        child: Text('Pagina di Creazione Prodotto', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}