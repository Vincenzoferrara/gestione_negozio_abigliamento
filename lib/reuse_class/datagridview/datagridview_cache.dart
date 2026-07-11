import '../../prodotti/class_prodotti.dart';

class DataGridViewCache {
  static List<ProdottoGlobal>? _products;
  static DateTime? _productsAt;
  static bool _productsDirty = true;

  static final Map<int, List<VarianteProductGlobal>> _variants =
      <int, List<VarianteProductGlobal>>{};
  static final Map<int, DateTime> _variantsAt = <int, DateTime>{};

  static bool get hasProducts => _products != null && _products!.isNotEmpty;

  static bool hasFreshProducts([Duration? ttl]) {
    if (_productsDirty || _products == null || _productsAt == null) {
      return false;
    }
    if (ttl == null) return true;
    return DateTime.now().difference(_productsAt!) <= ttl;
  }

  static List<ProdottoGlobal>? readProducts() {
    final products = _products;
    if (products == null) return null;
    return List<ProdottoGlobal>.from(products);
  }

  static void writeProducts(List<ProdottoGlobal> products) {
    _products = List<ProdottoGlobal>.from(products);
    _productsAt = DateTime.now();
    _productsDirty = false;
  }

  static void replaceProducts(List<ProdottoGlobal> products) {
    writeProducts(products);
  }

  static void appendProducts(List<ProdottoGlobal> products) {
    final current = _products ?? <ProdottoGlobal>[];
    _products = <ProdottoGlobal>[...current, ...products];
    _productsAt = DateTime.now();
    _productsDirty = false;
  }

  static void markProductsDirty() {
    _productsDirty = true;
  }

  static void clearProducts() {
    _products = null;
    _productsAt = null;
    _productsDirty = true;
  }

  static void clearVariants() {
    _variants.clear();
    _variantsAt.clear();
  }

  static void clearAll() {
    clearProducts();
    clearVariants();
  }

  static List<VarianteProductGlobal>? readVariants(
    int productId,
    Duration ttl,
  ) {
    final cachedAt = _variantsAt[productId];
    final cached = _variants[productId];
    if (cachedAt == null || cached == null) return null;
    if (DateTime.now().difference(cachedAt) > ttl) {
      removeVariants(productId);
      return null;
    }
    return List<VarianteProductGlobal>.from(cached);
  }

  static void writeVariants(
    int productId,
    List<VarianteProductGlobal> variants,
  ) {
    _variants[productId] = List<VarianteProductGlobal>.from(variants);
    _variantsAt[productId] = DateTime.now();
  }

  static void removeVariants(int productId) {
    _variants.remove(productId);
    _variantsAt.remove(productId);
  }
}
