import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gestione_negozio_abbigliamento/settings/prodotti_image_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('carica le soglie immagine prodotto dalle chiavi esistenti', () async {
    SharedPreferences.setMockInitialValues({
      'img_resize_width': 900,
      'img_resize_height': 1200,
      'product_image_dimension_warning_enabled': false,
    });

    final settings = ProductImageWarningSettings();
    await settings.init();

    expect(settings.thresholdWidth, 900);
    expect(settings.thresholdHeight, 1200);
    expect(settings.warningsEnabled, isFalse);
  });

  test('salva toggle e soglie normalizzando valori negativi', () async {
    final settings = ProductImageWarningSettings();
    await settings.init();

    await settings.setWarningsEnabled(false);
    await settings.setThresholdWidth(-10);
    await settings.setThresholdHeight(1600);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('product_image_dimension_warning_enabled'), isFalse);
    expect(prefs.getInt('img_resize_width'), 0);
    expect(prefs.getInt('img_resize_height'), 1600);
  });

  test('riconosce immagini oltre soglia solo quando il dato e noto', () {
    expect(
      isProductImageOverWarningThreshold(
        width: 1000,
        height: 800,
        warningsEnabled: true,
        thresholdWidth: 900,
        thresholdHeight: 1200,
      ),
      isTrue,
    );

    expect(
      isProductImageOverWarningThreshold(
        width: null,
        height: 1400,
        warningsEnabled: true,
        thresholdWidth: 900,
        thresholdHeight: 1200,
      ),
      isFalse,
    );

    expect(
      isProductImageOverWarningThreshold(
        width: 1000,
        height: 1400,
        warningsEnabled: false,
        thresholdWidth: 900,
        thresholdHeight: 1200,
      ),
      isFalse,
    );
  });
}
