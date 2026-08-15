import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gestione_negozio_abbigliamento/home/home.gui.dart';
import 'package:gestione_negozio_abbigliamento/login/gui/login.gui.dart';
import 'package:gestione_negozio_abbigliamento/theme/theme.dart';

void main() {
  testWidgets('compact width opens login full-screen without a dialog', (
    tester,
  ) async {
    await _pumpHomeScreen(tester, const Size(390, 844));

    await _openLoginFromDrawer(tester);

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('expanded width keeps the login dialog behavior', (tester) async {
    await _pumpHomeScreen(tester, const Size(1200, 900));

    await _openLoginFromDrawer(tester);

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(Dialog), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(LoginPage),
      ),
      findsOneWidget,
    );
  });
}

Future<void> _pumpHomeScreen(WidgetTester tester, Size surfaceSize) async {
  tester.view.physicalSize = surfaceSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.lightTheme, home: const HomeScreen()),
  );
  await tester.pumpAndSettle();
  _clearKnownLayoutExceptions(tester);
}

Future<void> _openLoginFromDrawer(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Open navigation menu'));
  await tester.pumpAndSettle();
  _clearKnownLayoutExceptions(tester);

  await tester.tap(find.widgetWithText(ListTile, 'Login'));
  await tester.pumpAndSettle();
  _clearKnownLayoutExceptions(tester);
}

void _clearKnownLayoutExceptions(WidgetTester tester) {
  while (tester.takeException() != null) {}
}
