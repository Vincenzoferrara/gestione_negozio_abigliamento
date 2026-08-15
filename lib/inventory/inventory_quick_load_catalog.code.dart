import 'package:flutter/foundation.dart';

import '../prodotti/class_prodotti.dart';
import '../prodotti/prodotti_gestisci/prodotti_gestisci.code.dart';

class InventoryQuickLoadCatalogController extends ChangeNotifier {
  InventoryQuickLoadCatalogController({
    ProdottiGestioneController? productsController,
  }) : _productsController = productsController ?? ProdottiGestioneController();

  final ProdottiGestioneController _productsController;
  bool _disposed = false;
  bool isLoading = false;
  int loadedProducts = 0;
  String? errorMessage;

  List<ProdottoGlobal> get products => _productsController.prodotti;

  Future<void> load({bool forceRefresh = false}) async {
    if (_disposed || isLoading) return;
    isLoading = true;
    errorMessage = null;
    _notifyListeners();
    try {
      await _productsController.caricaProdotti(
        forceRefresh: forceRefresh,
        onProgress: (items) {
          if (_disposed) return;
          loadedProducts = items.length;
          _notifyListeners();
        },
      );
      if (_disposed) return;
      loadedProducts = products.length;
      errorMessage = _productsController.consumeLastLoadWarning();
    } catch (error) {
      if (_disposed) return;
      errorMessage = error.toString();
    } finally {
      if (!_disposed) {
        isLoading = false;
        _notifyListeners();
      }
    }
  }

  void search(String query) {
    if (_disposed) return;
    _productsController.setFiltroRicerca(query);
    _notifyListeners();
  }

  bool isVariable(ProdottoGlobal product) {
    return product.variations?.isNotEmpty ?? false;
  }

  Future<List<VarianteProductGlobal>> loadVariants(
    ProdottoGlobal product, {
    bool forceRefresh = false,
  }) async {
    if (_disposed || !isVariable(product)) {
      return const <VarianteProductGlobal>[];
    }
    if (!forceRefresh && (product.varianti?.isNotEmpty ?? false)) {
      return product.varianti!;
    }
    _productsController.selezionaProdottoLocal(product);
    await _productsController.caricaVariantiProdottoSelezionato(
      forceRefresh: forceRefresh,
    );
    if (_disposed) return const <VarianteProductGlobal>[];
    return _productsController.prodottoSelezionato?.varianti ??
        const <VarianteProductGlobal>[];
  }

  void _notifyListeners() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _productsController.dispose();
    super.dispose();
  }
}

String inventoryVariationLabel(VarianteProductGlobal variant) {
  final attributes = variant.attributi
      .map((attribute) => attribute.opzione.trim())
      .where((value) => value.isNotEmpty)
      .join(' / ');
  if (attributes.isNotEmpty) return attributes;
  if (variant.nome.trim().isNotEmpty) return variant.nome.trim();
  return 'Variante #${variant.id}';
}
