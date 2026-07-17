import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gestione_negozio_abbigliamento/prodotti/prodotti_crea/widgets/media_selector_dialog.dart';

void main() {
  testWidgets('mostra il badge informativo per immagini oltre soglia', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProductImageDimensionWarningBadge(
            width: 1600,
            height: 1200,
            thresholdWidth: 720,
            thresholdHeight: 1080,
          ),
        ),
      ),
    );

    expect(find.text('Oltre soglia'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
  });
}
