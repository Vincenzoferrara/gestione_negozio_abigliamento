import 'package:flutter/material.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reports'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Report Section',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            // Qui puoi aggiungere la logica per visualizzare i report
            Text('Report Data: ...'),
          ],
        ),
      ),
    );
  }
}