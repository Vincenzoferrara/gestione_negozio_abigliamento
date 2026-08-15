import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestione_negozio_abbigliamento/prodotti/class_prodotti.dart';
import 'package:gestione_negozio_abbigliamento/prodotti/prodotti_gestisci/prodotti_gestisci.code.dart';
import 'package:gestione_negozio_abbigliamento/prodotti/prodotti_gestisci/prodotti_gestisci_view.gui.dart';
import 'package:gestione_negozio_abbigliamento/theme/theme.dart';

class _FakeProdottiController extends ProdottiGestioneController {
  int saveShortcutCalls = 0;

  @override
  Future<QuickVariantSaveResult> saveVariantQuickEdits({
    required int productId,
    required Map<int, QuickVariantEdit> edits,
  }) async {
    saveShortcutCalls++;
    return const QuickVariantSaveResult(
      updated: 1,
      failed: 0,
      message: 'Variante aggiornata.',
    );
  }
}

void main() {
  late ProdottoGlobal product;
  late _FakeProdottiController controller;

  setUp(() {
    product = ProdottoGlobal(
      id: 42,
      nome: 'Giacca test',
      sku: 'GIACCA-42',
      status: 'publish',
      varianti: <VarianteProductGlobal>[
        VarianteProductGlobal(
          id: 420,
          nome: 'Giacca blu',
          sku: 'GIACCA-42-BLU',
          prezzo: 79.90,
          quantita: 2,
        ),
      ],
    );
    controller = _FakeProdottiController();
    controller.selezionaProdottoLocal(product);
    controller.selectOnlyProductForBulk(product);
  });

  tearDown(() {
    controller.dispose();
  });

  Future<void> pumpDetails(
    WidgetTester tester, {
    String shortcutToggleEdit = 'Ctrl+E',
  }) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: ProdottoDettagliView(
            prodotto: product,
            controller: controller,
            shortcutToggleEdit: shortcutToggleEdit,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('la shortcut personalizzata attiva la modifica rapida', (
    tester,
  ) async {
    await pumpDetails(tester, shortcutToggleEdit: 'Alt+E');

    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pump();

    expect(find.text('Modifica attiva'), findsOneWidget);
  });

  testWidgets('Ctrl+S salva le modifiche rapide configurate', (tester) async {
    await pumpDetails(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Modifica rapida'));
    await tester.pump();

    final quantityField = find.byType(TextField).last;
    await tester.ensureVisible(quantityField);
    await tester.enterText(quantityField, '3');
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(controller.saveShortcutCalls, 1);
  });

  testWidgets('il dettaglio non duplica la sezione Foto per Variante', (
    tester,
  ) async {
    await pumpDetails(tester);

    expect(find.text('Foto per Variante'), findsNothing);
  });
}
